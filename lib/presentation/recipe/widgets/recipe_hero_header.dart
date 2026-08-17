import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class RecipeHeroHeader extends StatelessWidget {
  final String imageUrl;

  const RecipeHeroHeader({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientEnd = isDark
        ? AppColors.backgroundDeepDark
        : AppColors.backgroundLight;

    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: isDark ? const Color(0xFF2A151F) : Colors.grey.shade200,
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 48,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              );
            },
          ),

          // Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(76),
                    Colors.transparent,
                    gradientEnd,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),

          // Top Buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(),
                ),
                _buildCircleButton(
                  icon: Icons.more_vert,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.share),
                              title: Text(context.tr('share')),
                              onTap: () => Navigator.pop(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.bookmark_border),
                              title: Text(context.tr('save')),
                              onTap: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, color: Colors.white, size: 24)),
          ),
        ),
      ),
    );
  }
}
