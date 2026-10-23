import '../../../design_system/app_tappable.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../article_screen.dart';
import '../../../design_system/content_illustration.dart';
import '../../../../localization/app_localizations.dart';
import '../../../domain/models/article.dart';

/// Öne çıkan makale: koyu erik zeminli editoryal kart.
///
/// Görsel uygulama içinde çizilen illüstrasyon (bkz. `ContentIllustration`);
/// fotoğraf yok. Yazar adı ya da "okumaya başla" düğmesi de yok: makaleler
/// bir kişiye atfedilmiyor ve kartın tamamı dokunulabilir.
class HealthLibraryFeaturedArticle extends StatelessWidget {
  /// Görselin çıkabileceği en fazla yükseklik.
  ///
  /// Kütüphane geniş ekranda 1000 pt'ye açılınca oranla büyüyen görsel
  /// ekranın yarısını yiyor, altındaki makale ızgarası kaydırmadan
  /// görünmüyordu. Sınırın üstünde görsel daralmıyor, yalnızca alçalıyor.
  static const double _maxHeroHeight = 240;

  final Article article;

  const HealthLibraryFeaturedArticle({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (top, bottom, ink) = _plumCard(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: AppTappable(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ArticleScreen(article: article),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, bottom],
            ),
            boxShadow: AppShadows.floating(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                // İllüstrasyonun lekeleri kendi kutusunun dışına da
                // çiziliyor; kırpılmazsa başlığın altına taşıyor.
                builder: (context, constraints) => ClipRect(
                  child: SizedBox(
                    height: math.min(
                      constraints.maxWidth * 0.5,
                      _maxHeroHeight,
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ContentIllustration(
                          seed: article.titleKey,
                          icon: article.icon,
                        ),
                        // Görsel kartın tonuna bürünüp alttan kartın
                        // rengine eriyor; illüstrasyonun kendi rengi ne
                        // olursa olsun kart tek parça görünsün.
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                top,
                                top.withAlpha(170),
                                top.withAlpha(70),
                              ],
                              stops: const [0, 0.45, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          right: 14,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: _Badge(
                                  icon: Icons.stars_rounded,
                                  label: context.tr(
                                    'health_library_editor_choice',
                                  ),
                                  background: top.withAlpha(170),
                                  ink: ink,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _Badge(
                                icon: Icons.schedule,
                                label: context
                                    .tr('health_library_read_time')
                                    // Sabit "6" yazıyordu: hangi makale öne
                                    // çıkarsa çıksın aynı süreyi gösteriyordu.
                                    .replaceAll(
                                      '{min}',
                                      '${article.readMinutes}',
                                    ),
                                background: top.withAlpha(170),
                                ink: ink,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTag(
                      label: context.upper(context.tr(article.tagKey)),
                      background: context.tokens.secondary,
                      foreground: scheme.onSecondary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr(article.titleKey),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 26,
                        height: 1.15,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Koyu erik kartın degradesi ve üstündeki yazı rengi.
///
/// Açık temada birincil renk ve onun koyusu, yazı `onPrimary`. Koyu temada
/// birincil renk açık bir pembe; kartı onunla doldurmak ekranın en parlak
/// yüzeyini yapıyordu. Orada zemin, birincil rengin yüzeye karışmış koyu
/// tonu, yazı gövde metni rengi.
(Color, Color, Color) _plumCard(BuildContext context) {
  final theme = Theme.of(context);
  final primary = theme.colorScheme.primary;
  final t = context.tokens;
  if (theme.brightness == Brightness.dark) {
    return (
      Color.lerp(t.surface, primary, 0.34)!,
      Color.lerp(t.surface, primary, 0.16)!,
      t.text,
    );
  }
  final hsl = HSLColor.fromColor(primary);
  final deep = hsl
      .withLightness((hsl.lightness * 0.62).clamp(0.0, 1.0))
      .toColor();
  return (primary, deep, theme.colorScheme.onPrimary);
}

/// Görsel üstündeki rozet.
class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.label,
    required this.background,
    required this.ink,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ink),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
