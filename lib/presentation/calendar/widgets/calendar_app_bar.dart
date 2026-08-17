import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../core/navigation/route_names.dart';

class CalendarAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CalendarAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? AppColors.backgroundDark : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Row(
                children: [
                  Icon(Icons.calendar_month, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('calendar_title'),
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  context.pushNamed(RouteNames.cycleSettings);
                },
                icon: Icon(Icons.settings_outlined, color: onSurface),
                style: IconButton.styleFrom(
                  hoverColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}
