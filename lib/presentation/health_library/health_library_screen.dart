import 'package:flutter/material.dart';
import '../../design_system/app_colors.dart';
import '../../domain/models/article.dart';
import '../../localization/app_localizations.dart';
import 'widgets/health_library_app_bar.dart';
import 'widgets/health_library_article_list.dart';
import 'widgets/health_library_categories.dart';
import 'widgets/health_library_featured_article.dart';
import 'widgets/health_library_search_bar.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    final results = ArticleCatalog.filter(
      category: _category,
      query: _query,
      translate: context.tr,
    );

    // Öne çıkan makale yalnızca süzgeç uygulanmamışken gösterilir; aksi hâlde
    // sonuç listesinin dışında kalıp kafa karıştırırdı.
    final showFeatured = _query.isEmpty && _category == ArticleCategory.popular;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const HealthLibraryAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HealthLibrarySearchBar(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
            ),
            HealthLibraryCategories(
              selected: _category,
              onSelected: (category) => setState(() => _category = category),
            ),
            if (showFeatured)
              HealthLibraryFeaturedArticle(
                article: ArticleCatalog.all.firstWhere((a) => a.isFeatured),
              ),
            HealthLibraryArticleList(
              articles: showFeatured
                  ? results.where((a) => !a.isFeatured).toList()
                  : results,
              emptyQuery: _query,
            ),
          ],
        ),
      ),
    );
  }
}
