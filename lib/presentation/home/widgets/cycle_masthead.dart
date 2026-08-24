import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../calendar/view_models/calendar_view_model.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../domain/services/cycle_agenda.dart';
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
            // Cevap şekle kodlanmıyor, cümleyle söyleniyor.
            //
            // Halkanın içindeki "5" bir saniyede okunmuyordu: sayının döngü
            // günü olduğunu bilmek gerekiyor. Kullanıcının sorduğu soru ise
            // genelde "kaçıncı gündeyim" değil, "ne zaman başlayacak".
            Text(
              context.tr(_headlineLabelKey(phase)).toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                letterSpacing: 2.4,
                fontWeight: FontWeight.w600,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 2),

            Text(
              _headline(context, phase, day, daysUntil),
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 46,
                height: 1.1,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.2,
              ),
            ),

            // Bu satır yalnızca başlık gelecek reglden bahsederken anlamlı.
            // Regl sürerken "5. gün" altında bir tarih göstermek, o günün o
            // tarihte olduğunu ima ediyordu. Sıradaki regl zaten aşağıdaki
            // ajandada duruyor.
            if (phase != CyclePhase.menstruation &&
                info.predictedNextPeriod != null) ...[
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'home_expected_on',
                  params: {
                    'date': _formatDate(context, info.predictedNextPeriod!),
                  },
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  color: t.textMuted,
                ),
              ),
            ],

            const SizedBox(height: 18),
            CycleBand(info: info, currentDay: day ?? 0),
            const SizedBox(height: 22),

            for (final entry in CycleAgenda.upcoming(info, now: DateTime.now()))
              _AgendaRow(entry: entry),
          ],
        ),
      ),
    );
  }
}

/// Başlık etiketi: durum kelimesi.
String _headlineLabelKey(CyclePhase phase) => switch (phase) {
  CyclePhase.menstruation => 'home_label_period',
  CyclePhase.suppressed => 'home_label_cycle',
  CyclePhase.unknown => 'home_label_cycle',
  _ => 'home_label_next_period',
};

/// Başlık cümlesi.
String _headline(
  BuildContext context,
  CyclePhase phase,
  int? day,
  int? daysUntil,
) {
  if (day == null) return context.tr('home_headline_no_data');
  if (phase == CyclePhase.menstruation) {
    return context.tr('home_headline_period_day', params: {'n': '$day'});
  }
  if (daysUntil == null) {
    return context.tr('home_headline_cycle_day', params: {'n': '$day'});
  }
  if (daysUntil == 0) return context.tr('home_headline_period_today');
  return context.tr('home_headline_days_left', params: {'n': '$daysUntil'});
}

String _formatDate(BuildContext context, DateTime date) {
  final months = context.tr('month_names_short').split(',');
  final name = months.length >= date.month ? months[date.month - 1].trim() : '';
  return '${date.day} $name';
}

/// Ajandadaki tek satır: tarih, olay, kalan gün.
class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.entry});

  final AgendaEntry entry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: t.border)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 62,
              child: Text(
                _formatDate(context, entry.date),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                context.tr(entry.labelKey),
                style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
              ),
            ),
            Text(
              context.tr(
                'agenda_days_away',
                params: {'n': '${entry.daysAway}'},
              ),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                color: t.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
