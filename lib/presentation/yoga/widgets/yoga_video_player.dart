import 'package:flutter/material.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/content_illustration.dart';
import '../../../localization/app_localizations.dart';

/// Yoga akışının kapağı: illüstrasyon, altında zemine eriyen geçiş ve
/// evre etiketleri.
///
/// Dosyanın adı eskiden kalma. Burada bir video oynatıcı görüntüsü vardı —
/// ortada hiçbir yere bağlı olmayan bir oynat düğmesi. Uygulamada video yok;
/// oynatıcı görüntüsü olmayan bir içerik vaat ediyordu. Kapak bir görsel,
/// rehberli seans aşağıdaki "Başlat" düğmesinden açılıyor.
class YogaCover extends StatelessWidget {
  /// Gerçek fotoğraf tedarik edilince buraya bir adres verilir; adres ölürse
  /// ya da cihaz çevrimdışıysa uygulama içinde çizilen illüstrasyona düşer.
  /// Daha önce burada Google'ın geçici mockup adresi sabit olarak duruyordu.
  final String? imageUrl;

  const YogaCover({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 230,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.xl),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SafeNetworkImage(
                  url: imageUrl,
                  fallback: const ContentIllustration(
                    seed: 'yoga_hero',
                    icon: Icons.self_improvement,
                  ),
                ),
                // Alttan zemine eriyen geçiş: etiketler okunur kalsın.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        t.background,
                        t.background.withAlpha(110),
                        t.background.withAlpha(0),
                      ],
                      stops: const [0, 0.35, 0.75],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppTag(
                  label: context.tr('yoga_tag_period'),
                  dotColor: t.flowSoft,
                  background: scheme.primary,
                  foreground: scheme.onPrimary,
                ),
                AppTag(
                  label: context.tr('yoga_tag_relaxing'),
                  icon: Icons.spa_outlined,
                  background: t.surface,
                  foreground: t.textMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
