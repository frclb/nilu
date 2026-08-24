import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/phase_colors.dart';
import '../../../domain/services/phase_guide.dart';
import '../../../localization/app_localizations.dart';
import '../../calendar/view_models/calendar_view_model.dart';
import 'cycle_band.dart';

/// Ana ekranın üst bloğu.
///
/// Önceki düzen ortada 280 piksellik bir halka, içinde gün sayısı, altında
/// rozetler taşıyordu — bu kategorideki hemen her uygulamayla aynı görüntü.
/// Buradaki yerleşim bir almanak sayfası gibi: sola dayalı, büyük serif
/// rakam, küçük harfli etiketler ve döngünün tamamını gösteren bir şerit.
class CycleMasthead extends StatelessWidget {
  const CycleMasthead({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final info = context.watch<CalendarViewModel>().cycleInfo;

    final day = info.currentCycleDay;
    final phase = info.currentPhase;
    final daysUntil = info.daysUntilNextPeriod;

    return GestureDetector(
      onTap: () => NavigationService().push(RouteNames.calendar),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('home_cycle_day_title').toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w600,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 2),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  day == null ? '—' : '$day',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 88,
                    height: 1.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -3,
                  ),
                ),
                const SizedBox(width: 14),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: phase.color(t),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      context.tr(PhaseGuide.forPhase(phase).titleKey),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            CycleBand(info: info, currentDay: day ?? 0),
            const SizedBox(height: 10),

            if (daysUntil != null)
              Text(
                context.tr(
                  'home_days_until_period',
                  params: {'days': '$daysUntil'},
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  color: t.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
