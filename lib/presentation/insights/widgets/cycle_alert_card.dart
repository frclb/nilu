import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_decor.dart';
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        // Şeftaliden güle: dikkat çekiyor ama alarm vermiyor. Söylediği
        // şey "tekrar ederse hekime sor", "acil" değil.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.accentTint, t.brandTint, t.secondaryTint],
        ),
        boxShadow: AppShadows.soft(context),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: Icons.notifications_active,
            // Koyu temada ikincil renk açık pembe; üstünde beyaz okunmuyor.
            color: theme.colorScheme.onSecondary,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [t.secondary.withAlpha(170), t.secondary],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSectionLabel(
                  context.tr('alert_section_title'),
                  color: t.secondary,
                ),
                const SizedBox(height: 6),
                for (final alert in alerts) ...[
                  Text(
                    context.tr(CycleAlertService.titleKey(alert)),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr(
                      CycleAlertService.bodyKey(alert),
                      params: {'count': '$episodes'},
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline,
                        size: 15,
                        color: t.textMuted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        context.tr('alert_disclaimer'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11.5,
                          height: 1.4,
                          color: t.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
