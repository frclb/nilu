import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/app_card.dart';
import '../../../../localization/app_localizations.dart';

class NotesSection extends StatelessWidget {
  final TextEditingController controller;

  const NotesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('log_notes'),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: context.tokens.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.tokens.border),
              boxShadow: AppCard.shadow(),
            ),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: context.tr('log_notes_hint'),
                hintStyle: TextStyle(
                  color: theme.textTheme.labelLarge?.color?.withAlpha(204),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
