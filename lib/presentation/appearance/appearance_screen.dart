import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/navigation/route_names.dart';
import '../../design_system/app_flavor.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/view_models/theme_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';

/// Tema çeşidi seçimi.
///
/// Paywall "Özel Temalar" vaat ediyordu ama böyle bir ekran hiç yoktu.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final viewModel = context.watch<ThemeViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('appearance_title'))),
      body: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              context.tr('appearance_desc'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: t.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),
            for (final flavor in AppFlavor.values) ...[
              _FlavorTile(
                flavor: flavor,
                selected: viewModel.flavor == flavor,
                locked: !viewModel.canUse(flavor),
                onTap: () async {
                  final ok = await viewModel.select(flavor);
                  if (!ok && context.mounted) {
                    // Kilitli temaya dokunmak paywall'a götürür; sessizce
                    // hiçbir şey yapmamak kullanıcıyı şaşırtırdı.
                    context.pushNamed(RouteNames.premium);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlavorTile extends StatelessWidget {
  final AppFlavor flavor;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  const _FlavorTile({
    required this.flavor,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brand = isDark ? flavor.brandDark : flavor.brand;

    return Material(
      color: t.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected ? brand : t.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Önizleme: marka rengi, açık tonu ve sabit kalan akış rengi.
              // Kullanıcı temanın takvimi nasıl etkilemediğini görsün.
              _Swatch(colors: [brand, flavor.tint, t.flow]),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  context.tr(flavor.labelKey),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (locked)
                Icon(Icons.lock_outline, size: 20, color: t.textFaint)
              else if (selected)
                Icon(Icons.check_circle, size: 22, color: brand),
            ],
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final List<Color> colors;

  const _Swatch({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 32,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors[i],
                  shape: BoxShape.circle,
                  border: Border.all(color: context.tokens.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
