import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../core/navigation/route_names.dart';
import '../../../design_system/app_colors.dart';

class SymptomAnalysisCard extends StatelessWidget {
  const SymptomAnalysisCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? AppColors.surfaceWarmDark : Colors.white;
    final borderColor = isDark
        ? AppColors.surfaceDark
        : AppColors.borderGrayLight;
    final textColor = isDark
        ? const Color(0xFFF4F1F1)
        : AppColors.textMainLight;
    final subtitleColor = isDark
        ? AppColors.textMutedWarmDark
        : AppColors.textMutedLight;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('insights_symptoms_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('insights_symptoms_subtitle'),
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  context.pushNamed(RouteNames.calendar);
                },
                child: Row(
                  children: [
                    Text(
                      context.tr('insights_symptoms_details'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white
                            : theme.colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: isDark ? Colors.white : theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bars
          _buildBar(
            context,
            context.tr('log_symptom_cramp'),
            85,
            theme.colorScheme.primary,
            textColor,
            subtitleColor,
            isDark,
          ),
          const SizedBox(height: 20),
          _buildBar(
            context,
            context.tr('log_symptom_headache'),
            62,
            theme.colorScheme.primary.withAlpha(153),
            textColor,
            subtitleColor,
            isDark,
          ),
          const SizedBox(height: 20),
          _buildBar(
            context,
            context.tr('log_symptom_fatigue'),
            45,
            theme.colorScheme.primary.withAlpha(102),
            textColor,
            subtitleColor,
            isDark,
          ),
          const SizedBox(height: 20),
          _buildBar(
            context,
            context.tr('log_symptom_bloating'),
            20,
            theme.colorScheme.primary.withAlpha(51),
            textColor,
            subtitleColor,
            isDark,
          ),

          const SizedBox(height: 24),

          // Tip section
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('insights_tip_title'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.tr('insights_tip_text'),
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(
    BuildContext context,
    String label,
    int percentage,
    Color color,
    Color textColor,
    Color subtitleColor,
    bool isDark,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? AppColors.borderDark : AppColors.borderGrayLight,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            children: [
              Container(
                width:
                    MediaQuery.of(context).size.width *
                    (percentage / 100) *
                    0.7, // Approx width based on screen and padding
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
