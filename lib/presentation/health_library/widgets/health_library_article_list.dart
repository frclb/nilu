import '../../../design_system/app_tappable.dart';
import 'package:flutter/material.dart';
import '../../../design_system/app_decor.dart';
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
    final t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          // Yanında "Tümünü Gör" yazıyordu ama dokunulamıyordu; liste
          // zaten tamamı. Yalnızca başlık kaldı.
          child: Row(
            children: [
              Container(
                width: 5,
                height: 18,
                decoration: BoxDecoration(
                  color: t.secondary,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    context.tr('health_library_recommended'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 21,
                      color: theme.colorScheme.primary,
                    ),
                  ),
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
                style: theme.textTheme.bodyMedium?.copyWith(color: t.textMuted),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            // Kart yüksekliği sabit (88 pt görsel), o yüzden iki sütunda
            // satırlar birbirini tutuyor — ızgara için ayrı bir bileşene
            // gerek yok.
            child: AppColumns(
              spacing: 12,
              children: [
                for (final article in articles) _ArticleCard(article: article),
              ],
            ),
          ),
      ],
    );
  }
}

/// Kategoriye göre etiket renkleri: zemin tülü ve okunur metin.
(Color, Color) _tagColors(BuildContext context, ArticleCategory category) {
  final t = context.tokens;
  return switch (category) {
    ArticleCategory.nutrition => (t.accentTint, t.accent),
    ArticleCategory.psychology => (t.ovulationTint, t.ovulationText),
    ArticleCategory.period => (t.secondaryTint, t.flowText),
    ArticleCategory.exercise || ArticleCategory.popular => (
      t.brandTint,
      Theme.of(context).colorScheme.primary,
    ),
  };
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final (tagBg, tagFg) = _tagColors(context, article.category);

    return AppTappable(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ArticleScreen(article: article),
        ),
      ),
      // Kart görünümü paylaşılan bileşenden; koyu temada gölge tamamen
      // kapalıydı ve açık temada kenarlık şeffaftı — kart iki temada iki ayrı
      // şey gibi duruyordu.
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: SizedBox(
                width: 88,
                height: 88,
                child: ContentIllustration(
                  seed: article.titleKey,
                  icon: article.icon,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              // En az 88: büyük yazıda satır uzuyor, taşmıyor.
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Etiket kendi genişliğini alıyor, süre sağa yaslanıyor.
                    // `Spacer` kullanılsaydı ikisi alanı yarı yarıya bölüşür,
                    // etiket sığacağı yerde kesilirdi.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: AppTag(
                            label: context.tr(article.tagKey),
                            background: tagBg,
                            foreground: tagFg,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule, size: 13, color: t.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              context
                                  .tr('health_library_read_time_short')
                                  .replaceAll(
                                    '{min}',
                                    '${article.readMinutes}',
                                  ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11.5,
                                color: t.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Satır sınırı yok: büyük yazıda başlık üç noktayla
                    // kesilince makalenin ne olduğu okunmuyordu.
                    Text(
                      context.tr(article.titleKey),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 15,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
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
