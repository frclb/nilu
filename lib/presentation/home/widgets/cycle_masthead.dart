import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/date_names.dart';
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
    final now = DateTime.now();

    final day = info.currentCycleDay;
    final phase = info.currentPhase;
    final daysUntil = info.daysUntilNextPeriod;

    final agenda = CycleAgenda.upcoming(info, now: now);

    return GestureDetector(
      onTap: () => NavigationService().push(RouteNames.calendar),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        // Uygulamanın geri kalanı yuvarlak kartlarla kurulu; başlık çıplak
        // durunca altındaki kartlarla aynı dili konuşmuyordu.
        child: Container(
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: t.border),
            boxShadow: [
              BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 4),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bugünün tarihi. Ajandadaki satırlar "4 gün", "23 gün" diyor;
                    // bunların neye göre sayıldığı ekranda yazılı olmalı.
                    Text(
                      '${now.day} ${context.monthName(now.month)} '
                      '${now.year} · ${context.weekdayName(now.weekday)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        color: t.textMuted,
                      ),
                    ),
                    const SizedBox(height: 14),

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
                            'date': _formatDate(
                              context,
                              info.predictedNextPeriod!,
                            ),
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
                  ],
                ),
              ),

              // Ajanda kartın ikinci bölümü: aynı yüzeyde ama ayrı okunuyor.
              if (agenda.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: t.surfaceAlt,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      for (var i = 0; i < agenda.length; i++)
                        _AgendaRow(entry: agenda[i], divided: i > 0),
                    ],
                  ),
                ),
            ],
          ),
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

/// Ajanda satırındaki kısa tarih.
///
/// Ay adları için ayrı bir liste tutmuyoruz: uygulamada zaten
/// `context.monthName` var ve takvim de onu kullanıyor. İki ayrı listenin
/// zamanla birbirinden ayrılması kaçınılmazdı.
String _formatDate(BuildContext context, DateTime date) =>
    '${date.day} ${context.monthName(date.month)}';

/// Ajandadaki tek satır: tarih, olay, kalan gün.
class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.entry, required this.divided});

  final AgendaEntry entry;

  /// İlk satırın üstünde çizgi olmuyor: kartın kendi bölüm ayrımı yeterli.
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        decoration: BoxDecoration(
          border: divided ? Border(top: BorderSide(color: t.border)) : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Tam ay adı için yer bırakılıyor: dar sütunda "28 Ağustos"
            // ikiye bölünüyordu.
            SizedBox(
              width: 104,
              child: Text(
                _formatDate(context, entry.date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
