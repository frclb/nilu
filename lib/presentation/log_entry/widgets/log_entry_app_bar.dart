import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../core/navigation/navigation_service.dart';

class LogEntryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LogEntryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withAlpha(12)
                : theme.colorScheme.primary.withAlpha(12),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => NavigationService().pop(),
                icon: const Icon(Icons.close),
                color: theme.colorScheme.onSurface,
                style: IconButton.styleFrom(
                  backgroundColor: isDark
                      ? Colors.white.withAlpha(12)
                      : theme.colorScheme.primary.withAlpha(12),
                ),
              ),
              Text(
                context.tr('log_title'),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 48), // To balance the close button
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);
}
