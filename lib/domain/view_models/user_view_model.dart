import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/firebase_auth_datasource.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../data/repositories/pairing_repository.dart';
import '../services/subscription_service.dart';

class UserViewModel extends ChangeNotifier {
  final FirebaseAuthDataSource _authDS;
  final FirestoreDataSource _firestoreDS;
  final PairingRepository _pairing;

  /// Durum yerel depodan okunana kadar false kalır.
  ///
  /// Router bunu bekler: okuma bitmeden yönlendirme yaparsak dönen kullanıcıyı
  /// yanlışlıkla onboarding'e düşürürüz (okuma asenkron olduğu için başlangıçta
  /// tüm bayraklar varsayılan değerindedir).
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // ─── Onboarding ───
  bool _onboardingComplete = false;
  bool get onboardingComplete => _onboardingComplete;

  bool _isPartner = false;
  String? _partnerId;
  String? _myId;
  bool _hasPartner = false;

  bool get isPartner => _isPartner;
  String? get partnerId => _partnerId;

  /// Partner olarak bırakılan ve henüz kapanmamış isteğin kodu.
  String? _requestToken;
  String? get pendingRequestToken => _requestToken;
  String? get myId => _myId;
  bool get hasPartner => _hasPartner;

  /// Uzak kaynaklar testte sahteleriyle değiştirilebilsin diye enjekte.
  UserViewModel({
    FirebaseAuthDataSource? auth,
    FirestoreDataSource? firestore,
    PairingRepository? pairing,
  }) : _authDS = auth ?? FirebaseAuthDataSource(),
       _firestoreDS = firestore ?? FirestoreDataSource(),
       _pairing =
           pairing ??
           PairingRepository(remote: firestore ?? FirestoreDataSource()) {
    _loadState();
  }

  /// Partner olarak okutulan kod; onaylanmadan ayrılırsa istek geri
  /// çekilsin diye saklanıyor.
  static const String _requestTokenKey = 'pairing_request_token';
  static const String _signInSkippedKey = 'sign_in_skipped';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    _isPartner = prefs.getBool('isPartner') ?? false;
    _partnerId = prefs.getString('partnerId');
    _myId = prefs.getString('myId');
    _hasPartner = prefs.getBool('hasPartner') ?? (_partnerId != null);
    _requestToken = prefs.getString(_requestTokenKey);
    _signInSkipped = prefs.getBool(_signInSkippedKey) ?? false;

    // Hesapla giriş yapılmışsa kimlik onun uid'si.
    final uid = _accountUid;
    if (uid != null) {
      _myId = uid;
      await prefs.setString('myId', uid);
    }

