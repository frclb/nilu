import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/pregnancy_calendar.dart';

/// Gebeliğin takvimdeki izi: hafta, doğum, lohusalık günü, randevular.
void main() {
  final bugun = DateTime(2026, 10, 2);
  DateTime gun(int fark) => DateTime(bugun.year, bugun.month, bugun.day + fark);

  // 24+2 haftalık süren gebelik.
  final suren = Pregnancy.fromLmp(
    lmp: gun(-170),
    cycleLength: 28,
    confirmedAt: gun(-120),
    id: 'g1',
  );

  PregnancyDayInfo bilgi(
    DateTime d, {
    List<Pregnancy>? gebelikler,
    List<CareEvent> kalemler = const [],
  }) => PregnancyCalendar.dayInfo(
    pregnancies: gebelikler ?? [suren],
    events: kalemler,
    date: d,
  );

  group('süren gebelik', () {
    test('günün haftası; ileriki günlerde de', () {
      expect(bilgi(bugun).gestation, const GestationalAge(24, 2));
      expect(bilgi(gun(5)).gestation, const GestationalAge(25, 0));
      expect(bilgi(gun(-170)).gestation, const GestationalAge(0, 0));
      expect(bilgi(gun(-171)).gestation, isNull, reason: 'Başlamadan önce');
    });

    test('tahmini doğum günü işaretli; 42. haftadan sonrası boş', () {
      final edd = suren.estimatedDueDate;
      expect(bilgi(edd).isDueDate, isTrue);
      expect(bilgi(edd).gestation, const GestationalAge(40, 0));
      expect(
        bilgi(edd.add(const Duration(days: 14))).gestation,
        const GestationalAge(42, 0),
      );
      expect(bilgi(edd.add(const Duration(days: 15))).gestation, isNull);
    });
  });

  group('doğumla biten gebelik', () {
    final dogum = suren.ended(outcome: PregnancyOutcome.birth, at: gun(-10));

    test('doğumdan önce hafta, doğum günü, sonra lohusalık günü', () {
      final l = [dogum];
      expect(bilgi(gun(-11), gebelikler: l).gestation, isNotNull);
      final d = bilgi(gun(-10), gebelikler: l);
      expect(d.isBirthDay, isTrue);
      expect(d.postpartumDay, 0);
      expect(d.gestation, isNull, reason: 'Doğum günü gebelik değil');
      expect(bilgi(bugun, gebelikler: l).postpartumDay, 10);
      expect(
        bilgi(gun(32), gebelikler: l).postpartumDay,
        isNull,
        reason: '42 gün',
      );
    });

    test('lohusalık erken bitirildiyse sonrası boş', () {
      final l = [dogum.withPostpartumEndedAt(gun(-3))];
      expect(bilgi(gun(-4), gebelikler: l).postpartumDay, 6);
      expect(bilgi(gun(-3), gebelikler: l).postpartumDay, isNull);
    });
  });

  group('kayıpla biten gebelik takvimde anılmıyor', () {
    for (final sonuc in [
      PregnancyOutcome.miscarriage,
      PregnancyOutcome.ectopic,
      PregnancyOutcome.stillbirth,
      PregnancyOutcome.termination,
      PregnancyOutcome.undisclosed,
    ]) {
      test(sonuc.name, () {
        final g = suren.ended(outcome: sonuc, at: gun(-10));
        final randevu = CareEvent.custom(
          pregnancyId: g.id,
          title: 'Kontrol',
          scheduledAt: DateTime(bugun.year, bugun.month, bugun.day - 20, 10),
        );
        final d = bilgi(gun(-20), gebelikler: [g], kalemler: [randevu]);
        expect(d.gestation, isNull);
        expect(d.appointments, isEmpty);
        expect(bilgi(gun(-10), gebelikler: [g]).isBirthDay, isFalse);
      });
    }
  });

  test('randevular kendi gününde, saat sırasıyla', () {
    CareEvent r(String ad, int saat) => CareEvent.custom(
      pregnancyId: 'g1',
      title: ad,
      scheduledAt: DateTime(bugun.year, bugun.month, bugun.day + 3, saat),
    );
    final d = bilgi(gun(3), kalemler: [r('Öğleden sonra', 15), r('Sabah', 9)]);
    expect(d.appointments.map((e) => e.title), ['Sabah', 'Öğleden sonra']);
    expect(bilgi(gun(4), kalemler: [r('Sabah', 9)]).appointments, isEmpty);
  });

  test('gebelik yoksa boş', () {
    expect(
      identical(bilgi(bugun, gebelikler: const []), PregnancyDayInfo.none),
      isTrue,
    );
  });
}
