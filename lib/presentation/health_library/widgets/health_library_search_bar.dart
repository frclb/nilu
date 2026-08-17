import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class HealthLibrarySearchBar extends StatelessWidget {
  const HealthLibrarySearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.surfaceWarmDark : Colors.white;
    final inputBgColor = isDark
        ? Colors.black.withAlpha(51)
        : AppColors.backgroundLight;
    final hintColor = isDark ? Colors.grey.shade400 : Colors.grey.shade400;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: inputBgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TextField(
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: context.tr('health_library_search'),
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: isDark
                  ? theme.colorScheme.primary.withAlpha(204)
                  : theme.colorScheme.primary.withAlpha(153),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
