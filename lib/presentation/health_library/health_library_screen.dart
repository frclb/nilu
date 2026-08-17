import 'package:flutter/material.dart';
import 'widgets/health_library_app_bar.dart';
import 'widgets/health_library_search_bar.dart';
import 'widgets/health_library_categories.dart';
import 'widgets/health_library_featured_article.dart';
import 'widgets/health_library_article_list.dart';
import '../../design_system/app_colors.dart';

class HealthLibraryScreen extends StatelessWidget {
  const HealthLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const HealthLibraryAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HealthLibrarySearchBar(),
            const HealthLibraryCategories(),
            const HealthLibraryFeaturedArticle(),
            HealthLibraryArticleList(),
          ],
        ),
      ),
    );
  }
}
