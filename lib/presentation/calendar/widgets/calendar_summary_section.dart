import 'package:flutter/material.dart';
import '../../../design_system/app_palette.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/log_vocabulary.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../design_system/app_colors.dart';
import '../view_models/calendar_view_model.dart';
import 'day_detail_bottom_sheet.dart';

/// Seçili günün kayıt özeti.
///
/// Tarih ve döngü günü başlığı burada değil [CalendarDayHeader]'da; bu bölüm
/// yalnızca o güne girilmiş veriyi (akış, ruh hâli, semptom, not) gösterir.
class CalendarSummarySection extends StatelessWidget {
  const CalendarSummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewModel = context.watch<CalendarViewModel>();
    final selectedDate = viewModel.selectedDate;
    final dailyLog = viewModel.getDailyLogForDate(selectedDate);

    // Başlık seçili güne göre değişir: başka bir gün seçiliyken "Bugünün
    // özeti" demek yanıltıcı oluyordu.
    final isToday = DateUtils.isSameDay(selectedDate, DateTime.now());

    // Gerçek veri kontrolü
    final hasFlow = dailyLog.flowIntensity != null;
    final hasMoods = dailyLog.moods.isNotEmpty;
    final hasSymptoms = dailyLog.symptoms.isNotEmpty;
    final hasNotes = dailyLog.notes != null && dailyLog.notes!.isNotEmpty;
    final hasAnyData = hasFlow || hasMoods || hasSymptoms || hasNotes;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark.withAlpha(127)
                    : AppColors.borderSlateLight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        context.tr(
                          isToday
                              ? 'calendar_today_summary'
                              : 'calendar_day_summary',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          showDayDetailSheet(context, selectedDate),
                      tooltip: context.tr('calendar_add_note'),
                      icon: Icon(
                        Icons.edit,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status Chips - gerçek veriye göre
                if (hasAnyData)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      if (hasFlow)
                        _buildChip(
                          icon: Icons.water_drop,
                          iconColor: AppColors.flowMedium,
                          label: context.tr(
                            LogVocabulary.flowKey(dailyLog.flowIntensity!),
                          ),
                          textColor: isDark
                              ? AppPalette.rose200
                              : theme.colorScheme.primary,
                          bgColor: isDark
                              ? AppColors.secondaryPinkDark
                              : AppColors.primaryLightTint,
                          borderColor: isDark
                              ? theme.colorScheme.primary.withAlpha(25)
                              : AppPalette.rose200,
                        ),
                      if (hasMoods)
                        ...dailyLog.moods.map(
                          (mood) => _buildChip(
                            icon: Icons.sentiment_satisfied,
                            iconColor: AppColors.moodOrangeIcon,
                            label: context.tr(LogVocabulary.moodKey(mood)),
                            textColor: isDark
                                ? AppPalette.clay400
                                : AppColors.moodOrangeText,
                            bgColor: isDark
                                ? AppColors.moodOrangeText.withAlpha(51)
                                : AppColors.moodOrangeBg,
                            borderColor: isDark
                                ? AppColors.moodOrangeIcon.withAlpha(51)
                                : const Color(0xFFFFEDD5),
                          ),
                        ),
                      if (hasSymptoms)
                        ...dailyLog.symptoms
                            .take(3)
                            .map(
                              (symptom) => _buildChip(
                                icon: Icons.healing,
                                iconColor: AppColors.energyPurpleIcon,
                                label: context.tr(
                                  LogVocabulary.symptomKey(symptom),
                                ),
                                textColor: isDark
                                    ? const Color(0xFFE9D5FF)
                                    : AppColors.energyPurpleText,
                                bgColor: isDark
                                    ? AppColors.energyPurpleText.withAlpha(51)
                                    : AppColors.energyPurpleBg,
                                borderColor: isDark
                                    ? AppColors.energyPurpleIcon.withAlpha(51)
                                    : const Color(0xFFF3E8FF),
                              ),
                            ),
                    ],
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      context.tr('calendar_no_log_yet'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),
                Divider(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderSlateLight,
                  height: 1,
                ),
                const SizedBox(height: 20),

                // Notes (gerçek veriden)
                if (hasNotes) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.borderSlateDark.withAlpha(76)
                              : const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.note_alt_outlined,
                          color: isDark
                              ? AppColors.textMutedSlateDark
                              : AppColors.textMutedSlate,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('log_notes'),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dailyLog.notes!,
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Suggestion
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.suggestionTealText.withAlpha(51)
                              : AppColors.suggestionTealBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.self_improvement,
                          color: isDark
                              ? const Color(0xFF5EEAD4)
                              : AppColors.suggestionTealText,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('calendar_daily_suggestion'),
                              style: theme.textTheme.displayLarge?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('calendar_daily_suggestion_text'),
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color textColor,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
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
    );
  }
}
