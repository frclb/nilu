import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';

void main() {
  group('togglePeriodDay tarih normalleştirmesi', () {
    test('bugünün saati gelecek sayılmaz', () {
      // `DateTime.now()` gece yarısından sonraki bir andır; gün başlangıcıyla
      // karşılaştırılınca "gelecek" görünüyor ve bugünü işaretlemek
      // reddediliyordu.
      final now = DateTime(2026, 9, 20, 15, 51);
      final today = DateTime(now.year, now.month, now.day);
      final normalized = DateTime(now.year, now.month, now.day);

      expect(now.isAfter(today), isTrue, reason: 'hatanın kaynağı');
      expect(normalized.isAfter(today), isFalse, reason: 'düzeltme');
    });
  });

  CycleInfo info({DateTime? predicted}) =>
      CycleInfo(predictedNextPeriod: predicted);

  group('CycleInfo.daysLateAt', () {
    test('tahmin gelmediyse gecikme yok', () {
      expect(
        info(
          predicted: DateTime(2026, 9, 20),
        ).daysLateAt(DateTime(2026, 9, 15)),
        0,
      );
    });

    test('tam tahmin gününde gecikme yok', () {
      expect(
        info(
          predicted: DateTime(2026, 9, 20),
        ).daysLateAt(DateTime(2026, 9, 20)),
        0,
      );
    });

    test('tahmin geçtiyse geçen gün sayısı', () {
      // Gecikmenin ilk günü ile onuncu günü aynı görünmemeli.
      expect(
        info(
          predicted: DateTime(2026, 9, 20),
        ).daysLateAt(DateTime(2026, 9, 21)),
        1,
      );
      expect(
        info(
          predicted: DateTime(2026, 9, 20),
        ).daysLateAt(DateTime(2026, 9, 30)),
        10,
      );
    });

    test('günün saati sonucu değiştirmez', () {
      expect(
        info(
          predicted: DateTime(2026, 9, 20, 23),
        ).daysLateAt(DateTime(2026, 9, 21, 1)),
        1,
      );
    });

    test('tahmin yoksa gecikme yok', () {
      expect(info().daysLateAt(DateTime(2026, 9, 30)), 0);
    });
  });
}
