import 'package:flutter/material.dart';
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

    const categories = ArticleCategory.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: categories.map((category) {
          final title = context.tr(category.labelKey);
          final isSelected = category == selected;

          final bgColor = isSelected
              ? theme.colorScheme.primary
              : (context.tokens.surface);

          final textColor = isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : (context.tokens.textMuted);

          final borderColor = isSelected
              ? Colors.transparent
              : (context.tokens.surfaceAlt);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              elevation: isSelected ? 4 : 0,
              shadowColor: isSelected
                  ? theme.colorScheme.primary.withAlpha(76)
                  : Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(category),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
