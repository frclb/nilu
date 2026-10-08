import 'package:flutter/widgets.dart';

import '../../domain/models/calendar_day.dart';
import '../../domain/models/cycle_info.dart';
import '../../domain/models/home_widget_entry.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/models/pregnancy_month.dart';
import '../../localization/app_localizations.dart';
import '../pregnancy/care_text.dart';

/// Ana ekran widget'ının önümüzdeki [days] günü, uygulamanın dilinde.
///
/// Gebelik ve lohusalık metinleri panodakiyle aynı yardımcılardan geçiyor
/// ("24+2", "6. ay", "10. gün"): ayrı bir kopya zamanla ayrışırdı.
///
/// Evre her gün için o günün tarihine göre çözülüyor: lohusalık 42. günde
/// bitiyorsa sonraki günler döngü girdisi oluyor.
class HomeWidgetPlan {
  const HomeWidgetPlan._();

  /// Uygulama bu kadar gün açılmasa da widget doğru günü gösterir;
  /// sonrasında "güncellemek için aç" der.
  static const int days = 14;

  /// [afterPregnancy]: gebelik bitmiş ve ondan sonra regl kaydı yok. Ana
  /// ekran o zaman "Henüz kayıt yok" yerine "İlk reglin bekleniyor" diyor.
  static List<HomeWidgetEntry> build(
    BuildContext context, {
    required CycleInfo cycle,
    required List<Pregnancy> pregnancies,
    required DateTime today,
    bool afterPregnancy = false,
  }) {
    final bugun = DateTime(today.year, today.month, today.day);
    return [
      for (var i = 0; i < days; i++)
        entryFor(
          context,
          bugun.plusDays(i),
          cycle: cycle,
          pregnancies: pregnancies,
          afterPregnancy: afterPregnancy,
        ),
    ];
  }

  static HomeWidgetEntry entryFor(
    BuildContext context,
    DateTime date, {
    required CycleInfo cycle,
    required List<Pregnancy> pregnancies,
    bool afterPregnancy = false,
  }) {
    final gun = DateTime(date.year, date.month, date.day);
    final evre = LifeStage.resolve(pregnancies, today: gun);
    final gebelik = LifeStage.relevantPregnancy(pregnancies, today: gun);
    return switch (evre) {
      LifeStage.pregnancy when gebelik != null => _gebelik(
        context,
        gun,
        gebelik,
      ),
      LifeStage.postpartum when gebelik?.endedAt != null => _lohusa(
        context,
        gun,
        gebelik!,
      ),
      _ => _dongu(context, gun, cycle, afterPregnancy: afterPregnancy),
    };
  }

  static HomeWidgetEntry _bos(DateTime gun, String metin) =>
      HomeWidgetEntry(date: gun, hasData: false, detail: metin, spoken: metin);

  static String _cumle(List<String> parcalar) =>
      parcalar.where((p) => p.isNotEmpty).join(', ');

  static HomeWidgetEntry _dongu(
    BuildContext context,
    DateTime gun,
    CycleInfo cycle, {
    required bool afterPregnancy,
  }) {
    final dongu = cycle.cycleDayOn(gun);
    if (dongu == null) {
      return _bos(
        gun,
        context.tr(
          afterPregnancy ? 'home_headline_after_pregnancy' : 'widget_empty',
        ),
      );
    }

    final kalan = cycle.predictedNextPeriod?.daysSince(gun);
    // Evre yalnızca beklenen regl gelmeden: sonrasında döngünün nerede
    // olduğu bilinmiyor (regl gelmiş ama işaretlenmemiş olabilir).
    final evre = kalan == null || kalan > 0
        ? cycle.phaseForCurrentCycleDay(dongu)
        : CyclePhase.unknown;
    final evreAdi = switch (evre) {
      CyclePhase.menstruation => context.tr('phase_title_menstruation'),
      CyclePhase.follicular => context.tr('phase_title_follicular'),
      CyclePhase.ovulation => context.tr('phase_title_ovulation'),
      CyclePhase.luteal => context.tr('phase_title_luteal'),
      CyclePhase.suppressed || CyclePhase.unknown => '',
    };
    // Reglin içindeyken "Regle 26 gün kaldı" yazmak doğru ama yersiz;
    // evre adı zaten regl diyor.
    final String detay;
    if (kalan == null || evre == CyclePhase.menstruation) {
      detay = '';
    } else {
      detay = switch (kalan) {
        > 1 => context.tr('widget_period_in', params: {'n': '$kalan'}),
        1 => context.tr('widget_period_in_one'),
        0 => context.tr('widget_period_today'),
        -1 => context.tr('widget_period_late_one'),
        _ => context.tr('widget_period_late', params: {'n': '${-kalan}'}),
      };
    }
    // Bugünkü döngünün tahmini uzunluğu üzerinden: "28 günün 14'ü" yarım.
    // Gecikmede uzunluk bilinmiyor; halka dolu çizilse "döngü tamam" derdi.
    final uzunluk = kalan == null || kalan < 0 ? null : dongu + kalan - 1;

    return HomeWidgetEntry(
      date: gun,
      hasData: true,
      label: context.upper(context.tr('widget_cycle_day')),
      value: '$dongu',
      caption: evreAdi,
      detail: detay,
      spoken: _cumle([
        context.tr('home_headline_cycle_day', params: {'n': '$dongu'}),
        evreAdi,
        detay,
      ]),
      progress: uzunluk != null && uzunluk > 0
          ? (dongu / uzunluk).clamp(0.0, 1.0)
          : null,
      colorKey: evre.name,
    );
  }

  static HomeWidgetEntry _gebelik(
    BuildContext context,
    DateTime gun,
    Pregnancy p,
  ) {
    final ga = p.gestationOn(gun);
    if (ga == null) return _bos(gun, context.tr('widget_empty'));
    final ay = context.monthLabel(PregnancyMonth.of(ga).number);
    final geriSayim = context.dueCountdown(p.estimatedDueDate.daysSince(gun));
    return HomeWidgetEntry(
      date: gun,
      hasData: true,
      label: context.upper(context.tr('widget_pregnancy')),
      // Panodaki gösterim: tamamlanan hafta + gün.
      value: '${ga.weeks}+${ga.days}',
      caption: ay,
      detail: geriSayim,
      spoken: _cumle([context.gestationSentence(ga), ay, geriSayim]),
      progress: ((ga.weeks * 7 + ga.days) / Pregnancy.termDays).clamp(0.0, 1.0),
      colorKey: 'pregnancy',
    );
  }

  static HomeWidgetEntry _lohusa(
    BuildContext context,
    DateTime gun,
    Pregnancy p,
  ) {
    final sonra = gun.daysSince(p.endedAt!);
    // Doğum günü "0. gün" değil (bkz. lohusalık panosu).
    final deger = sonra == 0
        ? context.tr('pp_day_birth')
        : context.tr('pp_day', params: {'n': '$sonra'});
    final toplam = context.tr(
      'pp_days_total',
      params: {'n': '${LifeStage.postpartumDays}'},
    );
    return HomeWidgetEntry(
      date: gun,
      hasData: true,
      label: context.upper(context.tr('pp_label')),
      value: deger,
      caption: toplam,
      spoken: _cumle([context.tr('pp_label'), deger, toplam]),
      progress: (sonra / LifeStage.postpartumDays).clamp(0.0, 1.0),
      colorKey: 'postpartum',
    );
  }
}
