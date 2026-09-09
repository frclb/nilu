import 'dart:ui';
import '../../../design_system/app_scrim.dart';
import '../../../design_system/app_tokens.dart';
import 'package:flutter/material.dart';
import '../../../design_system/content_illustration.dart';
import '../../../localization/app_localizations.dart';

class RecipeHeroHeader extends StatelessWidget {
  /// Gerçek fotoğraf tedarik edilince buraya bir adres verilir; adres ölürse
  /// ya da cihaz çevrimdışıysa uygulama içinde çizilen illüstrasyona düşer.
  /// Daha önce burada Google'ın geçici mockup adresi sabit olarak duruyordu.
  final String? imageUrl;

  const RecipeHeroHeader({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final gradientEnd = context.tokens.background;

    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          SafeNetworkImage(
            url: imageUrl,
            fallback: const ContentIllustration(
              seed: 'recipe_hero',
              icon: Icons.restaurant_menu,
            ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppScrim.veil(76), Colors.transparent, gradientEnd],
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
              color: AppScrim.veil(51),
              shape: BoxShape.circle,
            ),
            child: Center(child: Icon(icon, color: AppScrim.ink, size: 24)),
          ),
        ),
      ),
    );
  }
}
