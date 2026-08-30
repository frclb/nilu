import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Reklam kurulumu.
///
/// Reklamlar **kişiselleştirilmiyor**. Uygulama kullanıcıya üç yerde verisinin
/// cihazda kaldığını söylüyor; davranış verisiyle hedefli reklam bu sözle
/// çelişirdi. `nonPersonalizedAds` ile reklam kimliği kullanılmıyor, izleme
/// izni (ATT) istenmiyor ve gizlilik bildiriminde izleme beyan edilmiyor.
///
/// Karşılığı gelirin düşmesi; bilinçli bir takas.
class AdsDatasource {
  const AdsDatasource._();

  /// Kendi AdMob birim kimliklerin gelene kadar Google'ın test kimlikleri.
  ///
  /// Bunlar gerçek reklam göstermez ve gelir üretmez; yerlerine kendi
  /// kimliklerini koymadan yayına çıkarsan reklam alanı boş kalır.
  static const String _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';

  /// Banner reklam birimi.
  static String get bannerUnitId =>
      Platform.isIOS ? _testBannerIOS : _testBannerAndroid;

  /// Reklamlar için istek. Kişiselleştirme kapalı.
  static const AdRequest request = AdRequest(nonPersonalizedAds: true);

  /// SDK'yı başlatır. Başarısız olursa uygulama reklamsız çalışmaya devam eder.
  static Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          // Uygulama çocuklara yönelik değil ama içerik derecesi ayarlanıyor:
          // regl takibi bağlamında yetişkin içerikli reklam istenmez.
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
    } on Exception catch (e) {
      debugPrint('Ads init failed: $e');
    }
  }
}
