import 'dart:io';

import 'package:flutter/foundation.dart';

/// Platforma göre değişen özellikler — tek yerde.
///
/// Uygulama önce yalnızca iOS için yazıldı; Android'de farklı olan şeyler
/// (mağaza, Apple Sağlık yerine Health Connect) ekranlara dağılmış
/// `Platform.isIOS` kontrolleri yerine buradan soruluyor.
///
/// Karar `defaultTargetPlatform`'dan değil gerçek işletim sisteminden: o
/// değer `flutter_test`'te varsayılan olarak Android ve mevcut testler iOS
/// davranışını sınıyor. Android davranışı testte [debugAndroid] ile kuruluyor.
abstract final class AppPlatform {
  /// Testte platformu değiştirmek için; `null` gerçek platform.
  @visibleForTesting
  static bool? debugAndroid;

  static bool get isAndroid => debugAndroid ?? (!kIsWeb && Platform.isAndroid);

  /// Play'in abonelikler sayfası; bu uygulamanınkini açıyor.
  static const String playSubscriptionsUrl =
      'https://play.google.com/store/account/subscriptions'
      '?package=com.furkan.rcperiodtracker';
}
