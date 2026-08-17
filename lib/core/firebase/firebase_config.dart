import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase bootstrap.
///
/// `Firebase.initializeApp()` platform yapılandırma dosyalarını okur
/// (Android: `google-services.json`, iOS: `GoogleService-Info.plist`).
/// Bu dosyalar henüz eklenmediyse init başarısız olur; bu durumda uygulama
/// çökmek yerine **yerel-only modda** çalışmaya devam eder ve tüm uzak
/// veri kaynakları devre dışı kalır ([isAvailable] false olur).
class FirebaseConfig {
  static bool _isAvailable = false;

  /// Firebase başarıyla başlatıldıysa true. DataSource'lar uzak çağrı
  /// yapmadan önce bunu kontrol eder.
  static bool get isAvailable => _isAvailable;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _isAvailable = true;
      debugPrint("Firebase successfully initialized.");
    } catch (e) {
      _isAvailable = false;
      debugPrint(
        "Firebase not configured — running in local-only mode. "
        "Add the platform config files (or run `flutterfire configure`) "
        "to enable remote features. Reason: $e",
      );
    }
  }
}
