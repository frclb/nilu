import 'package:flutter/material.dart';
import '../../design_system/app_theme.dart';
import '../widgets/ad_banner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design_system/app_tokens.dart';
import '../../design_system/content_illustration.dart';
import '../../domain/models/article.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';

/// Bir kütüphane makalesini okur.
///
/// Kütüphane daha önce yalnızca beş başlık listeliyordu; dokununca "yakında"
/// diyordu. Alt menüdeki kök sekmelerden biri tamamen boştu.
///
/// Metnin dayandığı kaynaklar makale sonunda açıkça listeleniyor: sağlık
/// iddialarının nereden geldiği okunabilir olmalı.
class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key, required this.article});

  final Article article;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: t.background,
      body: AppContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: t.background,
              flexibleSpace: FlexibleSpaceBar(
                background: ContentIllustration(
                  seed: article.titleKey,
                  icon: article.icon,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    context.tr(article.titleKey),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr(
                      'article_read_minutes',
                      params: {'n': '${article.readMinutes}'},
                    ),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 24),

                  for (final section in article.sections) ...[
                    if (section.headingKey != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.tr(section.headingKey!),
                        style: AppTheme.readingHeading(context),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      context.tr(section.bodyKey),
                      style: AppTheme.readingBody(context),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Makaleyle ilgili tarif — yalnızca konusu örtüşen
                  // makalelerde. Tarif ekranı yazılmıştı ama hiçbir yerden
                  // açılmıyordu.
                  if (article.hasRecipe) ...[
                    const SizedBox(height: 8),
                    AppCard(
                      padding: const EdgeInsets.all(14),
                      child: InkWell(
                        onTap: () => context.pushNamed(RouteNames.recipeDetail),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: t.brandTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                size: 22,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.tr('article_try_recipe'),
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                      color: t.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.tr('recipe_salmon_title'),
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: t.textFaint),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  _Disclaimer(text: context.tr('article_disclaimer')),

                  const SizedBox(height: 28),
                  Text(
                    context.tr('article_sources'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final source in article.sources)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _open(source.url),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.open_in_new,
                              size: 15,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                source.label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  const AdBanner(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tıbbi tavsiye olmadığını belirten not.
class _Disclaimer extends StatelessWidget {
  const _Disclaimer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: t.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 12.5,
                height: 1.55,
                color: t.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
