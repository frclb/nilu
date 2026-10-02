import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/models/pregnancy_month.dart';

/// Gebelik ayları: haftaya göre ay, trimesterle uyum, takvim tarihleri.
void main() {
  test('her tamamlanan hafta tam olarak bir aya düşüyor', () {
    for (var w = 0; w <= 40; w++) {
      final aylar = PregnancyMonth.all.where(
        (m) => w >= m.fromWeek && w <= m.toWeek,
      );
      expect(aylar, hasLength(1), reason: '$w. hafta');
      expect(PregnancyMonth.of(GestationalAge(w, 3)), aylar.single);
    }
  });

  test('aylar trimesterlere oturuyor (ACOG sınırları)', () {
    // 1. trimester 13+6'ya, 2. trimester 27+6'ya kadar.
    for (var w = 0; w <= 40; w++) {
      final ay = PregnancyMonth.of(GestationalAge(w, 0));
      final beklenen = w < 14
          ? Trimester.first
          : w < 28
          ? Trimester.second
          : Trimester.third;
      expect(ay.trimester, beklenen, reason: '$w. hafta, ${ay.number}. ay');
    }
  });

  test('bilinen noktalar', () {
    expect(PregnancyMonth.of(const GestationalAge(0, 3)).number, 1);
    expect(PregnancyMonth.of(const GestationalAge(13, 6)).number, 3);
    expect(PregnancyMonth.of(const GestationalAge(14, 0)).number, 4);
    expect(PregnancyMonth.of(const GestationalAge(24, 1)).number, 6);
    expect(PregnancyMonth.of(const GestationalAge(36, 0)).number, 9);
    expect(
      PregnancyMonth.of(const GestationalAge(41, 2)).number,
      9,
      reason: 'Gecikmiş doğum 9. ayda kalıyor',
    );
  });

  test('ayların takvim tarihleri art arda, boşluksuz', () {
    final g = Pregnancy.fromDueDate(
      dueDate: DateTime(2027, 1, 21),
      confirmedAt: DateTime(2026, 6, 1),
      id: 'g1',
    );
    expect(PregnancyMonth.all.first.startIn(g), g.gestationStart);
    for (var i = 1; i < PregnancyMonth.all.length; i++) {
      final onceki = PregnancyMonth.all[i - 1].endIn(g);
      final bu = PregnancyMonth.all[i].startIn(g);
      expect(
        bu,
        DateTime(onceki.year, onceki.month, onceki.day + 1),
        reason: '${i + 1}. ay bir önceki ayın ertesi günü başlamalı',
      );
    }
    // 9. ay doğum tarihini (40+0) içeriyor.
    expect(PregnancyMonth.all.last.contains(g, g.estimatedDueDate), isTrue);
  });
}
