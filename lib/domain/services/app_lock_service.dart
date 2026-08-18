import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cihazın kilit yeteneği.
enum LockCapability {
  /// Biyometri kayıtlı (Face ID, Touch ID, parmak izi).
  biometric,

  /// Biyometri yok ama cihaz şifresi/deseni var.
  deviceCredential,

  /// Cihazda hiçbir kilit tanımlı değil.
  none;

  bool get isAvailable => this != LockCapability.none;
}

/// Uygulama kilidi.
///
/// Ekranda iki anahtar vardı — "Biyometrik Kilit" ve "PIN Kodu" — ve ikisi de
/// yalnızca bir tercih kaydediyordu; altlarında "henüz uygulanmıyor" notu
/// duruyordu. Yani sağlık uygulaması, telefonu eline alan herkese açıktı.
///
/// Kilit artık gerçek. Kendi PIN'imizi saklamıyoruz: cihazın kendi
/// kimlik doğrulaması kullanılıyor (biyometri, yoksa cihaz şifresi). Parola
/// saklamamak, saklamanın her türlüsünden güvenli.
class AppLockService {
  static const String enabledKey = 'app_lock_enabled';

  /// Arka plandan bu süreden önce dönülürse yeniden doğrulama istenmez.
  ///
  /// Sıfır olsaydı QR taramak için kameraya geçmek, bildirim panelini açmak
  /// ya da fotoğraf seçmek her seferinde kilit ekranı getirirdi.
  static const Duration graceperiod = Duration(seconds: 30);

  /// Sistem istemi kapandıktan sonra "hâlâ istem yüzünden" sayılacak süre.
  ///
  /// `resumed` olayı istem kapandıktan hemen sonra geliyor; sıfır olsaydı
  /// yarış nedeniyle bazen arka plana çıkılmış sayılırdı.
  static const Duration promptSettleWindow = Duration(seconds: 2);

  /// Ekranda bir sistem kimlik doğrulama istemi var mı.
  ///
  /// Statik, çünkü istemi kapı da açıyor (`AppLockGate`) gizlilik ekranındaki
  /// anahtar da; ikisi ayrı `AppLockService` örneği kullanıyor ama ekranda
  /// tek bir istem var. Kapı, kendi açmadığı bir istemi de "arka plana
  /// çıkıldı" saymamalı — yoksa kullanıcı ayarı değiştirir değiştirmez
  /// ikinci bir istem geliyordu.
  static bool _promptOnScreen = false;
  static DateTime? _promptEndedAt;

  bool get isSystemPromptActive {
    if (_promptOnScreen) return true;
    final ended = _promptEndedAt;
    return ended != null &&
        DateTime.now().difference(ended) < promptSettleWindow;
  }

  final LocalAuthentication _auth;

  AppLockService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(enabledKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(enabledKey, value);
  }

  /// Cihazın neyi desteklediği.
  ///
  /// Ayar açılmadan önce sorulur: kilidi açamayacağı bir cihazda kullanıcıyı
  /// kendi verisinden kilitlemek olmaz.
  Future<LockCapability> capability() async {
    try {
      if (await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty) {
        return LockCapability.biometric;
      }
      if (await _auth.isDeviceSupported()) {
        return LockCapability.deviceCredential;
      }
    } on Exception catch (e) {
      debugPrint('Lock capability check failed: $e');
    }
    return LockCapability.none;
  }

  /// Kullanıcıdan kimlik doğrulaması ister.
  ///
  /// [reason] sistem iletişim kutusunda görünür, lokalize gelmeli.
  Future<bool> authenticate({required String reason}) async {
    _promptOnScreen = true;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // Biyometri başarısız olursa cihaz şifresine düşsün: parmağı ıslak
          // olan kullanıcı kendi verisinden kilitlenmesin.
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on Exception catch (e) {
      // İptal, çok fazla deneme, donanım hatası — hepsinde kilitli kal.
      debugPrint('Authentication failed: $e');
      return false;
    } finally {
      _promptOnScreen = false;
      _promptEndedAt = DateTime.now();
    }
  }
}
