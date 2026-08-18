import 'package:flutter/material.dart';
import '../../../design_system/content_illustration.dart';
import '../../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';
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
        onTap: () {
          // Makale detay ekranı henüz yok — bkz. health_library_article_list.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('article_coming_soon'))),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? AppColors.surfaceWarmDark : Colors.white,
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
            border: isDark
                ? Border.all(color: Colors.white.withAlpha(12))
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ContentIllustration(seed: article.titleKey, icon: article.icon),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black87,
                        Colors.black54,
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
                      color: isDark
                          ? Colors.black.withAlpha(153)
                          : Colors.white.withAlpha(229),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      context.tr('health_library_editor_choice'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF8A4F5B)
                            : theme.colorScheme.primary,
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
                            color: Colors.white,
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
                          color: Colors.white,
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
                            color: Colors.white.withAlpha(229),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context
                                .tr('health_library_read_time')
                                .replaceAll('{min}', '6'),
                            style: TextStyle(
                              color: Colors.white.withAlpha(229),
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
