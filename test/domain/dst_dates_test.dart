import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/calendar_day.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/care_templates.dart';
import 'package:period_tracker/domain/services/pregnancy_calendar.dart';

import '../dst_support.dart';

/// Gebelik tarihleri yaz saatinde kaymıyor.
///
/// `Duration(days: n)` ile gün eklemek Berlin'de 1 Mayıs son adet tarihinin
/// tahmini doğumunu 5 Şubat yerine 4 Şubat kaydediyordu; gün farkı saymak
/// 1 Mart → 1 Nisan'ı 30 gün buluyordu.
///
/// Geliştirme makinesi Türkiye saatinde ve Türkiye'de yaz saati yok: bu
/// iddialar burada kendiliğinden geçer. Asıl sınama `dst_timezones_test`
/// ile yaz saatli saat dilimlerinde.
void main() {
  expectDstZoneInChild();

  group('takvim günü', () {
    test('ilkbahar ve sonbahar geçişinde gün farkı tam', () {
      expect(DateTime(2026, 4, 1).daysSince(DateTime(2026, 3, 1)), 31);
      expect(DateTime(2026, 11, 1).daysSince(DateTime(2026, 10, 1)), 31);
      expect(DateTime(2026, 3, 1).daysSince(DateTime(2026, 4, 1)), -31);
      expect(DateTime(2026, 4, 1, 23, 30).daysSince(DateTime(2026, 4, 1)), 0);
    });

    test('gün eklemek gece yarısında kalıyor', () {
      expect(DateTime(2026, 3, 1).plusDays(31), DateTime(2026, 4, 1));
      expect(DateTime(2026, 10, 1).plusDays(31), DateTime(2026, 11, 1));
      expect(DateTime(2026, 4, 1).plusDays(-31), DateTime(2026, 3, 1));
    });
  });

  group('gebelik', () {
    // Bir yıl boyunca her ayın biri: bazıları tek bir geçişi aşıyor
    // (Mayıs → Şubat yalnızca sonbaharı), bazıları ikisini.
    final sonAdetler = [for (var ay = 1; ay <= 12; ay++) DateTime(2026, ay, 1)];

    test('tahmini doğum son adet + 280 gün; kaydedip okununca da', () {
      for (final sat in sonAdetler) {
        final g = Pregnancy.fromLmp(lmp: sat, cycleLength: 28, id: 'g');
        final beklenen = DateTime(sat.year, sat.month, sat.day + 280);
        expect(g.estimatedDueDate, beklenen, reason: 'SAT $sat');
        expect(
          Pregnancy.fromMap(g.toMap()).estimatedDueDate,
          beklenen,
          reason: 'SAT $sat, kaydedilip okununca',
        );
        expect(g.gestationStart, sat, reason: 'SAT $sat: 0+0 günü');
      }
    });

    test('hafta: son adetten 7 gün sonra 1+0, tahmini doğumda 40+0', () {
      for (final sat in sonAdetler) {
        final g = Pregnancy.fromLmp(lmp: sat, cycleLength: 28, id: 'g');
        expect(g.gestationOn(sat.plusDays(7)), const GestationalAge(1, 0));
        expect(
          g.gestationOn(g.estimatedDueDate),
          const GestationalAge(40, 0),
          reason: 'SAT $sat',
        );
        final biten = g.ended(
          outcome: PregnancyOutcome.birth,
          at: sat.plusDays(273),
        );
        expect(biten.gestationAtEnd, const GestationalAge(39, 0));
      }
    });

    test('takvim: tahmini doğum günü doğru günde, lohusalık günü tam', () {
      for (final sat in sonAdetler) {
        final g = Pregnancy.fromLmp(lmp: sat, cycleLength: 28, id: 'g');
        final edd = DateTime(sat.year, sat.month, sat.day + 280);
        PregnancyDayInfo bilgi(Pregnancy p, DateTime d) =>
            PregnancyCalendar.dayInfo(pregnancies: [p], events: [], date: d);
        expect(bilgi(g, edd).isDueDate, isTrue, reason: 'SAT $sat');
        expect(bilgi(g, edd).gestation, const GestationalAge(40, 0));

        final dogum = sat.plusDays(270);
        final biten = g.ended(outcome: PregnancyOutcome.birth, at: dogum);
        expect(bilgi(biten, dogum.plusDays(30)).postpartumDay, 30);
      }
    });

    test('bakım penceresi takvim günüyle', () {
      for (final sat in sonAdetler) {
        final g = Pregnancy.fromLmp(
          lmp: sat,
          cycleLength: 28,
          confirmedAt: sat.plusDays(42),
          id: 'g',
        );
        for (final e in CareTemplates.generate(
          g,
          CareTemplates.turkeyAntenatal,
        )) {
          expect(
            e.windowStart(g),
            sat.plusDays(e.fromDay),
            reason: 'SAT $sat, ${e.code}',
          );
          expect(e.windowEnd(g), sat.plusDays(e.toDay));
        }
      }
    });
  });
}
