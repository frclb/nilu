import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/app_card.dart';
import '../article_screen.dart';
import '../../../design_system/content_illustration.dart';
import '../../../../localization/app_localizations.dart';
import '../../../domain/models/article.dart';
import '../../../design_system/app_layout.dart';

class HealthLibraryArticleList extends StatelessWidget {
  final List<Article> articles;

  /// Boş sonuç mesajında gösterilecek arama metni.
  final String emptyQuery;

  const HealthLibraryArticleList({
    super.key,
    required this.articles,
    this.emptyQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                context.tr('health_library_recommended'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.tokens.text,
                ),
              ),
              Text(
                context.tr('health_library_see_all'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        if (articles.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Center(
              child: Text(
                emptyQuery.isEmpty
                    ? context.tr('library_empty')
                    : context.tr(
                        'library_no_results',
                        params: {'query': emptyQuery},
                      ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            // Kart yüksekliği sabit (96 pt görsel), o yüzden iki sütunda
            // satırlar birbirini tutuyor — ızgara için ayrı bir bileşene
            // gerek yok.
            child: AppColumns(
              children: [
                for (final article in articles)
                  _buildArticleCard(context, article, theme, isDark),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildArticleCard(
    BuildContext context,
    Article article,
    ThemeData theme,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArticleScreen(article: article),
        ),
      ),
      // Kart görünümü paylaşılan bileşenden; koyu temada gölge tamamen
      // kapalıydı ve açık temada kenarlık şeffaftı — kart iki temada iki ayrı
      // şey gibi duruyordu.
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 96,
                height: 96,
                child: ContentIllustration(
                  seed: article.titleKey,
                  icon: article.icon,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: SizedBox(
                height: 96,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(article.tagKey),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr(article.titleKey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.tokens.text,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: context.tokens.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context
                                  .tr('health_library_read_time_short')
                                  .replaceAll(
                                    '{min}',
                                    '${article.readMinutes}',
                                  ),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.tokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.bookmark_border,
                          size: 20,
                          color: context.tokens.textFaint,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
