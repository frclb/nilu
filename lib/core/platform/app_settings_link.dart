import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Uygulamanın **kendi** ayar sayfasını açar.
///
/// iOS'ta reddedilen bir izni uygulama ikinci kez soramıyor: sistem istemi bir
/// kez gösteriliyor. Geriye tek yol Ayarlar kalıyor ve kullanıcıya "Ayarlar →
/// Period Tracker → Kamera" diye tarif etmek, tarifi takip etmeyi gerektiriyor.
/// Tek dokunuşla oraya götürmek aynı şeyi yapıyor.
///
/// `app-settings:` yalnızca **uygulamaya ait** izinleri gösteriyor: kamera,
/// bildirim, Face ID, mikrofon. Sağlık izinleri orada **yok** — onlar Sağlık
/// uygulamasında duruyor, o yüzden Sağlık ekranında bu düğme kullanılmıyor,
/// yolu yazıyla tarif ediliyor. Yanlış sayfaya götüren bir düğme, hiç düğme
/// olmamasından kötü.
///
/// Ayarların belirli bir bölümüne (ör. `App-Prefs:NOTIFICATIONS_ID`) derin
/// bağlantı **bilerek** kullanılmıyor: Apple bunu belgelemiyor ve incelemede
/// ret sebebi oluyor.
class AppSettingsLink {
  const AppSettingsLink._();

  /// Apple'ın `UIApplication.openSettingsURLString` sabitinin değeri.
  static const String uri = 'app-settings:';

  /// Bu platformda ayar sayfası açılabiliyor mu?
  ///
  /// Yalnızca iOS. Android'de uygulamanın ayarlarına gitmek bir intent
  /// gerektiriyor ve bu sürüm iOS için yayınlanıyor. Desteklenmeyen yerde
  /// düğme hiç çizilmiyor — dokunulduğunda hiçbir şey olmayan bir düğme,
  /// kullanıcıya arıza gibi görünür.
  static bool get isSupported => !kIsWeb && Platform.isIOS;

  /// Test edilebilirlik için açma çağrısı ayrık tutuldu.
  @visibleForTesting
  static Future<bool> Function(Uri uri) launcher = launchUrl;

  /// Ayar sayfasını açar. Açılamazsa false.
  static Future<bool> open() async {
    if (!isSupported) return false;
    try {
      return await launcher(Uri.parse(uri));
    } catch (e) {
      debugPrint('Could not open app settings: $e');
      return false;
    }
  }

  @visibleForTesting
  static void resetForTest() => launcher = launchUrl;
}
