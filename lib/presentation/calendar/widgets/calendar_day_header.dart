import '../../../domain/models/pregnancy_month.dart';
import '../../../domain/view_models/pregnancy_view_model.dart';
import '../../pregnancy/care_text.dart';
import '../../pregnancy/stage_bleeding_note.dart';
import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/app_snack.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../domain/services/phase_guide.dart';
import 'package:provider/provider.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/date_names.dart';
import '../view_models/calendar_view_model.dart';
import '../../../domain/models/log_vocabulary.dart';
import 'day_detail_bottom_sheet.dart';

/// Seçili günün kimliği, durumu ve o güne uygulanan eylemler.
///
/// Bu bilgi ekranda eskiden **iki kez** çıkıyordu: takvim kartının altındaki
/// küçük kutu ("18 Ağu · Döngü günü 2 · Regl günü") ve hemen ardından gelen
/// özet bölümünün başlığı ("18 Ağustos / Salı · Döngü günü 2"). Üstelik eylem
/// düğmeleri, üzerinde çalıştıkları günün bilgisinden **önce** geliyordu.
///
/// Tek başlıkta toplandı. Ekran sırası artık okunma sırasıyla aynı:
/// takvim → seçili gün ve durumu → o güne yapılacak eylemler → günün özeti.
class CalendarDayHeader extends StatelessWidget {
  const CalendarDayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<CalendarViewModel>();

    final selectedDate = viewModel.selectedDate;
    final cycleDay = viewModel.getCycleDayForDate(selectedDate);
    final isPeriod = viewModel.isPeriodDay(selectedDate);
    final status = _DayStatus.resolve(
      context,
      isPeriod: isPeriod,
      isSpotting:
          viewModel.getDailyLogForDate(selectedDate).flowIntensity ==
          LogVocabulary.spotting,
      isOvulation: viewModel.cycleInfo.isOvulationDay(selectedDate),
      isFertile: viewModel.cycleInfo.isFertile(selectedDate),
      isPredicted: viewModel.isPredictedPeriodDay(selectedDate),
    );

    final dateStr =
        '${selectedDate.day} ${context.monthName(selectedDate.month)}';

    // Gebelik ya da lohusalık günü: döngü günü yerine kaçıncı hafta ve ay
    // ya da doğumdan sonraki gün.
    final gebelik = context.watch<PregnancyViewModel>().dayInfo(selectedDate);
    final ga = gebelik.gestation;
    final lohusa = gebelik.postpartumDay;
    final evreEtiketi = ga != null
        ? '${ga.weeks}+${ga.days} · '
              '${context.monthLabel(PregnancyMonth.of(ga).number)}'
        : lohusa != null
        ? (lohusa == 0
              ? context.tr('pp_day_birth')
              : context.tr('care_summary_pp_day', params: {'n': '$lohusa'}))
        : null;

    final t = context.tokens;
    final primary = theme.colorScheme.primary;

