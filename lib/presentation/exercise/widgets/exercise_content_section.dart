import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';

class ExerciseContentSection extends StatelessWidget {
  const ExerciseContentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = context.tokens.background;
    final textColor = context.tokens.text; // slate-900

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle Mock
          Center(
            child: Container(
              width: 48,
              height: 6,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: context.tokens.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Titles
          Text(
            context.upper(context.tr('exercise_tag')),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
              color: isDark
                  ? theme.colorScheme.primary.withAlpha(153)
                  : theme.colorScheme.primary.withAlpha(204),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('exercise_title'),
            style: TextStyle(
              fontSize: 28, // text-3xl approx
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 24),

          // Meta Tags
          Row(
            children: [
              _buildMetaTag(
                context,
                Icons.schedule,
                context.tr('exercise_duration'),
                isDark,
                theme,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetaTag(
                  context,
                  Icons.bar_chart,
                  context.tr('exercise_difficulty'),
                  isDark,
                  theme,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Benefits Section
          Text(
            context.tr('exercise_benefits_title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),

          _buildBenefitItem(
            context,
            Icons.healing,
            context.tr('exercise_benefit_1_title'),
            context.tr('exercise_benefit_1_desc'),
            isDark,
            theme,
          ),
          const SizedBox(height: 12),
          _buildBenefitItem(
            context,
            Icons.spa,
            context.tr('exercise_benefit_2_title'),
            context.tr('exercise_benefit_2_desc'),
            isDark,
            theme,
          ),

          const SizedBox(height: 32),

          // Description Section
          Text(
            context.tr('exercise_desc_title'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('exercise_desc_text'),
            style: TextStyle(
              fontSize: 14,
              color: context.tokens.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaTag(
    BuildContext context,
    IconData icon,
    String label,
    bool isDark,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.primary.withAlpha(51)
            : theme.colorScheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
    bool isDark,
    ThemeData theme,
  ) {
    final iconBg = context.tokens.brandTint;
    final titleColor = context.tokens.text;
    final descColor = context.tokens.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCard.decoration(context.tokens),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(
              child: Icon(icon, color: theme.colorScheme.primary, size: 20),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                Text(desc, style: TextStyle(fontSize: 14, color: descColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
