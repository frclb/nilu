import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../design_system/app_colors.dart';

class HealthLibraryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const HealthLibraryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.surfaceWarmDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textMainSlate;

    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text(
                context.tr('health_library_title'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: textColor,
                ),
              ),
              IconButton(
                onPressed: () {
                  context.goNamed(RouteNames.profile);
                },
                icon: Icon(Icons.account_circle, color: textColor, size: 28),
                style: IconButton.styleFrom(
                  hoverColor: isDark
                      ? theme.colorScheme.primary.withAlpha(51)
                      : AppColors.backgroundLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
