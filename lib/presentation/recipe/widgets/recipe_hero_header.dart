import '../../../design_system/app_decor.dart';
import '../../../design_system/app_scrim.dart';
import '../../../design_system/app_tokens.dart';
import 'package:flutter/material.dart';
import '../../../design_system/content_illustration.dart';
import '../../../localization/app_localizations.dart';

/// Tarifin kapağı: köşeleri yuvarlak görsel, üstünde evre etiketleri,
/// altında başlık.
class RecipeHeroHeader extends StatelessWidget {
  /// Gerçek fotoğraf tedarik edilince buraya bir adres verilir; adres ölürse
  /// ya da cihaz çevrimdışıysa uygulama içinde çizilen illüstrasyona düşer.
  /// Daha önce burada Google'ın geçici mockup adresi sabit olarak duruyordu.
  final String? imageUrl;

  const RecipeHeroHeader({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.floating(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeNetworkImage(
              url: imageUrl,
              fallback: const ContentIllustration(
                seed: 'recipe_hero',
                icon: Icons.restaurant_menu,
              ),
            ),
            // Başlığın okunması için alttan karartma. Görselin üstündeki
            // katman temayla değişmiyor (bkz. `AppScrim`).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppScrim.veil(170),
                    AppScrim.veil(40),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppTag(
                    label: context.tr('recipe_phase_follicular'),
                    dotColor: t.phaseFollicular,
                    background: AppScrim.veil(110),
                    foreground: AppScrim.ink,
                  ),
                  AppTag(
                    label: context.tr('recipe_tag_energizing'),
                    background: AppScrim.veil(110),
                    foreground: AppScrim.ink,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Semantics(
                header: true,
                child: Text(
                  context.tr('recipe_salmon_title'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 30,
                    height: 1.15,
                    color: AppScrim.ink,
                    shadows: AppScrim.lift(alpha: 60, blurRadius: 8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
