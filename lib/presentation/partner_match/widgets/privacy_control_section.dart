import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';

class PrivacyControlSection extends StatefulWidget {
  const PrivacyControlSection({super.key});

  @override
  State<PrivacyControlSection> createState() => _PrivacyControlSectionState();
}

class _PrivacyControlSectionState extends State<PrivacyControlSection> {
  bool _masterToggle = true;
  bool _detailToggle = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final headerColor = context.tokens.text;
    final dividerColor = context.tokens.surfaceAlt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('partner_match_privacy'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: headerColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppCard.decoration(context.tokens),
          child: Column(
            children: [
              // Master Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('partner_match_allow_sharing'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.tokens.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('partner_match_allow_sharing_desc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: _masterToggle,
                    onChanged: (val) {
                      setState(() {
                        _masterToggle = val;
                      });
                    },
                    activeThumbColor: context.tokens.surface,
                    activeTrackColor: theme.colorScheme.primary,
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: dividerColor, height: 1),
              ),

              // Granular Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_off,
                        size: 18,
                        color: context.tokens.textFaint,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('partner_match_hide_symptoms'),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.tokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: _detailToggle,
                    onChanged: (val) {
                      setState(() {
                        _detailToggle = val;
                      });
                    },
                    activeThumbColor: context.tokens.surface,
                    activeTrackColor: theme.colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Security Note
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 14, color: context.tokens.textFaint),
            const SizedBox(width: 4),
            Text(
              context.tr('partner_match_encryption_notice'),
              style: TextStyle(fontSize: 12, color: context.tokens.textFaint),
            ),
          ],
        ),
      ],
    );
  }
}
