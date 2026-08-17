import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class SharedInfoSection extends StatelessWidget {
  const SharedInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = isDark ? Colors.white : AppColors.textMainSlate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('partner_match_shared_info'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: headerColor,
              ),
            ),
            Icon(Icons.info, color: Colors.grey.shade400, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoItem(
          context,
          Icons.water_drop,
          context.tr('partner_match_phase'),
          context.tr('partner_match_phase_desc'),
          isDark,
          theme,
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          Icons.lightbulb,
          context.tr('partner_match_tips'),
          context.tr('partner_match_tips_desc'),
          isDark,
          theme,
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          Icons.sentiment_satisfied_alt,
          context.tr('partner_match_mood'),
          context.tr('partner_match_mood_desc'),
          isDark,
          theme,
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
    bool isDark,
    ThemeData theme,
  ) {
    final itemBgNode = isDark ? Colors.white.withAlpha(12) : Colors.white;
    final itemBorder = isDark
        ? Colors.white.withAlpha(25)
        : Colors.grey.shade100;
    final iconBg = theme.colorScheme.primary.withAlpha(25);
    final titleColor = isDark ? Colors.white : AppColors.textMainSlate;
    final descColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: itemBgNode,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: itemBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white : theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 12, color: descColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
