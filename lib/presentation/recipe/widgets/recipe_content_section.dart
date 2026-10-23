import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';

/// Tarifin gövdesi: süre ve zorluk, faydalar, malzemeler, adımlar.
///
/// Kalori yok: tek bir sayı porsiyona, malzemenin markasına ve miktarına
/// göre değişir; uygulama bunların hiçbirini bilmiyor. Puan da yok —
/// uygulamada değerlendirme diye bir şey yok.
class RecipeContentSection extends StatelessWidget {
  const RecipeContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Süre ve zorluk ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: t.brandTint.withAlpha(170),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _Meta(
                      icon: Icons.schedule,
                      value: context.tr(
                        'duration_minutes',
                        params: {'n': '15'},
                      ),
                      label: context.tr('yoga_stat_duration'),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppCard.dividerColor(t),
                  ),
                  Expanded(
                    child: _Meta(
                      icon: Icons.eco_outlined,
                      value: context.tr('recipe_difficulty_easy'),
                      label: context.tr('yoga_stat_level'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Faydalar ──
          Row(
            children: [
              Icon(Icons.stars_rounded, size: 20, color: t.secondary),
              const SizedBox(width: 8),
              Expanded(child: AppSectionLabel(context.tr('recipe_benefits'))),
            ],
          ),
          const SizedBox(height: 12),
          _Benefit(
            icon: Icons.monitor_heart_outlined,
            iconColor: primary,
            iconBackground: t.surface,
            background: t.brandTint,
            title: context.tr('recipe_magnesium'),
            subtitle: context.tr('recipe_magnesium_desc'),
          ),
          const SizedBox(height: 10),
          _Benefit(
            icon: Icons.water_drop_outlined,
            iconColor: t.secondary,
            iconBackground: t.secondaryTint,
            background: t.surfaceAlt,
            title: context.tr('recipe_omega3'),
            subtitle: context.tr('recipe_omega3_desc'),
          ),
          const SizedBox(height: 28),

          // ── Malzemeler ──
          _SectionTitle(
            icon: Icons.shopping_bag_outlined,
            title: context.tr('recipe_ingredients'),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(children: _ingredients(context)),
          ),
          const SizedBox(height: 28),

          // ── Adımlar ──
          _SectionTitle(
            icon: Icons.restaurant_outlined,
            title: context.tr('recipe_steps'),
          ),
          const SizedBox(height: 12),
          for (var i = 1; i <= 3; i++) ...[
            if (i > 1) const SizedBox(height: 10),
            _Step(index: i, text: context.tr('recipe_step_$i')),
          ],
        ],
      ),
    );
  }

  List<Widget> _ingredients(BuildContext context) {
    final items = [
      (context.tr('recipe_ing_salmon'), '150g'),
      (context.tr('recipe_ing_quinoa'), context.tr('recipe_ing_quinoa_amount')),
      (
        context.tr('recipe_ing_avocado'),
        context.tr('recipe_ing_avocado_amount'),
      ),
      (
        context.tr('recipe_ing_spinach'),
        context.tr('recipe_ing_spinach_amount'),
      ),
      (
        context.tr('recipe_ing_dressing'),
        context.tr('recipe_ing_dressing_amount'),
      ),
    ];

    final t = context.tokens;
    final theme = Theme.of(context);
    return [
      for (final (name, amount) in items)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: t.brandTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 15,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              // Büyük yazıda ad sarıyor, miktar sağda kalıyor.
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.text,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amount,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13.5,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
        ),
    ];
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 22, color: t.secondary),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: t.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: t.textMuted,
          ),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.background,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color background;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          AppIconTile(
            icon: icon,
            size: 46,
            circle: true,
            color: iconColor,
            background: iconBackground,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13.5,
                    color: t.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: context.tokens.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: t.brandTint.withAlpha(170),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.55,
                  color: t.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
