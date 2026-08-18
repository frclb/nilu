import 'package:flutter/material.dart';
import '../widgets/favorite_button.dart';
import 'widgets/recipe_hero_header.dart';
import 'widgets/recipe_content_section.dart';
import '../../design_system/app_colors.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.backgroundDeepDark
        : AppColors.backgroundLight;
    final bottomBarBg = bgColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Scrollable Content ──
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const RecipeHeroHeader(),
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: const RecipeContentSection(),
                ),
              ],
            ),
          ),

          // ── Sticky Bottom Bar ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [bottomBarBg, bottomBarBg, bottomBarBg.withAlpha(0)],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
              child: const SizedBox(
                height: 56,
                child: FavoriteButton(
                  contentId: 'recipe_salmon_quinoa',
                  expanded: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