    // Döngü günü etiketine seçili günün evresi ekleniyor ("Döngü günü 16 ·
    // Luteal Faz"). Yalnızca evrenin gerçekten hesaplandığı durumda:
    // gebelikte ve lohusalıkta evre yok, hormonal yöntemde ve veri yokken
    // de "evre" diye bir şey söylenmiyor.
    final phase = viewModel.phaseForDate(selectedDate);
    final evreAdi =
        viewModel.lifeStage.showsCyclePredictions &&
            phase != CyclePhase.unknown &&
            phase != CyclePhase.suppressed
        ? context.tr(PhaseGuide.forPhase(phase).titleKey)
        : null;
    final dongu = cycleDay == null
        ? null
        : [
            context.tr('calendar_cycle_day', params: {'day': '$cycleDay'}),
            ?evreAdi,
          ].join(' · ');
    final etiket = evreEtiketi ?? dongu;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarih ve gün adı yan yana; sığmazsa gün adı alt
                      // satıra iniyor.
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 8,
                        children: [
                          Text(
                            dateStr,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 26,
                              color: primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text(
                              context.weekdayName(selectedDate.weekday),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: t.textFaint,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Etiketin yeri her zaman ayrılıyor ve tek satır:
                      // ilk regl işaretlenince etiket beliriyor ("Döngü
                      // günü 1"); yer ayrılmasaydı alttaki düğmeler
                      // parmağın altından kayar, "Regli kaldır"a hemen
                      // basılamazdı.
                      Visibility(
                        visible: etiket != null,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: t.brandTint,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              etiket ?? ' ',
                              key: etiket == null
                                  ? null
                                  : const Key('calendar_day_chip'),
                              maxLines: 1,
                              softWrap: false,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ExcludeSemantics(
                  child: AppIconTile(
                    icon: Icons.calendar_month_outlined,
                    circle: true,
                    background: t.brandTint,
                    color: primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Seçili günün durumu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: t.brandTint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Icon(status.icon, size: 18, color: status.color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: status.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tahmini doğum günü ve o günün randevuları.
            if (gebelik.isDueDate)
              _GebelikSatiri(
                icon: Icons.star_rounded,
                text: context.tr('calendar_due_date'),
              ),
            for (final e in gebelik.appointments)
              _GebelikSatiri(
                icon: Icons.event_available,
                text:
                    '${context.careTitle(e)} · '
                    '${e.scheduledAt!.hour.toString().padLeft(2, '0')}:'
                    '${e.scheduledAt!.minute.toString().padLeft(2, '0')}',
              ),

            const SizedBox(height: 16),

            // Seçili güne uygulanan eylemler.
            // Erişilebilir dokunma alanı (min 48dp); uzun çevirilerde taşma
            // yerine kısaltma.
            // Regl kaydının tutulmadığı evrede (gebelik, lohusalık) işaretleme
            // düğmesi yok; yerine neden olmadığı yazıyor.
            if (viewModel.lifeStage.recordsPeriods)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isaretle = OutlinedButton.icon(
                    onPressed: () => _togglePeriod(context, viewModel),
                    icon: Icon(
                      isPeriod ? Icons.water_drop : Icons.water_drop_outlined,
                      size: 18,
                    ),
                    label: Text(
                      context.tr(
                        isPeriod
                            ? 'calendar_unmark_period'
                            : 'calendar_mark_period',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      // Gül "hayalet" hap: ikincil eylem. Regl günündeyse
                      // ("Regli kaldır") akış tonunda.
                      backgroundColor: isPeriod ? t.flowTint : t.secondaryTint,
                      foregroundColor: isPeriod ? t.flowText : t.secondary,
                      side: BorderSide.none,
                      textStyle: _markStyle(theme),
                    ),
                  );
                  final notEkle = _NotEkle(date: selectedDate);

                  // Yan yana sığmıyorsa (büyük yazı, uzun çeviri) alt alta:
                  // iki düğme de etiketini tam gösteriyor.
                  if (_yanYanaSigar(context, constraints.maxWidth)) {
                    return Row(
                      children: [
                        Expanded(child: isaretle),
                        const SizedBox(width: 10),
                        Expanded(child: notEkle),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [isaretle, const SizedBox(height: 10), notEkle],
                  );
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StageBleedingNote(stage: viewModel.lifeStage),
                  const SizedBox(height: 12),
                  _NotEkle(date: selectedDate),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// "Regl işaretle" düğmesinin yazı biçimi.
  static TextStyle? _markStyle(ThemeData theme) => theme.textTheme.titleMedium
      ?.copyWith(fontSize: 14, fontWeight: FontWeight.w700);

  /// İki eylem düğmesi yan yana etiketlerini kısaltmadan sığıyor mu?
  ///
  /// Uzun olan etiket ölçülüyor ("Regli kaldır" ile "Regl işaretle" arasında
  /// geçerken düzen zıplamasın).
  bool _yanYanaSigar(BuildContext context, double genislik) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final yon = Directionality.of(context);
    double olc(String metin, TextStyle? stil) {
      final p = TextPainter(
        text: TextSpan(text: metin, style: stil),
        textDirection: yon,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = p.width;
      p.dispose();
      return w;
    }

    final yarim = (genislik - 10) / 2;
    final isaret = [
      olc(context.tr('calendar_mark_period'), _markStyle(theme)),
      olc(context.tr('calendar_unmark_period'), _markStyle(theme)),
    ].reduce((a, b) => a > b ? a : b);
    // Simge 18 + boşluk 8 + iç boşluk 2 × 10.
    if (isaret + 18 + 8 + 20 + 4 > yarim) return false;
    // `AppGradientButton`: simge 20 + boşluk 10 + iç boşluk 2 × 24.
    final not = olc(
      context.tr('calendar_add_note'),
      theme.textTheme.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      ),
    );
    return not + 20 + 10 + 48 + 4 <= yarim;
  }

  Future<void> _togglePeriod(
    BuildContext context,
    CalendarViewModel viewModel,
  ) async {
    final date = viewModel.selectedDate;
    final success = await viewModel.togglePeriodDay(date);
    if (!context.mounted) return;

    if (!success) {
      AppSnack.error(context, context.tr('calendar_future_date_error'));
      return;
    }

    // Başarıda bildirim **yok**. Bildirim, kısa ekranlarda tam o günün
    // eylem düğmelerinin üstüne biniyordu (466×678'de düğmeler 645,
    // bildirim 614–678) ve dört saniye boyunca dokunuşu yutuyordu — yani
    // yanlış güne dokunan kullanıcı tam düzeltmek istediği anda
    // "Regli kaldır"a basamıyordu.
    //
    // Sonuç zaten ekranda: gün rozeti değişiyor ve düğme "Regl işaretle" ile
    // "Regli kaldır" arasında dönüyor. Hata durumundaki bildirim duruyor;
    // orada değişen bir şey olmadığı için tek geri bildirim o.
  }
}

/// Seçili günün durum rozetini (metin + renk + ikon) çözer.
class _DayStatus {
  final String text;
  final Color color;
  final IconData icon;

  /// Metnin rengi. Dolgu tonları ([AppTokens.flow], tahmin için
  /// [AppTokens.flowSoft]) küçük metinde açık zeminde okunmuyor; metin
  /// aynı ailenin koyu tonunda.
  final Color textColor;

  const _DayStatus(this.text, this.color, this.icon, this.textColor);

  static _DayStatus resolve(
    BuildContext context, {
    required bool isPeriod,
    required bool isSpotting,
    required bool isOvulation,
    required bool isFertile,
    required bool isPredicted,
  }) {
    if (isPeriod) {
      return _DayStatus(
        context.tr('calendar_status_period'),
        context.tokens.flow,
        Icons.water_drop,
        context.tokens.flowText,
      );
    }
    // Kaydedilmiş kanama, tahmin edilen yumurtlama ve doğurgan günün
    // önünde geliyor: biri kullanıcının gerçekten yazdığı bir bulgu,
    // diğerleri hesaplanmış birer öngörü. "Normal gün" demek, az önce
    // lekelenme kaydeden kişiye kaydın kaybolduğunu düşündürüyordu.
    if (isSpotting) {
      return _DayStatus(
        context.tr('log_flow_spotting'),
        context.tokens.flow,
        Icons.circle_outlined,
        context.tokens.flowText,
      );
    }
    if (isOvulation) {
      return _DayStatus(
        context.tr('calendar_status_ovulation'),
        context.tokens.ovulation,
        Icons.star,
        context.tokens.ovulationText,
      );
    }
    if (isFertile) {
      return _DayStatus(
        context.tr('calendar_status_fertile'),
        context.tokens.secondary,
        Icons.favorite,
        context.tokens.secondary,
      );
    }
    if (isPredicted) {
      return _DayStatus(
        context.tr('calendar_status_predicted'),
        context.tokens.flowSoft,
        Icons.water_drop_outlined,
        context.tokens.flowText,
      );
    }
    return _DayStatus(
      context.tr('calendar_status_normal'),
      context.tokens.textMuted,
      Icons.circle_outlined,
      context.tokens.textMuted,
    );
  }
}

/// "Not ekle": seçili günün sayfasını açan ana eylem (degrade hap).
class _NotEkle extends StatelessWidget {
  const _NotEkle({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return AppGradientButton(
      label: context.tr('calendar_add_note'),
      icon: Icons.edit_note,
      height: 48,
      radius: AppRadius.pill,
      onPressed: () => showDayDetailSheet(context, date),
    );
  }
}

class _GebelikSatiri extends StatelessWidget {
  const _GebelikSatiri({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final renk = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 12, right: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: renk),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: renk,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
