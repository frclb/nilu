import 'dart:io';

import 'package:flutter/foundation.dart';

/// Platforma göre değişen özellikler — tek yerde.
///
/// Uygulama önce yalnızca iOS için yazıldı; Android'de henüz olmayan ya da
/// farklı olan şeyler ekranlara dağılmış `Platform.isIOS` kontrolleri yerine
/// burada.
///
/// Karar `defaultTargetPlatform`'dan değil gerçek işletim sisteminden: o
/// değer `flutter_test`'te varsayılan olarak Android ve mevcut testler iOS
/// davranışını sınıyor. Android davranışı testte [debugAndroid] ile kuruluyor.
abstract final class AppPlatform {
  /// Testte platformu değiştirmek için; `null` gerçek platform.
  @visibleForTesting
  static bool? debugAndroid;

  static bool get isAndroid => debugAndroid ?? (!kIsWeb && Platform.isAndroid);

  /// Apple Sağlık eşitlemesi. Android'de Health Connect henüz bağlanmadı:
  /// izin beyanı ve Play'in sağlık verisi formu ayrı bir iş.
  static bool get healthSync => !isAndroid;

  /// Ana ekran widget'ı. Yalnızca iOS'ta (WidgetKit) yazıldı.
  static bool get homeWidget => !isAndroid;

  /// Mağazaya göre metin anahtarı: ödeme ve abonelik yönetimi App Store'da
  /// ya da Google Play'de. Android karşılığı `<anahtar>_android`.
  static String storeKey(String key) => isAndroid ? '${key}_android' : key;

  /// Play'in abonelikler sayfası; bu uygulamanınkini açıyor.
  static const String playSubscriptionsUrl =
      'https://play.google.com/store/account/subscriptions'
      '?package=com.furkan.rcperiodtracker';
}
