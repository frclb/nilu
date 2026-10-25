import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/navigation_service.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/date_names.dart';
import '../../calendar/view_models/calendar_view_model.dart';
import '../../calendar/widgets/day_detail_bottom_sheet.dart';
import '../../../domain/models/calendar_day.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../domain/services/cycle_agenda.dart';
import 'cycle_ring.dart';
import 'cycle_ring_data.dart';
import 'home_hero_card.dart';

/// Ana ekranın üst bloğu: bugünün tarihi, döngü halkası ve sıradakiler.
///
/// Halkanın ortasında bir sayı değil cümle duruyor ("9 gün var"): çıplak bir
/// sayının döngü günü olduğunu bilmek gerekiyordu. Kartın altında yaklaşan
/// üç olay, her biri halkadaki renginde.
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

    // Başlık zaten "Döngü günü N" diyorsa üstteki hap aynı şeyi
    // tekrarlamasın.
    final headlineIsCycleDay =
        day != null &&
        phase != CyclePhase.menstruation &&
        daysLate <= 0 &&
        daysUntil == null;

    // Kurulumda gebelik yolunu seçen kullanıcı döngü süresini hiç
    // söylemedi; varsayılan 28'i "/ 28" diye onunmuş gibi yazmıyoruz.
    final dayPill = day == null || headlineIsCycleDay
        ? null
        : context.tr('calendar_cycle_day', params: {'day': '$day'}) +
              (takvim.cycleLengthKnown ? ' / ${info.averageCycleLength}' : '');

    // Tahmini yumurtlama günü halkada ayrıca işaretleniyor — yalnızca
    // doğurganlık izleniyorsa ve o gün gerçekten yumurtlama rengindeyse.
    final ovulationDay = info.averageCycleLength - 14;
    final marker =
        day != null &&
            ovulationDay >= 1 &&
            info.phaseForRingDay(ovulationDay) == CyclePhase.ovulation
        ? ovulationDay - 1
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: HomeHeroCard(
        onTap: () => NavigationService().push(RouteNames.calendar),
        // Altta "Bu tahmin nasıl hesaplandı?" düğmesinin kendi boşluğu var.
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          daysLate <= 0 && agenda.isNotEmpty ? 12 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroDateLine(
              date: now,
              trailing: dayPill == null
                  ? null
                  : AppTag(
                      label: dayPill,
                      background: t.accentTint.withAlpha(200),
                      foreground: t.accent,
                      border: t.phaseLuteal.withAlpha(60),
                    ),
            ),
            const SizedBox(height: 10),
            CycleRing(
              data: CycleRingData.from(
                info: info,
                currentDay: day ?? 0,
                tokens: t,
              ),
              markerIndex: marker,
              caption: takvim.cycleLengthKnown
                  ? RingCaption.pill(
                      RingCaption.cycleLength(context, info.averageCycleLength),
                    )
                  : RingCaption(context.tr('home_ring_cycle_length_unknown')),
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: t.secondaryTint.withAlpha(140),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      context.upper(
                        context.tr(_headlineLabelKey(phase, daysLate)),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                        color: t.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
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
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 36,
                        height: 1.05,
                        letterSpacing: -0.6,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Gecikmede ajanda boş (tahmin zinciri kaçırılmış bir
            // başlangıca dayanıyor). Yerine bir sebep öne sürmeyen kısa bir
            // not: kayma sık, gebelik olasılığı varsa test sonucu bugüne
            // kaydedilebilir.
            if (daysLate > 0) ...[
              const SizedBox(height: 14),
              const HeroDivider(),
              const SizedBox(height: 14),
              const _LateNote(),
            ] else if (agenda.isNotEmpty) ...[
              const SizedBox(height: 14),
              const HeroDivider(),
              const SizedBox(height: 14),
              AppSectionLabel(context.tr('home_agenda_title')),
              const SizedBox(height: 10),
              for (var i = 0; i < agenda.length; i++) ...[
                if (i > 0) const SizedBox(height: 6),
                _AgendaRow(
                  entry: agenda[i],
                  // Sonraki regl tek gün değil aralık: kesinlik iddia
                  // etmesin (bkz. `PredictionBasis`).
                  range:
                      agenda[i].kind == AgendaKind.periodStart &&
                          info.basis != null &&
                          agenda[i].date == info.predictedNextPeriod
                      ? (info.basis!.earliest, info.basis!.latest)
                      : null,
                ),
              ],
              const SizedBox(height: 2),
              const _PredictionHowLink(),
            ],
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
      final n = periodLength ?? day;
      return context.tr(
        n == 1
            ? 'home_headline_period_finished_one'
            : 'home_headline_period_finished',
        params: {'n': '$n'},
      );
    }
    return context.tr('home_headline_period_day', params: {'n': '$day'});
  }
  // Gecikme kendi cümlesini hak ediyor. `daysUntil` sıfırın altına inmediği
  // için gecikmenin her gününde "bugün başlıyor" yazıyordu.
  if (daysLate > 0) {
    return context.tr(
      daysLate == 1 ? 'home_headline_late_one' : 'home_headline_late',
      params: {'n': '$daysLate'},
    );
  }
  if (daysUntil == null) {
    return context.tr('home_headline_cycle_day', params: {'n': '$day'});
  }
  if (daysUntil == 0) return context.tr('home_headline_period_today');
  return context.tr(
    daysUntil == 1 ? 'home_headline_days_left_one' : 'home_headline_days_left',
    params: {'n': '$daysUntil'},
  );
}

/// Ajandadaki tek satır: simge, tarih ve olay, kalan gün.
class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.entry, this.range});

  final AgendaEntry entry;

  /// Tahmin aralığı; verilirse tarih yerine o yazılıyor.
  final (DateTime, DateTime)? range;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final period = entry.kind == AgendaKind.periodStart;

    // Renk satırı halkayla eşliyor: aynı olay ekranda iki yerde aynı
    // renkte görünsün.
    final color = period ? t.flow : t.ovulation;
    final deep = period
        ? Color.lerp(t.flow, t.flowText, 0.35)!
        : Color.lerp(t.ovulation, t.ovulationText, 0.6)!;
    final tint = period ? t.flowTint : t.ovulationTint;
    final ink = period ? t.flowText : t.ovulationText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: t.brandTint.withAlpha(150),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tint.withAlpha(120)),
      ),
      child: Row(
        children: [
          AppIconTile(
            icon: switch (entry.kind) {
              AgendaKind.periodStart => Icons.water_drop_rounded,
              AgendaKind.fertileStart => Icons.egg_rounded,
              // Halkada yumurtlama günü de halka içinde nokta.
              AgendaKind.ovulation => Icons.radio_button_checked_rounded,
            },
            size: 32,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, deep],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (range) {
                    (final a, final b) => context.dayRange(a, b),
                    null => context.dayMonth(entry.date),
                  },
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 13.5,
                    height: 1.25,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  context.tr(entry.labelKey),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.3,
                    color: t.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Uzun etiket ("Tahmini doğurgan dönem başlıyor") kalan güne
          // yapışmasın.
          const SizedBox(width: 8),
          AppTag(
            label: context.tr(
              entry.daysAway == 1 ? 'agenda_days_away_one' : 'agenda_days_away',
              params: {'n': '${entry.daysAway}'},
            ),
            background: tint,
            foreground: ink,
          ),
        ],
      ),
    );
  }
}

