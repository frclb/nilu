import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/view_models/subscription_view_model.dart';
import '../../../localization/app_localizations.dart';
import '../../../../core/navigation/navigation_service.dart';
import '../../../../core/navigation/route_names.dart';
import 'settings_surface.dart';

class PremiumBanner extends StatelessWidget {
  const PremiumBanner({super.key});

  void _open() => NavigationService().push(RouteNames.premium);

  @override
  Widget build(BuildContext context) {
    // Abone olmuş kullanıcıya "Premium'a Geç" demek yanlış: yerine durumu
    // söyleyen ince bir satır. Dokununca abonelik ekranı (orada yönetim
    // bağlantısı var).
    if (context.watch<SubscriptionViewModel>().isPremium) {
      return _ActiveRow(onTap: _open);
    }
    return _Offer(onTap: _open);
  }
}

/// Teklif kartının renkleri.
///
/// Açık temada derin erik degrade, üstünde beyaz yazı. Koyu temada marka
/// rengi açık bir erik; aynı degrade gece zemininde parlak bir pembe levha
/// gibi duruyordu. Orada kart yüzeyin erik tülü, yazı açık.
class _OfferColors {
  const _OfferColors({
    required this.gradient,
    required this.on,
    required this.ctaBackground,
    required this.ctaForeground,
    required this.ring,
  });

  factory _OfferColors.of(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      final start = Color.alphaBlend(scheme.primary.withAlpha(70), t.surface);
      return _OfferColors(
        gradient: [
          start,
          Color.alphaBlend(t.secondary.withAlpha(60), t.surface),
        ],
        on: t.text,
        ctaBackground: scheme.primary,
        ctaForeground: scheme.onPrimary,
        ring: start,
      );
    }
    return _OfferColors(
      gradient: [
        scheme.primary,
        scheme.primary,
        Color.alphaBlend(t.secondary.withAlpha(110), scheme.primary),
      ],
      on: scheme.onPrimary,
      ctaBackground: scheme.onPrimary,
      ctaForeground: scheme.primary,
      ring: scheme.primary,
    );
  }

  final List<Color> gradient;

  /// Kartın üstündeki yazı ve simge.
  final Color on;
  final Color ctaBackground;
  final Color ctaForeground;

  /// Özellik dairelerinin çevresi: kart zemini.
  final Color ring;
}

/// Abone olmayan kullanıcıya teklif kartı: erik degradesi, yumuşak ışıma.
class _Offer extends StatelessWidget {
  const _Offer({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final c = _OfferColors.of(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: c.gradient,
        ),
        boxShadow: AppShadows.floating(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Köşelerde renk ışımaları: gül sağ üstte, kehribar sol altta.
          Positioned(
            top: -60,
            right: -50,
            child: _Glow(color: t.secondary, size: 200),
          ),
          Positioned(
            bottom: -70,
            left: -50,
            child: _Glow(color: t.phaseLuteal, size: 170, alpha: 60),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTag(
                  label: context.tr('premium_title'),
                  icon: Icons.auto_awesome,
                  background: c.on.withAlpha(38),
                  foreground: c.on,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr('premium_banner_title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: c.on,
                    fontSize: 27,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  // Eski metin "sınırsız partner desteği" vaat
                  // ediyordu; öyle bir kilit yok. Üstelik bu iki
                  // satır hiç çevrilmemişti — Almanca cihazda da
                  // Türkçe çıkıyordu.
                  context.tr('premium_banner_desc'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: c.on.withAlpha(225),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    // Teklifteki üç özellik: trend, rapor dosyası, temalar.
                    ExcludeSemantics(child: _FeatureDots(ring: c.ring)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _CtaPill(
                          label: context.tr('premium_banner_cta'),
                          background: c.ctaBackground,
                          foreground: c.ctaForeground,
                          onTap: onTap,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size, this.alpha = 90});

  final Color color;
  final double size;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withAlpha(alpha), color.withAlpha(0)],
          ),
        ),
      ),
    );
  }
}

/// Üst üste binen üç küçük özellik dairesi.
class _FeatureDots extends StatelessWidget {
  const _FeatureDots({required this.ring});

  final Color ring;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final dots = [
      (Icons.insights_rounded, t.secondary),
      // Rapor dosyası PDF değil (özet metni ve tablo): belge simgesi.
      (Icons.description_outlined, t.phaseLuteal),
      (Icons.palette_outlined, t.fertile),
    ];
    const size = 30.0;
    const step = 22.0;
    return SizedBox(
      width: size + step * (dots.length - 1),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < dots.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dots[i].$2,
                  border: Border.all(color: ring, width: 2),
                ),
                child: Icon(dots[i].$1, size: 15, color: scheme.onPrimary),
              ),
            ),
        ],
      ),
    );
  }
}

/// Teklif kartının hap düğmesi.
class _CtaPill extends StatelessWidget {
  const _CtaPill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      child: Material(
        color: background,
        shape: const StadiumBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 46),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward, size: 18, color: foreground),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Abonenin ince satırı: "Premium aktif".
class _ActiveRow extends StatelessWidget {
  const _ActiveRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SettingsCard(
      child: MergeSemantics(
        child: InkWell(
          key: const Key('premium_active_row'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                AppIconTile(
                  icon: Icons.workspace_premium_rounded,
                  gradient: AppGradients.mark(context),
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('premium_active_title'),
                        style: SettingsText.title(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('premium_active_desc'),
                        style: SettingsText.subtitle(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 22, color: t.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
