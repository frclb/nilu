import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../core/navigation/navigation_service.dart';

class LogEntryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LogEntryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: context.tokens.surfaceAlt, width: 1),
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
                  backgroundColor: context.tokens.surfaceAlt,
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
