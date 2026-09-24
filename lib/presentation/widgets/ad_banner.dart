import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/ads_datasource.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/premium_gate.dart';
import '../../domain/view_models/subscription_view_model.dart';

/// Ücretsiz katmanda gösterilen banner.
///
/// Premium'da hiç kurulmuyor — gizlenmiyor, ağ isteği de yapılmıyor.
///
/// Nerede kullanılacağı bilinçli olarak sınırlı: kütüphane ve içerik
/// ekranları. Kullanıcının semptom girdiği, takvimini işaretlediği ya da
/// analizine baktığı ekranlarda reklam yok — orada reklam hem rahatsız edici
/// hem bağlam olarak yanlış.
///
/// Reklam rızası (AEA) burada çözülüyor: uygulamada reklamın göründüğü ilk
/// yer burası, dolayısıyla formun sorulması gereken en geç an da burası.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  AdSize? _size;
  bool _loaded = false;
  bool _requesting = false;

  /// Bu bağlanmada bir kez denendi mi?
  ///
  /// `didChangeDependencies` birden çok kez çalışıyor: abonelik durumu
  /// depodan geldiğinde `SubscriptionViewModel` haber veriyor ve `watch`
  /// yüzünden burası yeniden tetikleniyor. Yalnızca "yükleniyor mu" bakmak
  /// yetmedi — ilk deneme bitmiş oluyor ve ikincisi rıza formunu **yeniden**
  /// açıyordu. Formu kapatan kullanıcı her yeniden çizimde onu tekrar
  /// görürdü.
  bool _attempted = false;

  /// Devam eden asenkron yüklemeyi geçersiz kılmak için.
  ///
  /// Yükleme birkaç `await` sürüyor; arada premium'a geçilirse ya da widget
  /// ağaçtan çıkarsa geriye dönen sonucun kendini kurmaması gerekiyor.
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isPremium = context.watch<SubscriptionViewModel>().isPremium;
    if (PremiumGate.showsAds(isPremium: isPremium)) {
      // Genişlik yalnızca **ilk** yüklemede okunuyor; dönmede ya da iPad'de
      // Split View sürüklenirken yeniden yüklenmiyor. Genişlik değiştikçe
      // reklam istemek, kullanıcı hiçbir şey yapmadan arka arkaya istek
      // üretirdi — hem geçersiz trafik sayılır hem de bir şeyi düzeltmez:
      // reklam ortalanmış duruyor, yalnızca bandından dar kalıyor.
      unawaited(_load(MediaQuery.sizeOf(context).width));
    } else {
      _release();
    }
  }

  Future<void> _load(double maxWidth) async {
    if (_ad != null || _requesting || _attempted) return;
    _requesting = true;
    _attempted = true;
    final generation = _generation;
    try {
      // Rıza alınamadıysa reklam istenmiyor: AEA'da rızasız istek hem Google
      // politikasına hem ePrivacy'ye aykırı.
      if (!await AdsDatasource.ensureReady(mayShowForm: true)) return;
      if (!mounted || generation != _generation) return;

      final requested = AdsDatasource.bannerSize(maxWidth);

      final ad = BannerAd(
        adUnitId: AdsDatasource.bannerUnitId,
        size: requested,
        request: AdsDatasource.request,
        listener: BannerAdListener(
          // Inline uyarlanabilir boyutun yüksekliği istenirken 0: gerçek
          // yüksekliği Google reklamı seçtikten sonra biliyor. Bant onu
          // öğrenene kadar çizilmiyor, yoksa önce sıfır yükseklikte, sonra
          // birden açılan bir kutu olurdu.
          onAdLoaded: (loaded) async {
            // Ölçüm **bir kez** alınıyor. Google inline reklamı yeniden
            // ölçtüğünde bandın o anki yüksekliğini bildiriyor; onu geri
            // yazmak kendi kendini besleyen bir döngü kuruyordu.
            if (_size != null) return;
            final actual = await (loaded as BannerAd).getPlatformAdSize();
            if (!mounted || generation != _generation || _size != null) return;
            setState(() {
              _size = actual;
              _loaded = actual != null;
            });
          },
          // Reklam yüklenemezse alan hiç görünmüyor; boş bir kutu bırakmak
          // ekranda açıklanamayan bir boşluk yaratıyordu.
          onAdFailedToLoad: (failed, error) {
            // Önce bağı kopar, sonra bırak: `dispose()` iki kez çağrılmasın.
            if (identical(_ad, failed)) {
              _ad = null;
              _size = null;
              _loaded = false;
            }
            failed.dispose();
            if (mounted && generation == _generation) setState(() {});
          },
        ),
      );
      _ad = ad;
      await ad.load();
    } finally {
      _requesting = false;
    }
  }

  void _release() {
    _generation++;
    final ad = _ad;
    _ad = null;
    _size = null;
    _loaded = false;
    // Premium'a geçip geri dönen kullanıcı yeniden deneyebilsin.
    _attempted = false;
    ad?.dispose();
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    final size = _size;
    if (!_loaded || ad == null || size == null) return const SizedBox.shrink();

    final t = context.tokens;
    // Kutuya yükseklik **verilmiyor**: yüksekliği içindeki reklam belirliyor.
    // Kenarlık 1'er punto ve `height` verildiğinde o iki punto kutunun
    // içinden kesiliyordu; reklam eziliyor, ölçüm küçülüyor, küçülen ölçü
    // geri yazılıyordu. 56 puntodan 32'ye inip "gösterilecek reklam yok"a
    // düşmesinin sebebi buydu.
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        border: Border.symmetric(horizontal: BorderSide(color: t.border)),
      ),
      child: SizedBox(
        width: size.width.toDouble(),
        height: size.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
