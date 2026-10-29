import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/remote/account_auth.dart';
import '../../data/datasources/remote/firestore_sync_remote.dart';
import '../../data/sync/prefs_sync_state_store.dart';
import '../../data/sync/repository_sync_local.dart';
import '../services/sync_engine.dart';

enum SyncStatus { idle, syncing, failed }

/// Hesap silmenin sonucu.
enum AccountDeleteResult { deleted, cancelled, failed }

/// İsteğe bağlı hesap ve bulut eşitleme.
///
/// Takip, kayıt ve analizler hesapsız çalışıyor. Hesap verinin bir
/// kopyasını buluta koymak, başka cihazda geri almak ve partner eşleşmesi
/// için.
///
/// **Rıza.** Giriş yapmak tek başına hiçbir sağlık verisini göndermiyor.
/// Eşitleme ancak kullanıcı açık rıza verince başlıyor (KVKK m.6: sağlık
/// verisi özel nitelikli; m.9: sunucu yurt dışında olabilir). Rıza hesaba
/// ve cihaza bağlı tutuluyor; geri çekilince ([disableSync]) buluttaki
/// kopya siliniyor ve öbür cihazlar da yüklemeyi bırakıyor.
class AccountViewModel extends ChangeNotifier {
  AccountViewModel({
    AccountAuth? auth,
    SyncRemote? remote,
    SyncLocal? local,
    SyncStateStore? stateStore,
    this.debounce = const Duration(seconds: 4),
    DateTime Function()? clock,
  }) : _auth = auth ?? FirebaseAccountAuth(),
       _remote = remote ?? FirestoreSyncRemote(),
       _local = local ?? const RepositorySyncLocal(),
       _stateStore = stateStore ?? const PrefsSyncStateStore(),
       _clock = clock ?? DateTime.now {
    _engine = SyncEngine(
      remote: _remote,
      local: _local,
      state: _stateStore,
      clock: _clock,
    );
    _load();
  }

  final AccountAuth _auth;
  final SyncRemote _remote;
  final SyncLocal _local;
  final SyncStateStore _stateStore;
  final DateTime Function() _clock;
  late final SyncEngine _engine;

  /// Değişiklikten sonra bu kadar beklenip tek seferde yükleniyor: art arda
  /// dokunulan her çip için ayrı bir yükleme olmasın.
  final Duration debounce;

  static const String _consentUidKey = 'sync_consent_uid';
  static const String _consentAtKey = 'sync_consent_at';

  /// Buluttan veri indikten sonra bellekteki kopyalar yenilenmeli (takvim,
  /// gebelik). `main.dart` bağlıyor.
  Future<void> Function()? onRemoteApplied;

  /// Hesap ya da kimlik değişti (partner kimliği bunu bilmeli).
  Future<void> Function()? onIdentityChanged;

  /// Hesabın sunucudaki partner verisini ve kimliğin kendisini siler
  /// (bkz. `UserViewModel.deleteRemoteData`). `main.dart` bağlıyor.
  Future<bool> Function()? deleteIdentityAndPartnerData;

  AccountUser? _account;
  AccountUser? get account => _account;
  bool get isSignedIn => _account != null;
  bool get isAvailable => _auth.isAvailable;

  bool _syncEnabled = false;
  bool get syncEnabled => _syncEnabled;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  DateTime? _lastSyncAt;
  DateTime? get lastSyncAt => _lastSyncAt;

  bool _busy = false;

  /// Giriş, çıkış ya da silme sürüyor: düğmeler kilitli.
  bool get busy => _busy;

  /// Eşitleme başka bir cihazda kapatıldığı için burada da durdu. Ekran
  /// bunu bir kez söylüyor.
  bool _stoppedRemotely = false;
  bool get stoppedRemotely => _stoppedRemotely;
  void acknowledgeStoppedRemotely() {
    _stoppedRemotely = false;
    notifyListeners();
  }

  Timer? _timer;
  bool _running = false;
  bool _again = false;
  StreamSubscription<AccountUser?>? _sub;

  Future<void> _load() async {
    _account = _auth.currentAccount;
    await _readConsent();
    notifyListeners();
    _sub ??= _auth.accountChanges.listen((a) async {
      if (a?.uid == _account?.uid) return;
      _account = a;
      await _readConsent();
      notifyListeners();
    });
  }

  /// Firebase açılıştan sonra hazır olunca (bkz. `main.dart`).
  Future<void> refresh() async {
    await _sub?.cancel();
    _sub = null;
    await _load();
    if (_syncEnabled) scheduleSync(immediately: true);
    if (_pendingVerification case final kod? when isAvailable) {
      _pendingVerification = null;
      await applyEmailVerification(kod);
    }
  }

