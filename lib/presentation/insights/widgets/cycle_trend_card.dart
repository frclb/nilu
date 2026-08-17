import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../localization/app_localizations.dart';
import 'cycle_trend_chart.dart';
import '../../../presentation/calendar/view_models/calendar_view_model.dart';
import '../../../design_system/app_colors.dart';

class CycleTrendCard extends StatelessWidget {
  const CycleTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewModel = context.watch<CalendarViewModel>();
    final avgDays = viewModel.cycleInfo.averageCycleLength.toString();

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('insights_trend_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('insights_trend_subtitle'),
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context.tr(
                      'insights_trend_average',
                      params: {'days': avgDays},
                    ),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      context.tr('insights_trend_average_label'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Chart
          const CycleTrendChart(),

          const SizedBox(height: 36), // Space for X labels
          // Insight Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withAlpha(127)
                  : AppColors.primaryLightTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info,
                  size: 20,
                  color: isDark
                      ? const Color(0xFF7A2A38)
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: textColor,
                        height: 1.5,
                      ),
                      children: _parseBoldText(
                        context.tr('insights_trend_insight_text'),
                        isDark,
                        theme,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simple parser to make numbers/specific text bold if desired.
  // In a real app we might pass the full string with HTML-like tags,
  // but here we know the design specifically bolds "2 gün daha uzun".
  // For simplicity, we just render the raw text, but attempt to bold '2' or specific parts.
  List<TextSpan> _parseBoldText(String text, bool isDark, ThemeData theme) {
    // Basic example of highlighting part of the text from TR translation
    // In actual implementation, you can use the localized string directly.
    return [TextSpan(text: text)];
  }
}
