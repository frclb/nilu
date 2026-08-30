import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? Colors.white : AppColors.textMainSlate;
    final dividerColor = isDark
        ? Colors.white.withAlpha(25)
        : Colors.grey.shade100;

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
                            color: isDark
                                ? Colors.white
                                : AppColors.textMainSlate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('partner_match_allow_sharing_desc'),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade500,
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
                    activeThumbColor: Colors.white,
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
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('partner_match_hide_symptoms'),
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
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
                    activeThumbColor: Colors.white,
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
            Icon(Icons.lock, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Text(
              context.tr('partner_match_encryption_notice'),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }
}
