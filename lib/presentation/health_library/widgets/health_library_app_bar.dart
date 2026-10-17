import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../core/navigation/route_names.dart';

class HealthLibraryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const HealthLibraryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = context.tokens.surface;
    final textColor = context.tokens.text;

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
              const SizedBox(width: 48),
              Expanded(
                // Büyük yazıda başlık kısalıyor; düğmeler yerinde kalıyor.
                child: Text(
                  context.tr('health_library_title'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: textColor,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.tr('nav_profile'),
                onPressed: () {
                  context.goNamed(RouteNames.profile);
                },
                icon: Icon(Icons.account_circle, color: textColor, size: 28),
                style: IconButton.styleFrom(
                  hoverColor: isDark
                      ? theme.colorScheme.primary.withAlpha(51)
                      : context.tokens.background,
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
