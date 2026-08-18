import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../localization/app_localizations.dart';
import 'cycle_trend_chart.dart';
import '../../../presentation/calendar/view_models/calendar_view_model.dart';
import '../../../design_system/app_colors.dart';
import '../../../domain/services/insights_service.dart';

/// Kullanıcının gözlenmiş döngü uzunlukları.
///
/// Kart eskiden her zaman dolu görünüyordu: grafik sabit bir eğri, alttaki
/// yorum ise "Döngünüz bu ay normalden 2 gün daha uzun sürdü" diye sabit bir
/// cümleydi — kullanıcı hiç kayıt girmemiş olsa bile. Artık hem sayılar hem
/// yorum gerçek kayıtlardan geliyor, yetecek veri yoksa kart bunu söylüyor.
class CycleTrendCard extends StatelessWidget {
  const CycleTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewModel = context.watch<CalendarViewModel>();

    final points = InsightsService.cycleLengths(viewModel.periodLogs);
    final average = InsightsService.averageLength(points);
    final variation = InsightsService.variation(points);

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
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
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
                      points.isEmpty
                          ? context.tr('insights_trend_no_data_subtitle')
                          : context.tr(
                              'insights_trend_cycles',
                              params: {'count': '${points.length}'},
                            ),
                      style: TextStyle(fontSize: 12, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              if (average != null) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.tr(
                        'insights_trend_average',
                        params: {'days': '$average'},
                      ),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? Colors.white
                            : theme.colorScheme.primary,
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
            ],
          ),

          const SizedBox(height: 24),

          if (points.isEmpty)
            _EmptyState(subtitleColor: subtitleColor)
          else ...[
            CycleTrendChart(points: points),
            const SizedBox(height: 20),
            _InsightBox(
              text: _insightText(context, variation),
              isDark: isDark,
              textColor: textColor,
            ),
          ],
        ],
      ),
    );
  }

  /// Grafiğin altındaki cümle.
  ///
  /// Tek döngü varken yorum yapılmaz: iki ölçüm olmadan "düzenli" ya da
  /// "değişken" demek veriye dayanmaz.
  String? _insightText(BuildContext context, int? variation) {
    if (variation == null) return null;
    return context.tr(
      variation <= 3 ? 'insights_trend_steady' : 'insights_trend_variable',
      params: {'days': '$variation'},
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color subtitleColor;

  const _EmptyState({required this.subtitleColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.insights_outlined, size: 20, color: subtitleColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            context.tr('insights_trend_empty'),
            style: TextStyle(fontSize: 13, height: 1.5, color: subtitleColor),
          ),
        ),
      ],
    );
  }
}

class _InsightBox extends StatelessWidget {
  final String? text;
  final bool isDark;
  final Color textColor;

  const _InsightBox({
    required this.text,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final message = text;
    if (message == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
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
            Icons.info_outline,
            size: 20,
            color: isDark ? const Color(0xFF7A2A38) : theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: textColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
