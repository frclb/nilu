import 'package:flutter/material.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';
import 'log_section_header.dart';

class NotesSection extends StatelessWidget {
  final TextEditingController controller;

  const NotesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LogSectionHeader(
            icon: Icons.edit_note,
            title: context.tr('log_notes'),
          ),
          Container(
            height: 128,
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.soft(context),
            ),
            padding: const EdgeInsets.all(18),
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: context.tr('log_notes_hint'),
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: t.textFaint,
                  fontSize: 15,
                ),
                // Kartın kendisi alan; temanın dolgu ve çerçevesi yok.
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
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
