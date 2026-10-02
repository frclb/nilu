import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/phase_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/date_names.dart';
import '../../calendar/view_models/calendar_view_model.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../domain/services/cycle_agenda.dart';
import 'cycle_ring.dart';
import 'cycle_ring_data.dart';

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
    final takvim = context.watch<CalendarViewModel>();
    final info = takvim.cycleInfo;
    final now = DateTime.now();

    // Gebelik bitti, ondan sonra henüz regl kaydı yok. Döngü istatistiği
    // kesintiden sonraki başlangıçlardan hesaplanıyor (bkz.
    // `CycleIntervals.usableStarts`); kayıt yokken gün de yok. Başlık o
    // zaman "Henüz kayıt yok" diyordu — kayıtları olan, çoğu zaman da bir
    // kaybın hemen ardındaki kullanıcıya.
    final afterPregnancy = takvim.cycleBreaks.isNotEmpty;

    final day = info.currentCycleDay;
    final phase = info.currentPhase;
    final daysUntil = info.daysUntilNextPeriod;
    final daysLate = info.daysLateAt(now);

    final agenda = CycleAgenda.upcoming(info, now: now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      // Kart görünümü paylaşılan bileşenden: yarıçap, kenarlık ve gölge
      // tek yerde tanımlı olsun ki ekranlar arasında derinlik tutarlı olsun.
      child: AppSectionedCard(
        onTap: () => NavigationService().push(RouteNames.calendar),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bugünün tarihi. Ajandadaki satırlar "4 gün", "23 gün" diyor;
            // bunların neye göre sayıldığı ekranda yazılı olmalı.
            Text(
              '${now.day} ${context.monthName(now.month)} '
              '${now.year} · ${context.weekdayName(now.weekday)}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
            const SizedBox(height: 6),

            // Cevap şekle kodlanmıyor, cümleyle söyleniyor.
            //
            // Halkanın içindeki çıplak bir sayı ("5") bir saniyede
            // okunmuyor: onun döngü günü olduğunu bilmek gerekiyor.
            // Merkezde duran şey bir sayı değil, cümle.
            CycleRing(
              data: CycleRingData.from(
                info: info,
                currentDay: day ?? 0,
                tokens: t,
              ),
              // Kurulumda gebelik yolunu seçen kullanıcı döngü süresini hiç
              // söylemedi; gebelik bitince halka varsayılan 28'i "28 günlük
              // döngü" diye onunmuş gibi yazıyordu.
              caption: takvim.cycleLengthKnown
                  ? null
                  : context.tr('home_ring_cycle_length_unknown'),
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.upper(
                      context.tr(_headlineLabelKey(phase, daysLate)),
                    ),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w700,
                      // Etiket gri değil evre renginde: çelenkteki
                      // renkle aynı şeyi söylüyor.
                      color: phase.color(t),
                    ),
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _headline(
                        context,
                        phase,
                        day,
                        daysUntil,
                        daysLate,
                        finishedToday: info.periodEndedToday,
                        periodLength: info.currentPeriodLength,
                        afterPregnancy: afterPregnancy,
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 34,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        footer: agenda.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Text(
                    context.upper(context.tr('home_agenda_title')),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (var i = 0; i < agenda.length; i++)
                    _AgendaRow(entry: agenda[i], divided: i > 0),
                  const SizedBox(height: 6),
                ],
              ),
      ),
    );
  }
}

/// Başlık etiketi: durum kelimesi.
String _headlineLabelKey(CyclePhase phase, int daysLate) {
  if (phase == CyclePhase.menstruation) return 'home_label_period';
  if (daysLate > 0) return 'home_label_period';
  if (phase == CyclePhase.suppressed || phase == CyclePhase.unknown) {
    return 'home_label_cycle';
  }
  return 'home_label_next_period';
}

/// Başlık cümlesi.
String _headline(
  BuildContext context,
  CyclePhase phase,
  int? day,
  int? daysUntil,
  int daysLate, {
  required bool finishedToday,
  int? periodLength,
  bool afterPregnancy = false,
}) {
  if (day == null) {
    return context.tr(
      afterPregnancy
          ? 'home_headline_after_pregnancy'
          : 'home_headline_no_data',
    );
  }
  if (phase == CyclePhase.menstruation) {
    // "Reglim bitti" bugünü kayıttan silmiyor, son gün olarak işaretliyor;
    // faz o yüzden hâlâ menstrüasyon. Ama sayfanın en büyük yazısı
    // "3. gün" deyince kullanıcı hâlâ regl gününde olduğunu okuyor ve
    // hemen altındaki "Reglin bugün bitti" ile çelişiyordu.
    if (finishedToday) {
      return context.tr(
        'home_headline_period_finished',
        params: {'n': '${periodLength ?? day}'},
      );
    }
    return context.tr('home_headline_period_day', params: {'n': '$day'});
  }
  // Gecikme kendi cümlesini hak ediyor. `daysUntil` sıfırın altına inmediği
  // için gecikmenin her gününde "bugün başlıyor" yazıyordu.
  if (daysLate > 0) {
    return context.tr('home_headline_late', params: {'n': '$daysLate'});
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
            // Renk noktası satırı halkayla eşliyor: aynı olay ekranda iki
            // yerde aynı renkte görünsün.
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _entryColor(entry.kind, t),
                shape: BoxShape.circle,
              ),
            ),
            // Tam ay adı için yer bırakılıyor: dar sütunda "28 Ağustos"
            // ikiye bölünüyordu.
            SizedBox(
              width: 96,
              child: Text(
                _formatDate(context, entry.date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
            ),
            Expanded(
              child: Text(
                context.tr(entry.labelKey),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  color: t.text,
                ),
              ),
            ),
            Text(
              context.tr(
                'agenda_days_away',
                params: {'n': '${entry.daysAway}'},
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

/// Ajanda satırındaki renk noktası — halkadaki evre renkleriyle aynı.
Color _entryColor(AgendaKind kind, AppTokens t) => switch (kind) {
  AgendaKind.periodStart => t.flow,
  AgendaKind.fertileStart => t.ovulation,
  AgendaKind.ovulation => t.ovulation,
};
