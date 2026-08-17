import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class NotesSection extends StatelessWidget {
  final TextEditingController controller;

  const NotesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note,
                color: isDark ? Colors.white : theme.colorScheme.primary,
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
              color: isDark ? const Color(0xFF2A2224) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? AppColors.borderSlateDark
                    : AppColors.borderSlate,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
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
