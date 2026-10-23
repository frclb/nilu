import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';
import '../../../domain/models/article.dart';

/// Kategori şeridi. Seçim durumu ekranda tutulur; burada tutulduğunda
/// makale listesi seçimden haberdar olmuyordu.
class HealthLibraryCategories extends StatelessWidget {
  final ArticleCategory selected;
  final ValueChanged<ArticleCategory> onSelected;

  const HealthLibraryCategories({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final scheme = theme.colorScheme;

    const categories = ArticleCategory.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      // Alt pay seçili hapın gölgesi kesilmesin diye geniş.
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: Row(
        children: [
          for (final category in categories)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Pill(
                label: context.tr(category.labelKey),
                selected: category == selected,
                onTap: () => onSelected(category),
                selectedGradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    scheme.primary,
                    Color.lerp(scheme.primary, t.secondary, 0.35)!,
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedGradient,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Gradient selectedGradient;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.pill);

    return Semantics(
      button: true,
      selected: selected,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: selected ? selectedGradient : null,
          color: selected ? null : t.surface,
          border: selected ? null : Border.all(color: AppCard.borderColor(t)),
          boxShadow: selected
              ? AppShadows.floating(context)
              : AppShadows.soft(context),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected
                          ? theme.colorScheme.onPrimary
                          : t.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