/// "Bu tahmin nasıl hesaplandı?" satırı.
class _PredictionHowLink extends StatelessWidget {
  const _PredictionHowLink();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: TextButton(
        key: const Key('home_prediction_how'),
        onPressed: () => NavigationService().push(RouteNames.predictionInfo),
        style: TextButton.styleFrom(
          foregroundColor: t.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: const Size(0, 44),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.insights_rounded,
              size: 17,
              color: theme.colorScheme.primary.withAlpha(190),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.tr('home_prediction_how'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: t.textMuted,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: t.textFaint),
          ],
        ),
      ),
    );
  }
}

/// Gecikmedeki not ve bugünün kaydını açan düğme.
class _LateNote extends StatelessWidget {
  const _LateNote();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Container(
      key: const Key('home_late_note'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: t.brandTint.withAlpha(150),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: t.flowTint.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: t.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('home_late_note'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    height: 1.45,
                    color: t.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          TextButton.icon(
            key: const Key('home_late_log_today'),
            onPressed: () =>
                showDayDetailSheet(context, DateTime.now().plusDays(0)),
            icon: const Icon(Icons.edit_note_rounded, size: 18),
            label: Text(context.tr('home_late_log_today')),
            style: TextButton.styleFrom(
              foregroundColor: t.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 44),
            ),
          ),
        ],
      ),
    );
  }
}
