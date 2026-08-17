import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';

class LogEntryHeader extends StatelessWidget {
  const LogEntryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('log_date_example'),
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('log_subtitle'),
            style: theme.textTheme.labelLarge?.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
