import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import '../widgets/favorite_button.dart';
import 'widgets/recipe_hero_header.dart';
import 'widgets/recipe_content_section.dart';
import '../../design_system/app_layout.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bgColor = context.tokens.background;
    final bottomBarBg = bgColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: AppContentWidth(
        // `Scaffold` gövdeye **gevşek** kısıt veriyor; `Stack` de en uzun
        // konumlandırılmamış çocuğuna göre büzülüyor. İçerik ekrandan
        // kısaysa `Positioned(bottom: 0)` ekranın dibine değil içeriğin
        // dibine yapışıyor ve eylem çubuğu ortada havada kalıyordu.
        // Telefonda içerik ekranı doldurduğu için görünmüyordu.
        child: SizedBox.expand(
          child: Stack(
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
                      colors: [
                        bottomBarBg,
                        bottomBarBg,
                        bottomBarBg.withAlpha(0),
                      ],
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
        ),
      ),
    );
  }
}
