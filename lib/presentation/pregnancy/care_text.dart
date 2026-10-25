import 'package:flutter/material.dart';

import '../../domain/models/care_event.dart';
import '../../domain/models/pregnancy.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';

/// Bakım kaleminin ekrandaki metinleri. Pano ve randevu listesi aynı
/// metni göstersin diye tek yerde.
extension CareText on BuildContext {
  String careTitle(CareEvent e) =>
      e.isCustom ? (e.title ?? '') : tr('care_${e.code}_title');

  /// "18–22. hafta", "13–17. gün" ya da randevunun tarihi ve saati.
  String careWhen(CareEvent e, Pregnancy p) {
    final randevu = e.scheduledAt;
    if (randevu != null) {
      final saat =
          '${randevu.hour.toString().padLeft(2, '0')}:'
          '${randevu.minute.toString().padLeft(2, '0')}';
      return '${dayMonth(randevu)} · $saat';
    }
    if (e.isCustom) return tr('care_no_date');

    switch (e.anchor) {
      case CareAnchor.gestation:
        final a = e.fromDay ~/ 7;
        final b = e.toDay ~/ 7;
        // İlk izlem "ilk 14 hafta içinde": 0. haftadan başlayan pencere
        // "0–13. hafta" diye yazılınca tuhaf duruyordu.
        if (a == 0) {
          return tr('care_window_before_week', params: {'n': '${b + 1}'});
        }
        if (a == b) return tr('care_window_week', params: {'n': '$a'});
        return tr('care_window_weeks', params: {'a': '$a', 'b': '$b'});
      case CareAnchor.postpartum:
        return tr(
          'care_window_days',
          params: {'a': '${e.fromDay}', 'b': '${e.toDay}'},
        );
    }
  }

  /// "24 hafta 3 günlük gebesin" — 0 ve 1 gün için ayrı anahtar.
  ///
  /// Türkçede tekil/çoğul ayrımı yok ama diğer beş dilde var: tek anahtarla
  /// İngilizce "24 weeks and 1 days" yazıyordu.
  String gestationSentence(GestationalAge ga) => switch (ga.days) {
    0 => tr('preg_week_sentence', params: {'w': '${ga.weeks}'}),
    1 => tr('preg_week_day_sentence_one', params: {'w': '${ga.weeks}'}),
    _ => tr(
      'preg_week_day_sentence',
      params: {'w': '${ga.weeks}', 'd': '${ga.days}'},
    ),
  };

  /// "6. ay"; Fransızcada birinci ay "1er mois" olduğu için ayrı anahtar.
  String monthLabel(int n) => n == 1
      ? tr('preg_month_label_first')
      : tr('preg_month_label', params: {'n': '$n'});

  /// Tahmini doğuma kalan ya da geçen gün — 0 ve 1 için ayrı anahtar.
  String dueCountdown(int kalan) => switch (kalan) {
    0 => tr('preg_due_today'),
    1 => tr('preg_days_left_one'),
    -1 => tr('preg_days_past_one'),
    > 1 => tr('preg_days_left', params: {'n': '$kalan'}),
    _ => tr('preg_days_past', params: {'n': '${-kalan}'}),
  };
}
