import 'package:flutter/material.dart';
import '../../design_system/app_decor.dart';
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

/// Bir kütüphane makalesini okur.
///
/// Kütüphane daha önce yalnızca beş başlık listeliyordu; dokununca "yakında"
/// diyordu. Alt menüdeki kök sekmelerden biri tamamen boştu.
///
/// Metnin dayandığı kaynaklar makale sonunda açıkça listeleniyor: sağlık
/// iddialarının nereden geldiği okunabilir olmalı.
///
/// Makale bir kişiye atfedilmiyor: yazar adı, unvan ya da tarih yok —
/// uydurulmuş bir hekim adı sağlık metnine hak etmediği bir güven verirdi.
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
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: t.background,
      body: AppContentWidth(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: t.background,
              surfaceTintColor: Colors.transparent,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 48),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: AppTag(
                          label: context.tr(article.tagKey),
                          icon: Icons.spa,
                          background: scheme.primary,
                          foreground: scheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 16, color: t.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            context.tr(
                              'article_read_minutes',
                              params: {'n': '${article.readMinutes}'},
                            ),
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Semantics(
                    header: true,
                    child: Text(
                      context.tr(article.titleKey),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        height: 1.2,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Kapak: uygulama içinde çizilen illüstrasyon, fotoğraf
                  // değil.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: SizedBox(
                      height: 210,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ContentIllustration(
                            seed: article.titleKey,
                            icon: article.icon,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  scheme.primary.withAlpha(70),
                                  scheme.primary.withAlpha(0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  for (final section in article.sections) ...[
                    if (section.headingKey != null) ...[
                      const SizedBox(height: 14),
                      Semantics(
                        header: true,
                        child: Text(
                          context.tr(section.headingKey!),
                          style: AppTheme.readingHeading(
                            context,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      context.tr(section.bodyKey),
                      style: AppTheme.readingBody(
                        context,
                        color: section.headingKey == null ? t.text : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Makaleyle ilgili tarif — yalnızca konusu örtüşen
                  // makalelerde. Tarif ekranı yazılmıştı ama hiçbir yerden
                  // açılmıyordu.
                  if (article.hasRecipe) ...[
                    const SizedBox(height: 8),
                    _RecipeLink(
                      onTap: () => context.pushNamed(RouteNames.recipeDetail),
                    ),
                  ],

                  const SizedBox(height: 16),
                  _Disclaimer(text: context.tr('article_disclaimer')),

                  const SizedBox(height: 28),
                  AppSectionLabel(context.tr('article_sources')),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final source in article.sources)
                        _SourceChip(
                          label: source.label,
                          onTap: () => _open(source.url),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
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

/// Makale sonundaki tarif bağlantısı.
class _RecipeLink extends StatelessWidget {
  const _RecipeLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.md);

    return Material(
      color: t.brandTint,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AppIconTile(
                icon: Icons.restaurant_menu,
                size: 48,
                circle: true,
                color: scheme.onPrimary,
                background: scheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSectionLabel(
                      context.tr('article_try_recipe'),
                      color: t.secondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('recipe_salmon_title'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: t.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chevron_right, color: scheme.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kaynak bağlantısı: hap biçiminde, dışarı açıldığını söyleyen okla.
class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.pill);

    return Material(
      color: t.surfaceAlt,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.north_east, size: 15, color: t.secondary),
              ],
            ),
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: t.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
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
