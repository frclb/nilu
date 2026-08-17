import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../design_system/app_colors.dart';

class InsightsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const InsightsAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Using color palette matching the HTML
    final surfaceColor = isDark ? AppColors.surfaceWarmDark : Colors.white;
    final textColor = isDark
        ? const Color(0xFFF4F1F1)
        : AppColors.textMainLight;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade200;

    return Container(
      color: surfaceColor,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      }
                    },
                    icon: Icon(Icons.arrow_back, color: textColor),
                    style: IconButton.styleFrom(
                      hoverColor: isDark
                          ? Colors.white.withAlpha(12)
                          : Colors.black.withAlpha(12),
                    ),
                  ),
                  Text(
                    context.tr('insights_title'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.pushNamed(RouteNames.calendar);
                    },
                    icon: Icon(Icons.calendar_month, color: textColor),
                    style: IconButton.styleFrom(
                      hoverColor: isDark
                          ? Colors.white.withAlpha(12)
                          : Colors.black.withAlpha(12),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Navigation
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  _buildTab(
                    context,
                    context.tr('insights_tab_general'),
                    true,
                    isDark,
                    theme,
                  ),
                  _buildTab(
                    context,
                    context.tr('insights_tab_activity'),
                    false,
                    isDark,
                    theme,
                  ),
                  _buildTab(
                    context,
                    context.tr('insights_tab_nutrition'),
                    false,
                    isDark,
                    theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String title,
    bool isActive,
    bool isDark,
    ThemeData theme,
  ) {
    final activeColor = isDark ? Colors.white : theme.colorScheme.primary;
    final inactiveColor = isDark
        ? AppColors.textMutedWarmDark
        : AppColors.textMutedLight;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isActive) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr(
                    'insights_tab_coming_soon',
                    params: {'tab': title},
                  ),
                ),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? activeColor : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60);
}
