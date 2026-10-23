import 'package:flutter/material.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../widgets/ad_banner.dart';
import '../../domain/models/article.dart';
import '../../localization/app_localizations.dart';
import 'widgets/health_library_app_bar.dart';
import 'widgets/health_library_article_list.dart';
import 'widgets/health_library_categories.dart';
import 'widgets/health_library_featured_article.dart';
import 'widgets/health_library_search_bar.dart';
import '../../design_system/app_layout.dart';

/// Sağlık kütüphanesi.
///
/// Arama ve kategori durumu burada tutulur: arama çubuğu ve kategori şeridi
/// eskiden birbirinden ve listeden habersizdi — arama alanının hiç
/// `controller`'ı yoktu, kategoriler yalnızca kendi görünümünü değiştiriyordu.
class HealthLibraryScreen extends StatefulWidget {
  const HealthLibraryScreen({super.key});

  @override
  State<HealthLibraryScreen> createState() => _HealthLibraryScreenState();
}

class _HealthLibraryScreenState extends State<HealthLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  ArticleCategory _category = ArticleCategory.popular;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final results = ArticleCatalog.filter(
      category: _category,
      query: _query,
      translate: context.tr,
    );

    // Öne çıkan makale yalnızca süzgeç uygulanmamışken gösterilir; aksi hâlde
    // sonuç listesinin dışında kalıp kafa karıştırırdı.
    // Hiçbir makale öne çıkarılmamışsa bölüm tamamen atlanıyor. Eskiden
    // `firstWhere` ile aranıyordu ve o durumda ekran `StateError` ile
    // kırmızıya dönüyordu.
    final featured = ArticleCatalog.featured;
    final showFeatured =
        featured != null &&
        _query.isEmpty &&
        _category == ArticleCategory.popular;

    return Scaffold(
      backgroundColor: context.tokens.background,
      body: AmbientBackground(
        child: Column(
          children: [
            const HealthLibraryAppBar(),
            Expanded(
              child: AppContentWidth(
                // Makale listesi geniş ekranda iki sütuna açılıyor; tek
                // sütunun okunur genişliğine sıkıştırılırsa kartlar 280
                // pt'ye düşer.
                maxWidth: AppLayout.wideContentMaxWidth,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Semantics(
                          header: true,
                          child: Text(
                            context.tr('health_library_title'),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 28,
                              height: 1.15,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      HealthLibrarySearchBar(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                      ),
                      HealthLibraryCategories(
                        selected: _category,
                        onSelected: (category) =>
                            setState(() => _category = category),
                      ),
                      if (showFeatured)
                        HealthLibraryFeaturedArticle(article: featured),
                      HealthLibraryArticleList(
                        articles: showFeatured
                            ? results.where((a) => !a.isFeatured).toList()
                            : results,
                        emptyQuery: _query,
                      ),

                      // Reklam yalnızca burada ve içerik ekranlarında.
                      // Takvim, kayıt ve analiz ekranlarında yok:
                      // kullanıcının semptom girdiği yerde reklam göstermek
                      // hem rahatsız edici hem bağlam olarak yanlış.
                      const AdBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