    _isLoaded = true;
    notifyListeners();
  }

  /// Firebase açılıştan sonra hazır olduğunda kimlik durumunu tazeler.
  ///
  /// `_loadState` ilk karede çalışıyor ve o sırada Firebase henüz
  /// başlatılmamış olabiliyor — açılış artık onu beklemiyor. O anda
  /// `currentUser` null döner ve oturum açmış kullanıcının uid'si
  /// tazelenmez; bu çağrı açığı kapatıyor.
  Future<void> refreshAuthState() => _loadState();

  /// Onboarding'in tamamlandığını işaretler.
  ///
  /// Ekranlar `SharedPreferences`'a doğrudan yazmamalıdır: o yol bellek içi
  /// durumu güncellemediği için router eski değeri görmeye devam eder.
  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    _onboardingComplete = true;
    notifyListeners();
  }

  String? get _accountUid => _authDS.accountUid;

  /// Giriş ekranı bir kez gösteriliyor: "Hesap olmadan devam et" denince
  /// bir daha sorulmuyor.
  bool _signInSkipped = false;

  /// Hesap hizmeti hazır, oturum yok ve giriş ekranı henüz geçilmedi:
  /// karşılamadan sonra giriş ekranı geliyor (bkz. `resolveRedirect`).
  ///
  /// Hesap isteğe bağlı (App Store 5.1.1(v)): takip, gebelik modu ve
  /// yedekleme hesapsız çalışıyor; hesap yalnızca bulut yedeği, yeni
  /// telefona taşıma ve partner eşleşmesi için gerekiyor. 29 Ekim'de bir
  /// gün boyunca zorunluydu. Firebase yapılandırılmamışsa (testler, yerel
  /// mod) giriş istenmiyor.
  bool get needsSignIn => needsAccountForPairing && !_signInSkipped;

  /// "Hesap olmadan devam et": giriş ekranı bir daha zorla açılmıyor;
  /// giriş Profil → Hesap ve bulut yedeği'nden yapılabiliyor.
  Future<void> skipSignIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signInSkippedKey, true);
    _signInSkipped = true;
    notifyListeners();
  }

  /// E-postayla giriş yapılmış ama adres doğrulanmamış: uygulama
  /// doğrulanana kadar kullanılmıyor (bkz. `resolveRedirect`).
  bool get needsEmailVerification =>
      _firestoreDS.isAvailable && _authDS.needsEmailVerification;

  /// Eşleşme sunucusu var ama hesap yok: eşleşmeden önce giriş gerekiyor
  /// (giriş ekranı geçilmiş olsa da).
  bool get needsAccountForPairing =>
      _firestoreDS.isAvailable && _accountUid == null;

  /// Eşleşmede kullanılan kimlik; **tek bir yerden**.
  ///
  /// 1. Sunucu varken kimlik hesabın uid'si. Hesap yoksa `null`: partner
  ///    eşleşmesi Apple ya da Google ile giriş istiyor.
  /// 2. Sunucu yoksa (yerel mod, testler) yerel bir UUID; eşleşme zaten
  ///    kapalı.
  ///
  /// Eskiden hesap yoksa anonim bir Firebase kimliği açılıyordu. Kaldırıldı:
  /// eşleşme ve paylaşılan durum artık hesaba bağlı, "Hesabı sil" hepsini
  /// birlikte kaldırıyor.
  ///
  /// QR eşleştirme ve onay aynı kimliği görsün diye hepsi bu metodu
  /// çağırır — kimliği başka hiçbir yerde üretme.
  Future<String?> ensureMyId() async {
    final prefs = await SharedPreferences.getInstance();

    Future<String> sakla(String id) async {
      if (_myId != id) {
        await prefs.setString('myId', id);
        _myId = id;
        notifyListeners();
      }
      return id;
    }

    // Sunucu varken kimlik **oturumun** kimliği olmalı: kurallar yazanın
    // kimliğine bakıyor.
    final oturum = _accountUid;
    if (oturum != null) return sakla(oturum);

    if (!_firestoreDS.isAvailable) {
      final mevcut = _myId;
      return (mevcut != null && mevcut.isNotEmpty)
          ? mevcut
          : sakla(const Uuid().v4());
    }

    return null;
  }

  /// Onboarding'i tamamlar.
  ///
  /// Önceden burada her kullanıcı için anonim Firebase girişi yapılıyor,
  /// sunucuda bir profil dokümanı açılıyor ve bildirim jetonu yazılıyordu —
  /// partner modunu hiç kullanmayacak kullanıcı için bile. Kimlik artık
  /// hesaptan geliyor ([ensureMyId]); onboarding sunucuya hiçbir şey
  /// yazmıyor.
  Future<void> completeOnboarding() => markOnboardingComplete();

  Future<void> setPartnerState({
    required bool isPartner,
    String? partnerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPartner', isPartner);

    // Yalnızca yerel durum. Uzak taraftaki erişim [approvePartnerRequest],
    // [removePartnerAccess] ve [leavePartnerRole] ile değişiyor. Önceden
    // burada da yazılıyordu: kodu okutan partner, sahibi **kendi**
    // listesine ekliyor; onaylayan sahip aynı yazımı iki kez yapıyordu.
    final hasPartnerNow = partnerId != null;
    if (partnerId != null) {
      await prefs.setString('partnerId', partnerId);
    } else {
      await prefs.remove('partnerId');
    }
    await prefs.setBool('hasPartner', hasPartnerNow);

    _isPartner = isPartner;
    _partnerId = partnerId;
    _hasPartner = hasPartnerNow;

    notifyListeners();
  }

  Future<void> setMyId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('myId', id);
    _myId = id;
    notifyListeners();
  }

  Future<void> setHasPartner(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasPartner', value);
    _hasPartner = value;
    notifyListeners();
  }

  // ─── Partner bağlantısı ───

  /// Sahip bir eşleştirme isteğini onaylar.
  ///
  /// **Tek partner.** Önceki partner varsa erişimi kalkıyor ve paylaşılmış
  /// durum geri çekiliyor: yeni partner, öncekine gönderilmiş durumu
  /// görmemeli. Sunucuya yazılamazsa hiçbir şey değişmiyor ve `false`.
  Future<bool> approvePartnerRequest(
    String requesterUid, {
    required String token,
  }) async {
    final myId = await ensureMyId();
    if (myId == null) return false;
    final previous = _partnerId;
    if (!await _firestoreDS.approvePartner(myId, requesterUid)) return false;
    if (previous != null && previous != requesterUid) {
      await _firestoreDS.deleteIntimacyStatus(myId);
    }
    await _firestoreDS.clearPairingRequest(token, requesterUid);
    await setPartnerState(isPartner: false, partnerId: requesterUid);
    return true;
  }

  /// Sahip partnerin erişimini kaldırır.
  ///
  /// Önceden yalnızca listeden çıkarılıyordu: paylaşılmış son durum
  /// sunucuda kalıyor, eski QR da geçerliliğini koruyordu. Şimdi durum
  /// siliniyor ve kod yenileniyor — eski QR ile yeniden istek
  /// gönderilemiyor.
  Future<bool> removePartnerAccess() async {
    final myId = _myId;
    final partner = _partnerId;
    if (myId != null && partner != null && _firestoreDS.isAvailable) {
      if (!await _firestoreDS.removePartner(myId, partner)) return false;
      await _firestoreDS.deleteIntimacyStatus(myId);
      await _pairing.rotate(myId);
    }
    await setPartnerState(isPartner: false, partnerId: null);
    return true;
  }

  /// Partner kodu okuttuktan sonra: istek bırakılır ve bu cihaz partner
  /// moduna geçer. Veri ancak sahip onaylayınca okunabiliyor.
  ///
  /// [invite]: kod tek kullanımlık bir davet bağlantısı; istekle aynı
  /// yazımda bu kişiye bağlanıyor.
  Future<bool> requestPartnerAccess({
    required String token,
    required String ownerUid,
    bool invite = false,
  }) async {
    final myId = await ensureMyId();
    if (myId == null) return false;
    if (!await _firestoreDS.requestPairing(token, myId, claim: invite)) {
      return false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_requestTokenKey, token);
    _requestToken = token;
    await setPartnerState(isPartner: true, partnerId: ownerUid);
    await completeOnboarding();
    return true;
  }

  /// Partner kendi erişimini bırakır ve partner modundan çıkar.
  ///
  /// Önceden yalnızca bu cihazdaki kayıt siliniyordu: sahibin listesinde
  /// kalan partner yeniden okuyabiliyordu, onay bekleyen istek de sahibin
  /// ekranında duruyordu. Şimdi ikisi de sunucudan kalkıyor. Sunucuya
  /// ulaşılamazsa `false` — "bağlantı kesildi" denmiyor.
  ///
  /// Bu cihaz kendi döngüsü için hiç kurulmadı; kurulum baştan başlıyor.
  Future<bool> leavePartnerRole() async {
    final myId = _myId;
    final owner = _partnerId;
    final prefs = await SharedPreferences.getInstance();
    if (myId != null && owner != null && _firestoreDS.isAvailable) {
      final ok = await _firestoreDS.leavePartner(ownerUid: owner, myUid: myId);
      if (!ok) return false;
      final token = prefs.getString(_requestTokenKey);
      if (token != null) await _firestoreDS.clearPairingRequest(token, myId);
    }
    await prefs.remove(_requestTokenKey);
    _requestToken = null;
    await setPartnerState(isPartner: false, partnerId: null);
    await prefs.setBool('onboarding_complete', false);
    _onboardingComplete = false;
    notifyListeners();
    return true;
  }

  /// Hesabın uzak verisini siler.
  ///
  /// "Tüm verilerimi sil" yalnızca cihazdaki veriyi siliyordu; Firestore'daki
  /// profil, loglar ve yakınlık dokümanı yerinde kalıyordu — bağlı partner
  /// hesap silindikten sonra da veriyi okumaya devam edebiliyordu.
  ///
  /// Yerel silmeden **önce** çağrılmalı: `_myId` temizlendikten sonra hangi
  /// dokümanın silineceği bilinemez.
  /// Hesap gerçekten silindi mi? Kimlik silinemediyse `false`.
  Future<bool> deleteRemoteData() async {
    final uid = _myId;
    if (uid == null || uid.isEmpty) return true;

    // Eşleşme kodu da iptal ediliyor. `PairingRepository.revoke()` bu akış
    // için yazılmıştı ama hiç çağrılmıyordu: hesap silindikten sonra
    // sunucuda jeton→uid eşlemesi duruyordu. Elinde eski QR olan biri
    // silinmiş bir hesaba istek gönderebilir, üstelik gizlilik
    // politikasının "tüm verileriniz kalıcı olarak kaldırılır" sözü
    // tutulmamış olurdu.
    try {
      await _pairing.revoke();
    } catch (e) {
      debugPrint('Pairing token revoke failed: $e');
    }

    if (_isPartner && _partnerId != null) {
      // Partner rolünde liste sahibin dokümanında: kendimizi oradan
      // çıkarıyoruz. Kendi listemizde kimse yok.
      await _firestoreDS.leavePartner(ownerUid: _partnerId!, myUid: uid);
      await _firestoreDS.deleteUserData(uid);
    } else {
      await _firestoreDS.deleteUserData(uid, partnerId: _partnerId);
    }

    try {
      await SubscriptionService.logout();
    } catch (e) {
      debugPrint('Subscription logout after data deletion failed: $e');
    }

    // Veriden sonra kimliğin kendisi. Silinemezse oturumu kapatıp geri
    // dönüyoruz: çağıran taraf kullanıcıya yeniden giriş yapması gerektiğini
    // söylemeli, "hesabın silindi" dememeli.
    final deleted = await _authDS.deleteAccount();
    if (!deleted) {
      try {
        await _authDS.signOut();
      } catch (e) {
        debugPrint('Sign out after failed account delete: $e');
      }
    }
    return deleted;
  }

  /// Hesap silindi ama bu cihazdaki kayıtlar kalıyor (Profil → Hesap →
  /// "Hesabı sil"). Kimlik ve partner bağlantısı silinmiş hesaba aitti;
  /// bu cihazda onlara işaret eden bir şey kalmamalı. Onboarding durumu
  /// değişmiyor: kullanıcı kendi döngüsünü kullanmaya devam ediyor.
  Future<void> forgetIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('myId');
    await prefs.remove(_requestTokenKey);
    _myId = null;
    _requestToken = null;
    await setPartnerState(isPartner: false, partnerId: null);
  }

  /// Yerel veri tamamen silindikten sonra durumu sıfırdan okur.
  /// (Profil → "Tüm verilerimi sil" akışı bunu çağırır.)
  Future<void> reloadAfterDataWipe() async {
    _onboardingComplete = false;
    _isPartner = false;
    _partnerId = null;
    _myId = null;
    _hasPartner = false;
    _requestToken = null;
    _isLoaded = false;
    notifyListeners();
    await _loadState();
  }

  /// Normal kullanıcı girişinde partner modunu sıfırlar.
  Future<void> resetPartnerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPartner', false);
    _isPartner = false;
    notifyListeners();
  }
}
