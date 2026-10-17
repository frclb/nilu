import 'package:flutter/material.dart';
import '../../../design_system/app_scrim.dart';
import '../../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../../localization/app_localizations.dart';

class PartnerMatchAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PartnerMatchAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? context.tokens.background.withValues(alpha: 0.8)
        : context.tokens.background.withValues(alpha: 0.8);
    final textColor = Theme.of(context).colorScheme.primary;

    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          // Dikey pay 4: 56 pt'lik çubukta düğmeye 48 pt kalsın (8 iken
          // 40'a sıkışıyordu, iOS'un önerdiği 44'ün altında).
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  }
                },
                icon: Icon(Icons.arrow_back, color: textColor),
                style: IconButton.styleFrom(
                  hoverColor: isDark ? AppScrim.frost(25) : AppScrim.veil(12),
                ),
              ),
              Expanded(
                // Büyük yazıda başlık kısalıyor; düğmeler yerinde kalıyor.
                child: Text(
                  context.tr('partner_match_title'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: textColor,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: context.tr('profile_partner_settings'),
                    onPressed: () {
                      context.pushNamed(RouteNames.partnerShareSettings);
                    },
                    icon: Icon(Icons.settings, color: textColor),
                    style: IconButton.styleFrom(
                      hoverColor: isDark
                          ? AppScrim.frost(26)
                          : AppScrim.veil(13),
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
