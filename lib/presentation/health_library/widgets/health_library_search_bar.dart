import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';

class HealthLibrarySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const HealthLibrarySearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: AppCard.borderColor(t)),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.soft(context),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.text,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: context.tr('health_library_search'),
            hintStyle: theme.textTheme.bodyMedium?.copyWith(color: t.textFaint),
            filled: true,
            fillColor: t.surface,
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    icon: Icon(Icons.close, size: 18, color: t.textMuted),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(color: t.secondary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
