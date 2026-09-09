import 'package:flutter/material.dart';
import '../../../design_system/app_scrim.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../article_screen.dart';
import '../../../design_system/content_illustration.dart';
import '../../../../localization/app_localizations.dart';
import '../../../domain/models/article.dart';

class HealthLibraryFeaturedArticle extends StatelessWidget {
  final Article article;

  const HealthLibraryFeaturedArticle({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 8),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ArticleScreen(article: article),
          ),
        ),
        // Koyu temada gölge kapalı, açık temada kenarlık yoktu — kart iki
        // temada iki ayrı şey gibi duruyordu. Artık ikisi de paylaşılan
        // bileşenden.
        child: Container(
          decoration: AppCard.decoration(context.tokens),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ContentIllustration(seed: article.titleKey, icon: article.icon),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        AppScrim.veil(222),
                        AppScrim.veil(138),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.4, 1.0],
                    ),
                  ),
                ),

                // Editor's Choice Badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppScrim.veil(153) : AppScrim.frost(229),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      context.tr('health_library_editor_choice'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                // Article Info
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(204),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.tr(article.tagKey),
                          style: TextStyle(
                            color: AppScrim.ink,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(article.titleKey),
                        style: TextStyle(
                          color: AppScrim.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            color: AppScrim.frost(229),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context
                                .tr('health_library_read_time')
                                // Sabit "6" yazıyordu: hangi makale öne
                                // çıkarsa çıksın aynı süreyi gösteriyordu.
                                .replaceAll('{min}', '${article.readMinutes}'),
                            style: TextStyle(
                              color: AppScrim.frost(229),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
