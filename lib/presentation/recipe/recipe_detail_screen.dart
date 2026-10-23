import 'package:flutter/material.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../widgets/favorite_button.dart';
import 'widgets/recipe_hero_header.dart';
import 'widgets/recipe_content_section.dart';
import '../../design_system/app_layout.dart';

class RecipeDetailScreen extends StatelessWidget {
  const RecipeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.background,
      // Kapağın üstündeki yüzen geri düğmesi yerine sade bir çubuk: geri
      // oku temanın rengini alıyor, kapak illüstrasyonu kapatılmıyor.
      // Yanında bir "⋮" menüsü vardı: "Paylaş" ve "Kaydet" yalnızca menüyü
      // kapatıyordu. Kaydetme alttaki gerçek favori düğmesinde.
      appBar: AppBar(backgroundColor: t.background),
      // Eylem çubuğu `Scaffold`'un altında: gövdedeki bir `Stack`e
      // `Positioned(bottom: 0)` ile konduğunda içerik ekrandan kısayken
      // ekranın değil içeriğin dibine yapışıyordu.
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: t.background,
          boxShadow: AppShadows.soft(context),
        ),
        child: const AppContentWidth(
          child: FavoriteButton(
            contentId: 'recipe_salmon_quinoa',
            expanded: true,
          ),
        ),
      ),
      body: AppContentWidth(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: const [RecipeHeroHeader(), RecipeContentSection()],
        ),
      ),
    );
  }
}
