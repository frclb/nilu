import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_consent.dart';

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

  static bool _sdkStarted = false;

  /// Reklam istenebilecek duruma getirir: önce rıza, sonra SDK.
  ///
  /// Sıra önemli. Google, rıza çözülmeden SDK'nın başlatılmamasını istiyor —
  /// başlatma tek başına reklam istemese de SDK ön yükleme yapabiliyor. Sıranın
  /// tek bir yerde durması da bilinçli: açılıştaki çağrı ile banner'ın çağrısı
  /// ayrı ayrı yazılsaydı zamanla birbirinden ayrışırdı.
  ///
  /// [mayShowForm] yalnızca reklamın gerçekten gösterileceği yerde true olur;
  /// açılışta yalnızca durum tazelenir, kullanıcıya bir şey çıkmaz.
  static Future<bool> ensureReady({required bool mayShowForm}) async {
    if (!await AdConsent.resolve(mayShowForm: mayShowForm)) return false;
    await _startSdk();
    return _sdkStarted;
  }

  static Future<void> _startSdk() async {
    if (_sdkStarted) return;
    try {
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          // Uygulama çocuklara yönelik değil ama içerik derecesi ayarlanıyor:
          // regl takibi bağlamında yetişkin içerikli reklam istenmez.
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );
      _sdkStarted = true;
    } catch (e) {
      // Dar yakalama yetmiyor: SDK sarmalayıcısı platform yanıtına `!`
      // uyguluyor ve kanal yoksa `Exception` değil `Error` atıyor.
      debugPrint('Ads init failed: $e');
    }
  }

  /// Bandın alabileceği en fazla yükseklik (punto).
  ///
  /// Uyarlanabilir banner'ın "büyük" türü ekran yüksekliğinin **%15'ini**
  /// istiyor: ölçtüğümde iPhone'da 136, iPad'de 148 punto çıktı. Eski sabit
  /// banner 50 puntoydu. Genişlik sorununu çözerken bandı üç katına çıkarmak
  /// istenen şey değildi — uygulama reklamı iki ekranla sınırlıyor, boyutuyla
  /// da ölçülü kalmalı.
  ///
  /// 90: standart leaderboard yüksekliği. Genişliği dolduruyor, eskisinin
  /// 1,8 katı. Geliri artırmak için yükseltilebilir; tek yer burası.
  static const int maxBannerHeight = 90;

  /// Kaydırılan içeriğin içindeki banner boyutu.
  ///
  /// "Inline" tür seçildi, "anchored" değil: bant ekranın kenarına sabitlenmiş
  /// bir çubuk değil, listenin sonunda akan içeriğin parçası. Google'ın
  /// önerisi de bu — ve yalnızca bu tür yükseklik sınırı kabul ediyor.
  ///
  /// Genişlik ekranı dolduruyor. Sabit 320 punto, iPad'de ~1030 puntoluk
  /// bandın ortasında küçük bir kutu olarak duruyordu.
  ///
  /// Dönen boyutun yüksekliği 0: gerçek yükseklik reklam yüklendikten sonra
  /// [BannerAd.getPlatformAdSize] ile öğreniliyor.
  static InlineAdaptiveSize bannerSize(double maxWidth) =>
      AdSize.getInlineAdaptiveBannerAdSize(
        maxWidth.truncate(),
        maxBannerHeight,
      );

  /// Açılışta çağrılır: rıza durumu tazelenir, kullanıcıya form gösterilmez.
  static Future<void> init() async {
    await ensureReady(mayShowForm: false);
  }

  @visibleForTesting
  static void resetForTest() => _sdkStarted = false;
}
