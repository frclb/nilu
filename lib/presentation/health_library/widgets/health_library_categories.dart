import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class HealthLibraryCategories extends StatefulWidget {
  const HealthLibraryCategories({super.key});

  @override
  State<HealthLibraryCategories> createState() =>
      _HealthLibraryCategoriesState();
}

class _HealthLibraryCategoriesState extends State<HealthLibraryCategories> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categories = [
      context.tr('health_library_cat_popular'),
      context.tr('health_library_cat_period'),
      context.tr('health_library_cat_nutrition'),
      context.tr('health_library_cat_psychology'),
      context.tr('health_library_cat_exercise'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = index == _selectedIndex;

          final bgColor = isSelected
              ? theme.colorScheme.primary
              : (isDark ? AppColors.surfaceWarmDark : Colors.white);

          final textColor = isSelected
              ? Colors.white
              : (isDark ? Colors.grey.shade300 : Colors.grey.shade600);

          final borderColor = isSelected
              ? Colors.transparent
              : (isDark ? Colors.white.withAlpha(25) : Colors.grey.shade100);

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
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
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
