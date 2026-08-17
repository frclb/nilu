import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class PartnerMatchAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PartnerMatchAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.backgroundDark.withValues(alpha: 0.8)
        : AppColors.backgroundLight.withValues(alpha: 0.8);
    final textColor = isDark ? Colors.white : theme.colorScheme.primary;

    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
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
                      ? Colors.white.withAlpha(25)
                      : Colors.black.withAlpha(12),
                ),
              ),
              Text(
                context.tr('partner_match_title'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: textColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      context.pushNamed(RouteNames.partnerImportantDays);
                    },
                    icon: Icon(Icons.notifications_none, color: textColor),
                    style: IconButton.styleFrom(
                      hoverColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      context.pushNamed(RouteNames.partnerShareSettings);
                    },
                    icon: Icon(Icons.settings, color: textColor),
                    style: IconButton.styleFrom(
                      hoverColor: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ],
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
