import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../design_system/app_scrim.dart';
import '../../../design_system/content_illustration.dart';
import '../../widgets/favorite_button.dart';
import 'package:go_router/go_router.dart';

class ExerciseHeroHeader extends StatelessWidget {
  /// Kahraman görselin çıkabileceği en fazla yükseklik.
  ///
  /// Oran 4:5'ti ve yorumu da "mobile" diyordu: telefonda (~390 pt) 487 pt
  /// ediyor. Geniş ekranda içerik 600 pt'ye açılınca aynı oran 750 pt'ye
  /// çıkıp egzersizin adını bile ekranın dışına itiyordu.
  static const double _maxHeroHeight = 480;

  /// Gerçek fotoğraf tedarik edilince buraya bir adres verilir; adres ölürse
  /// ya da cihaz çevrimdışıysa uygulama içinde çizilen illüstrasyona düşer.
  /// Daha önce burada Google'ın geçici mockup adresi sabit olarak duruyordu.
  final String? imageUrl;

  const ExerciseHeroHeader({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        height: math.min(constraints.maxWidth * 5 / 4, _maxHeroHeight),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            SafeNetworkImage(
              url: imageUrl,
              fallback: const ContentIllustration(
                seed: 'exercise_hero',
                icon: Icons.fitness_center,
              ),
            ),

            // Gradient Overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppScrim.veil(102),
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
                  // Kaydetme artık kalıcı (bkz. FavoriteButton).
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppScrim.veil(76),
                      shape: BoxShape.circle,
                    ),
                    child: const FavoriteButton(
                      contentId: 'exercise_light_flow',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          color: AppScrim.frost(76),
          shape: BoxShape.circle,
          border: Border.all(color: AppScrim.frost(51)),
        ),
        child: Center(child: Icon(icon, color: AppScrim.ink, size: 24)),
      ),
    );
  }
}
