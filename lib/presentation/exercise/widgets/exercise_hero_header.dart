import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../localization/app_localizations.dart';

class ExerciseHeroHeader extends StatelessWidget {
  final String imageUrl;

  const ExerciseHeroHeader({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // 4/5 aspect ratio on mobile, similar to HTML
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey,
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
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withAlpha(102),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top Buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (ctx) => _buildCircleButton(
                    icon: Icons.arrow_back,
                    onTap: () {
                      if (ctx.canPop()) ctx.pop();
                    },
                  ),
                ),
                Builder(
                  builder: (ctx) => _buildCircleButton(
                    icon: Icons.bookmark_border,
                    onTap: () {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('saved')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
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
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(76),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(51)),
        ),
        child: Center(child: Icon(icon, color: Colors.white, size: 24)),
      ),
    );
  }
}
