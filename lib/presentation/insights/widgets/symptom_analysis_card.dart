import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';
import '../../../domain/models/log_vocabulary.dart';
import '../../../domain/services/insights_service.dart';
import '../../calendar/view_models/calendar_view_model.dart';

/// Kullanıcının en sık kaydettiği belirtiler.
///
/// Bu kart eskiden dört sabit çubuk gösteriyordu: Kramp %85, Baş Ağrısı %62,
/// Yorgunluk %45, Şişkinlik %20. Sayılar koda gömülüydü; kullanıcı hiç kayıt
/// girmemiş olsa bile aynı grafiği görüyordu. Sağlık verisi sunan bir ekranda
/// "makul görünen" bir sayı, yanlış sayıdan daha tehlikeli.
///
/// Artık her yüzde, kullanıcının kayıt girdiği gün sayısına oranla o belirtiyi
/// kaç günde işaretlediğini gösterir; kayıt yoksa kart bunu söyler.
class SymptomAnalysisCard extends StatelessWidget {
  const SymptomAnalysisCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewModel = context.watch<CalendarViewModel>();

    final frequencies = InsightsService.symptomFrequencies(viewModel.dailyLogs);
    final loggedDays = InsightsService.loggedDayCount(viewModel.dailyLogs);

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
            frequencies.isEmpty
                ? context.tr('insights_symptoms_subtitle')
                : context.tr(
                    'insights_symptoms_basis',
                    params: {'days': '$loggedDays'},
                  ),
            style: TextStyle(fontSize: 12, color: subtitleColor),
          ),

          const SizedBox(height: 24),

          if (frequencies.isEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.edit_note_outlined, size: 20, color: subtitleColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr('insights_symptoms_empty'),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: subtitleColor,
                    ),
                  ),
                ),
              ],
            )
          else
            for (var i = 0; i < frequencies.length; i++) ...[
              if (i > 0) const SizedBox(height: 20),
              _SymptomBar(
                label: context.tr(
                  LogVocabulary.symptomKey(frequencies[i].code),
                ),
                percentage: frequencies[i].percentage,
                dayCount: frequencies[i].dayCount,
                // En sık görülen en koyu; sıra aşağı indikçe soluyor.
                color: theme.colorScheme.primary.withAlpha(
                  [255, 200, 150, 105][i.clamp(0, 3)],
                ),
                textColor: textColor,
                subtitleColor: subtitleColor,
                trackColor: isDark
                    ? AppColors.borderDark
                    : AppColors.borderGrayLight,
              ),
            ],
        ],
      ),
    );
  }
}

class _SymptomBar extends StatelessWidget {
  final String label;
  final int percentage;
  final int dayCount;
  final Color color;
  final Color textColor;
  final Color subtitleColor;
  final Color trackColor;

  const _SymptomBar({
    required this.label,
    required this.percentage,
    required this.dayCount,
    required this.color,
    required this.textColor,
    required this.subtitleColor,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr(
        'insights_symptoms_semantics',
        params: {
          'symptom': label,
          'percent': '$percentage',
          'days': '$dayCount',
        },
      ),
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Ham gün sayısı da gösteriliyor: tek kayıtlı günde "%100"
              // tek başına yanıltıcı, "%100 · 1 gün" değil.
              Text(
                context.tr(
                  'insights_symptoms_count',
                  params: {'percent': '$percentage', 'days': '$dayCount'},
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: trackColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
