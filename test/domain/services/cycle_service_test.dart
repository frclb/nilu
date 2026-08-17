import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/cycle_service.dart';

PeriodLog startedOn(int day, {int month = 1}) =>
    PeriodLog(id: '$month-$day', startDate: DateTime(2026, month, day));

void main() {
  final service = CycleService();

  group('calculateAverageCycleLength', () {
    test('log yokken varsayılanı döner', () {
      expect(service.calculateAverageCycleLength([]), 28);
      expect(service.calculateAverageCycleLength([], defaultLength: 31), 31);
    });

    test('tek log varken varsayılanı döner (aralık hesaplanamaz)', () {
      expect(
        service.calculateAverageCycleLength([startedOn(1)], defaultLength: 30),
        30,
      );
    });

    test('iki log varken aradaki gün farkını döner', () {
      final logs = [startedOn(1), startedOn(1, month: 2)]; // 1 Oca → 1 Şub
      expect(service.calculateAverageCycleLength(logs), 31);
    });

    test('yalnızca son 3 aralığın ortalamasını alır', () {
      // Aralıklar: 40, 28, 28, 28 → son 3'ün ortalaması 28
      final logs = [
        PeriodLog(id: 'a', startDate: DateTime(2026, 1, 1)),
        PeriodLog(id: 'b', startDate: DateTime(2026, 2, 10)),
        PeriodLog(id: 'c', startDate: DateTime(2026, 3, 10)),
        PeriodLog(id: 'd', startDate: DateTime(2026, 4, 7)),
        PeriodLog(id: 'e', startDate: DateTime(2026, 5, 5)),
      ];
      expect(service.calculateAverageCycleLength(logs), 28);
    });

    test('sırasız girdiyi önce sıralar', () {
      final ordered = [startedOn(1), startedOn(1, month: 2)];
      final shuffled = [startedOn(1, month: 2), startedOn(1)];

      expect(
        service.calculateAverageCycleLength(shuffled),
        service.calculateAverageCycleLength(ordered),
      );
    });

    test('girdi listesini değiştirmez', () {
      final logs = [startedOn(1, month: 2), startedOn(1)];
      service.calculateAverageCycleLength(logs);
      expect(logs.first.startDate, DateTime(2026, 2, 1));
    });
  });

  group('getLastPeriodStart', () {
    test('log yokken null döner', () {
      expect(service.getLastPeriodStart([]), isNull);
    });

    test('en geç başlangıcı döner (sıradan bağımsız)', () {
      final logs = [
        startedOn(10, month: 3),
        startedOn(1),
        startedOn(5, month: 2),
      ];
      expect(service.getLastPeriodStart(logs), DateTime(2026, 3, 10));
    });
  });
}
