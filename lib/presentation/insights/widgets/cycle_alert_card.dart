import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_tokens.dart';
import '../../../domain/models/daily_log.dart';
import '../../../domain/models/period_log.dart';
import '../../../domain/services/cycle_alert.dart';
import '../../../domain/services/insights_service.dart';
import '../../../localization/app_localizations.dart';
import '../../calendar/view_models/calendar_view_model.dart';

/// Döngü uzunluğu sağlık kurumlarının belirttiği aralığın dışına çıktığında
/// kullanıcıyı bilgilendirir.
///
/// Uygulama döngü uzunluklarını zaten hesaplıyordu ama sonuç pasif bir sayı
/// olarak duruyordu; eşik aşıldığında kullanıcıya bir şey söylemiyordu.
///
/// Hiçbir uyarı yoksa hiç görünmez — "her şey yolunda" kartı ekranı
/// kalabalıklaştırır ve gerçek uyarıların dikkat çekiciliğini azaltır.
class CycleAlertCard extends StatelessWidget {
  const CycleAlertCard({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = context.select<CalendarViewModel, List>((v) => v.periodLogs);
    final daily = context.select<CalendarViewModel, List>((v) => v.dailyLogs);
    final breaks = context.select<CalendarViewModel, List<DateSpan>>(
      (v) => v.cycleBreaks,
    );
    final periods = List<PeriodLog>.from(logs);
    final points = InsightsService.cycleLengths(periods, breaks: breaks);
    final dailyLogs = List<DailyLog>.from(daily);
    final alerts = CycleAlertService.evaluate(
      points,
      breaks: breaks,
      dailyLogs: dailyLogs,
      periodLogs: periods,
    );

    // Ara kanama metni kaç kez olduğunu söylüyor: "birkaç kez" demek yerine
    // kullanıcının kendi kaydını göstermek hem doğrulanabilir hem de
    // hekime giderken söyleyeceği sayı.
    final episodes = CycleAlertService.intermenstrualEpisodes(
      dailyLogs: dailyLogs,
      periodLogs: periods,
      breaks: breaks,
    ).length;

    if (alerts.isEmpty) return const SizedBox.shrink();

    final t = context.tokens;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: t.warning.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.warning.withAlpha(64)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: t.warning),
              const SizedBox(width: 8),
              Text(
                context.tr('alert_section_title'),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final alert in alerts) ...[
            Text(
              context.tr(CycleAlertService.titleKey(alert)),
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(
                CycleAlertService.bodyKey(alert),
                params: {'count': '$episodes'},
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                height: 1.55,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            context.tr('alert_disclaimer'),
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 12,
              height: 1.5,
              color: t.textFaint,
            ),
          ),
        ],
      ),
    );
  }
}
