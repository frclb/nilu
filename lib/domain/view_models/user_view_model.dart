import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/remote/firebase_auth_datasource.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../data/datasources/remote/notification_service.dart';
import '../services/subscription_service.dart';

class UserViewModel extends ChangeNotifier {
  final FirebaseAuthDataSource _authDS = FirebaseAuthDataSource();
  final FirestoreDataSource _firestoreDS = FirestoreDataSource();
  final NotificationService _notificationService = NotificationService();

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

  UserViewModel() {
    _loadState();
  }

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
      // Push bildirim için token dinlemeyi başlat
      _notificationService.initialize(user.uid);
    }

    _isLoaded = true;
    notifyListeners();
  }

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

  /// Oturumu kapatır.
  ///
  /// Uzak oturumu (Firebase, RevenueCat) sonlandırır, oturuma ait yerel
  /// bayrakları sıfırlar ve kullanıcıyı onboarding'e döndürür.
  ///
  /// **Sağlık verisini silmez** — o, Profil → Gizlilik → "Hesabımı Sil"
  /// akışının işidir. Çıkış yalnızca oturumu bitirir.
  Future<void> signOut() async {
    try {
      await _authDS.signOut();
      await SubscriptionService.logout();
    } catch (e) {
      // Uzak taraf başarısız olsa da yerel oturum kapatılmalı.
      debugPrint('Sign out (remote) failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', false);
    await prefs.setBool('isPartner', false);
    await prefs.setBool('hasPartner', false);
    await prefs.remove('partnerId');
    await prefs.remove('myId');

    _onboardingComplete = false;
    _isPartner = false;
    _hasPartner = false;
    _partnerId = null;
    _myId = null;
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
    if (_myId != null && _myId!.isNotEmpty) return _myId!;

    final prefs = await SharedPreferences.getInstance();

    final credential = await _authDS.signInAnonymously();
    final uid = credential?.user?.uid ?? const Uuid().v4();

    await prefs.setString('myId', uid);
    _myId = uid;
    notifyListeners();
    return uid;
  }

  /// Onboarding tamamlandığında kimliği çözer, (mümkünse) Firestore'da profil
  /// oluşturur ve onboarding'i tamamlanmış olarak işaretler.
  ///
  /// Firebase erişilemese bile onboarding **her zaman** tamamlanır; uygulama
  /// yerel-only modda çalışmaya devam eder.
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final uid = await ensureMyId();

      // Firestore'da kullanıcı dokümanı oluştur (Firebase yoksa no-op)
      await _firestoreDS.createUserProfile(uid, {
        'createdAt': DateTime.now().toIso8601String(),
        'isPartner': _isPartner,
        'hasPartner': _hasPartner,
      });

      // Bildirimleri başlat (Firebase yoksa no-op)
      _notificationService.initialize(uid);
    } catch (e) {
      debugPrint("Error completing onboarding: $e");
    }

    // Uzak taraf başarısız olsa bile kullanıcıyı onboarding'de kilitleme.
    await prefs.setBool('onboarding_complete', true);
    _onboardingComplete = true;
    notifyListeners();
  }

  Future<void> setPartnerState({
    required bool isPartner,
    String? partnerId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPartner', isPartner);

    bool hasPartnerNow = false;
    if (partnerId != null) {
      await prefs.setString('partnerId', partnerId);
      hasPartnerNow = true;

      // Eğer kendi UID'miz varsa Firestore'da da bağlantıyı kur
      if (_myId != null) {
        await _firestoreDS.savePartnerConnection(_myId!, partnerId);
      }
    } else {
      await prefs.remove('partnerId');
      hasPartnerNow = false;

      // Eğer kendi UID'miz varsa ve eski bir partnerId varsa Firestore'da bağlantıyı kes
      if (_myId != null && _partnerId != null) {
        await _firestoreDS.disconnectPartner(_myId!, _partnerId!);
      }
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

  /// Hesabın uzak verisini siler.
  ///
  /// "Hesabımı Sil" yalnızca cihazdaki veriyi siliyordu; Firestore'daki profil,
  /// loglar ve yakınlık dokümanı yerinde kalıyordu — bağlı partner hesap
  /// silindikten sonra da veriyi okumaya devam edebiliyordu.
  ///
  /// Yerel silmeden **önce** çağrılmalı: `_myId` temizlendikten sonra hangi
  /// dokümanın silineceği bilinemez.
  Future<void> deleteRemoteData() async {
    final uid = _myId;
    if (uid == null || uid.isEmpty) return;

    await _firestoreDS.deleteUserData(uid, partnerId: _partnerId);

    try {
      await _authDS.signOut();
      await SubscriptionService.logout();
    } catch (e) {
      // Uzak veri silindi; oturum kapatma başarısız olsa da akış sürmeli.
      debugPrint('Sign out after data deletion failed: $e');
    }
  }

  /// Yerel veri tamamen silindikten sonra durumu sıfırdan okur.
  /// (Profil → "Hesabımı Sil" akışı bunu çağırır.)
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
