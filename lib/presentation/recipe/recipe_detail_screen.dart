import 'package:flutter/material.dart';
import 'widgets/recipe_hero_header.dart';
import 'widgets/recipe_content_section.dart';
import '../../localization/app_localizations.dart';
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
    final primaryColor = isDark
        ? const Color(0xFF551C25)
        : AppColors.primaryLight;
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
                const RecipeHeroHeader(
                  imageUrl:
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAEuevEoUgOhPQdWgv1noD1YT026Uaiip4IgLvqqydRb15J_hhO-Ec_eYZoqRUMBpJlEWlUOqvIIUQEmsOK0_cVCRjnHgwMBGZZ5mNzMLmzGIRpQx_f3Gj3Bty8mZLdBVCVLdmyA6awwIyQ4IK9XBlk6s2WTqZ7nib_TKZeH4Ee2JknbkFkZ4nhC66KknFZA3nyO_jOXtpuzGqvn4sTBKR_zhLphX5F4l3ybkArZtDYr1pBlIi4MWQk56DiFCBYPa8hBEz3ggYemD4',
                ),
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
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('recipe_favorited'))),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: primaryColor.withAlpha(127),
                  ),
                  icon: const Icon(Icons.favorite, size: 22),
                  label: Text(
                    context.tr('recipe_favorite'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