  Future<void> _readConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _account?.uid;
    _syncEnabled = uid != null && prefs.getString(_consentUidKey) == uid;
    _lastSyncAt = uid == null ? null : (await _stateStore.load(uid)).lastSyncAt;
  }

  Future<T> _withBusy<T>(Future<T> Function() op) async {
    _busy = true;
    notifyListeners();
    try {
      return await op();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  // ─── Giriş ───

  Future<SignInResult> signIn(AccountProvider provider) =>
      _withBusy(() async => _signedIn(await _auth.signIn(provider)));

  /// E-posta ve şifreyle giriş; [create] ise yeni hesap.
  Future<SignInResult> signInWithEmail(
    String email,
    String password, {
    required bool create,
    String? languageCode,
  }) => _withBusy(
    () async => _signedIn(
      await _auth.signInWithEmail(
        email,
        password,
        create: create,
        languageCode: languageCode,
      ),
    ),
  );

  Future<bool> sendPasswordReset(String email, {String? languageCode}) =>
      _withBusy(
        () => _auth.sendPasswordReset(email, languageCode: languageCode),
      );

  /// E-posta hesabı doğrulanmadı: uygulama doğrulanana kadar kapalı.
  bool get needsEmailVerification => _account?.needsEmailVerification ?? false;

  Future<bool> resendEmailVerification({String? languageCode}) =>
      _auth.sendEmailVerification(languageCode: languageCode);

  /// Hesabı sunucudan yeniden okur. Adres doğrulandıysa kimliği tazeler
  /// (yönlendirme doğrulama ekranından çıkıyor). Doğrulandıysa `true`.
  Future<bool> checkEmailVerified() async {
    final onceden = needsEmailVerification;
    final guncel = await _auth.reloadAccount();
    if (guncel != null) _account = guncel;
    if (onceden && !needsEmailVerification) {
      await onIdentityChanged?.call();
    }
    notifyListeners();
    return !needsEmailVerification;
  }

  /// Firebase başlamadan gelen doğrulama kodu; başlayınca uygulanıyor.
  String? _pendingVerification;

  /// E-postadaki doğrulama bağlantısı uygulamayı açtı.
  ///
  /// Bağlantı uygulamayı soğuk başlattıysa Firebase henüz hazır olmayabilir
  /// (açılış onu beklemiyor): kod saklanıyor ve [refresh]'te uygulanıyor.
  Future<bool> applyEmailVerification(String code) async {
    if (!isAvailable) {
      _pendingVerification = code;
      return false;
    }
    await _auth.applyEmailVerification(code);
    return checkEmailVerified();
  }

  /// Şifre yenileme kodu geçerliyse hesabın adresi.
  Future<String?> checkPasswordResetCode(String code) =>
      _auth.checkPasswordResetCode(code);

  /// Yeni şifreyi belirler; oturum yoksa o şifreyle giriş de yapar.
  Future<PasswordResetResult> resetPassword(
    String code, {
    required String email,
    required String newPassword,
  }) => _withBusy(() async {
    final sonuc = await _auth.confirmPasswordReset(code, newPassword);
    if (sonuc == PasswordResetResult.done && _account == null) {
      await _signedIn(
        await _auth.signInWithEmail(email, newPassword, create: false),
      );
    }
    return sonuc;
  });

  Future<SignInResult> _signedIn(SignInResult sonuc) async {
    if (sonuc.status == SignInStatus.signedIn) {
      _account = sonuc.user ?? _auth.currentAccount;
      await _readConsent();
      await onIdentityChanged?.call();
    }
    return sonuc;
  }

  /// Çıkış: eşitleme durur, bu cihazdaki kayıtlar kalır.
  Future<void> signOut() => _withBusy(() async {
    _timer?.cancel();
    final uid = _account?.uid;
    await _auth.signOut();
    if (uid != null) await _clearConsent();
    _account = null;
    _syncEnabled = false;
    _lastSyncAt = null;
    _status = SyncStatus.idle;
    await onIdentityChanged?.call();
  });

  // ─── Eşitleme ───

  /// Açık rıza alındı: eşitleme başlıyor.
  Future<SyncOutcome?> enableSync() async {
    final uid = _account?.uid;
    if (uid == null) return null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_consentUidKey, uid);
    await prefs.setString(_consentAtKey, _clock().toIso8601String());
    _syncEnabled = true;
    _stoppedRemotely = false;
    notifyListeners();
    return syncNow(resume: true);
  }

  /// Rıza geri çekildi: buluttaki kopya siliniyor. Silinemezse (bağlantı
  /// yok) `false` ve eşitleme açık kalıyor — "kapattım" sanılıp bulutta
  /// veri bırakılmasın.
  Future<bool> disableSync() => _withBusy(() async {
    final uid = _account?.uid;
    if (uid == null) return true;
    _timer?.cancel();
    try {
      await _remote.delete(uid, keepDisabledMarker: true);
    } on SyncException catch (e) {
      debugPrint('Disable sync failed: $e');
      return false;
    }
    await _clearConsent();
    await _stateStore.clear(uid);
    _syncEnabled = false;
    _lastSyncAt = null;
    _status = SyncStatus.idle;
    return true;
  });

  Future<void> _clearConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentUidKey);
    await prefs.remove(_consentAtKey);
  }

  /// Cihazda bir şey değişmiş olabilir: kısa bir beklemeden sonra, gerçekten
  /// değiştiyse eşitle.
  ///
  /// [immediately]: beklemeden ve değişiklik olmasa da — uygulama öne
  /// geldiğinde başka cihazın yüklediği kopyayı almak için.
  void scheduleSync({bool immediately = false}) {
    if (!_syncEnabled || _account == null) return;
    _timer?.cancel();
    _timer = Timer(
      immediately ? Duration.zero : debounce,
      immediately ? syncNow : syncIfChanged,
    );
  }

  /// Cihazda değişiklik varsa hemen eşitler (uygulama arka plana giderken:
  /// orada zamanlayıcı çalışmıyor).
  Future<void> syncIfChanged() async {
    final uid = _account?.uid;
    if (uid == null || !_syncEnabled) return;
    _timer?.cancel();
    if (!await _engine.hasLocalChanges(uid)) return;
    await syncNow();
  }

  /// Hemen eşitler. Eşitleme zaten sürüyorsa bittikten sonra bir kez daha.
  Future<SyncOutcome?> syncNow({bool resume = false}) async {
    final uid = _account?.uid;
    if (uid == null || !_syncEnabled) return null;
    if (_running) {
      _again = true;
      return null;
    }
    _running = true;
    _status = SyncStatus.syncing;
    notifyListeners();
    SyncOutcome? sonuc;
    try {
      sonuc = await _engine.sync(uid, resume: resume);
      switch (sonuc) {
        case SyncOutcome.downloaded:
        case SyncOutcome.merged:
          await onRemoteApplied?.call();
        case SyncOutcome.disabledRemotely:
          await _clearConsent();
          await _stateStore.clear(uid);
          _syncEnabled = false;
          _stoppedRemotely = true;
        case SyncOutcome.upToDate:
        case SyncOutcome.uploaded:
        case SyncOutcome.nothing:
          break;
      }
      _lastSyncAt = (await _stateStore.load(uid)).lastSyncAt ?? _lastSyncAt;
      _status = SyncStatus.idle;
    } on SyncException catch (e) {
      debugPrint('Sync failed: $e');
      _status = SyncStatus.failed;
    } catch (e) {
      debugPrint('Sync failed: $e');
      _status = SyncStatus.failed;
    } finally {
      _running = false;
      notifyListeners();
    }
    if (_again) {
      _again = false;
      unawaited(syncNow());
    }
    return sonuc;
  }

  /// Bu cihazda kayıt var mı? Geri yüklemeden sonra "kayıtların geldi" mi
  /// yoksa "bu hesapta kayıt yok" mu deneceğine bakılıyor.
  Future<bool> hasLocalData() async => !(await _local.read()).isEmpty;

  // ─── Silme ───

  /// Hesabı ve buluttaki her şeyi siler. Bu cihazdaki kayıtlara dokunmaz.
  ///
  /// Sıra: kimlik yeniden doğrulanıyor (Apple'da jeton iptali; e-posta
  /// hesabında [password] ile), sonra bulut kopyası, partner verisi ve
  /// kimliğin kendisi. Doğrulamadan vazgeçilirse hiçbir şey silinmiyor.
  Future<AccountDeleteResult> deleteAccount({String? password}) =>
      _withBusy(() => _deleteAccount(password));

  Future<AccountDeleteResult> _deleteAccount(String? password) async {
    final uid = _account?.uid;
    if (uid == null) return AccountDeleteResult.deleted;
    _timer?.cancel();
    if (!await _auth.reauthenticateForDeletion(password: password)) {
      return AccountDeleteResult.cancelled;
    }
    try {
      await _remote.delete(uid);
    } on SyncException catch (e) {
      debugPrint('Cloud copy delete failed: $e');
      return AccountDeleteResult.failed;
    }
    final silindi = await deleteIdentityAndPartnerData?.call() ?? true;
    if (!silindi) return AccountDeleteResult.failed;
    await _clearConsent();
    await _stateStore.clear(uid);
    _account = null;
    _syncEnabled = false;
    _lastSyncAt = null;
    _status = SyncStatus.idle;
    await onIdentityChanged?.call();
    return AccountDeleteResult.deleted;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
