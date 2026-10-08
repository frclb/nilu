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

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    _isPartner = prefs.getBool('isPartner') ?? false;
    _partnerId = prefs.getString('partnerId');
    _myId = prefs.getString('myId');
    _hasPartner = prefs.getBool('hasPartner') ?? (_partnerId != null);

    // Eğer auth açıksa ve daha önce giriş yapılmışsa myId'yi oradan al
    final user = _authDS.currentUser;
    if (user != null) {
      _myId = user.uid;
      await prefs.setString('myId', user.uid);
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

  /// Kullanıcı kimliğini **tek bir yerden** üretir ve kalıcılaştırır.
  ///
  /// Öncelik sırası:
  /// 1. Zaten kayıtlı bir `myId` varsa o kullanılır.
  /// 2. Firebase erişilebiliyorsa anonim giriş yapılıp UID kullanılır.
  /// 3. Aksi halde yerel bir UUID üretilir (yerel-only mod).
  ///
  /// QR eşleştirme ve onboarding aynı kimliği görsün diye her iki akış da
  /// bu metodu çağırır — kimliği başka hiçbir yerde üretme.
  Future<String> ensureMyId() async {
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
    // kimliğine bakıyor. Önceden giriş bir kez başarısız olunca yerel bir
    // UUID kalıcı olarak saklanıyor ve bir daha giriş denenmiyordu; o
    // cihazdan eşleşme hiçbir zaman kurulamıyordu.
    final oturum = _authDS.currentUser?.uid;
    if (oturum != null) return sakla(oturum);

    if (!_firestoreDS.isAvailable) {
      final mevcut = _myId;
      return (mevcut != null && mevcut.isNotEmpty)
          ? mevcut
          : sakla(const Uuid().v4());
    }

    final uid = (await _authDS.signInAnonymously())?.user?.uid;
    if (uid != null) return sakla(uid);
    // Giriş başarısız: geçici kimlik, saklanmıyor — sonraki deneme gerçek
    // kimliği alabilsin. Bu kimlikle yapılan yazımları kurallar reddeder
    // ve ekran "bağlantı kurulamadı" der.
    return _myId ?? const Uuid().v4();
  }

  /// Onboarding'i tamamlar.
  ///
  /// Önceden burada her kullanıcı için anonim Firebase girişi yapılıyor,
  /// sunucuda bir profil dokümanı açılıyor ve bildirim jetonu yazılıyordu —
  /// partner modunu hiç kullanmayacak kullanıcı için bile. Kimlik artık
  /// yalnızca eşleşme başlatılınca üretiliyor ([ensureMyId]); onboarding
  /// sunucuya hiçbir şey yazmıyor.
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
  Future<bool> requestPartnerAccess({
    required String token,
    required String ownerUid,
  }) async {
    final myId = await ensureMyId();
    if (!await _firestoreDS.requestPairing(token, myId)) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_requestTokenKey, token);
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

  /// Yerel veri tamamen silindikten sonra durumu sıfırdan okur.
  /// (Profil → "Tüm verilerimi sil" akışı bunu çağırır.)
  Future<void> reloadAfterDataWipe() async {
    _onboardingComplete = false;
    _isPartner = false;
    _partnerId = null;
    _myId = null;
    _hasPartner = false;
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
