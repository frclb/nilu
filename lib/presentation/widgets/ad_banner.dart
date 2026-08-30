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
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isPremium = context.watch<SubscriptionViewModel>().isPremium;
    if (PremiumGate.showsAds(isPremium: isPremium)) {
      _load();
    } else {
      _dispose();
    }
  }

  void _load() {
    if (_ad != null) return;
    final ad = BannerAd(
      adUnitId: AdsDatasource.bannerUnitId,
      size: AdSize.banner,
      request: AdsDatasource.request,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        // Reklam yüklenemezse alan hiç görünmüyor; boş bir kutu bırakmak
        // ekranda açıklanamayan bir boşluk yaratıyordu.
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  void _dispose() {
    _ad?.dispose();
    _ad = null;
    _loaded = false;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();

    final t = context.tokens;
    return Container(
      alignment: Alignment.center,
      width: double.infinity,
      height: AdSize.banner.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        border: Border.symmetric(horizontal: BorderSide(color: t.border)),
      ),
      child: SizedBox(
        width: AdSize.banner.width.toDouble(),
        height: AdSize.banner.height.toDouble(),
        child: AdWidget(ad: ad),
      ),
    );
  }
}
