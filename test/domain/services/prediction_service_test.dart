import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

PeriodLog completed(String id, DateTime start, DateTime end) =>
    PeriodLog(id: id, startDate: start, endDate: end);

void main() {
  final service = PredictionService();

  group('veri yokken', () {
    test('kullanıcı ayarlarını döner, tahmin üretmez', () {
      final info = service.getCycleInfo(
        [],
        userCycleLength: 30,
        userPeriodLength: 6,
      );

      expect(info.averageCycleLength, 30);
      expect(info.averagePeriodLength, 6);
      expect(info.lastPeriodStart, isNull);
      expect(info.predictedNextPeriod, isNull);
      expect(info.futurePredictions, isEmpty);
    });
  });

  group('tek log ile tahmin', () {
    final logs = [completed('a', DateTime(2026, 1, 1), DateTime(2026, 1, 5))];

    test('sonraki regl bir döngü uzunluğu sonrasıdır', () {
      final info = service.getCycleInfo(logs, userCycleLength: 28);
      expect(info.predictedNextPeriod, DateTime(2026, 1, 29));
    });

    test('yumurtlama sonraki reglden 14 gün öncedir', () {
      final info = service.getCycleInfo(logs, userCycleLength: 28);
      expect(info.ovulationDay, DateTime(2026, 1, 15));
      expect(
        info.predictedNextPeriod!.difference(info.ovulationDay!).inDays,
        14,
      );
    });

    test('14 gün kuralı 28 dışındaki döngülerde de geçerlidir', () {
      final info = service.getCycleInfo(logs, userCycleLength: 31);
      expect(
        info.predictedNextPeriod!.difference(info.ovulationDay!).inDays,
        14,
      );
    });

    test('doğurganlık penceresi yumurtlama -5 / +1 gündür', () {
      final info = service.getCycleInfo(logs, userCycleLength: 28);
      expect(info.fertileWindowStart, DateTime(2026, 1, 10));
      expect(info.fertileWindowEnd, DateTime(2026, 1, 16));
    });

    test('3 ileri döngü tahmini üretir ve tarihler artan sıradadır', () {
      final info = service.getCycleInfo(logs, userCycleLength: 28);
      expect(info.futurePredictions, hasLength(3));

      final starts = info.futurePredictions.map((p) => p.startDate).toList();
      expect(starts[0].isAfter(info.predictedNextPeriod!), isTrue);
      expect(starts[1].isAfter(starts[0]), isTrue);
      expect(starts[2].isAfter(starts[1]), isTrue);
    });

    test('her ileri tahminde de yumurtlama regl öncesi 14 gündür', () {
      final info = service.getCycleInfo(logs, userCycleLength: 28);
      for (final p in info.futurePredictions) {
        expect(p.startDate.difference(p.ovulationDay!).inDays, 14);
      }
    });
  });

  group('ortalama regl süresi', () {
    test('devam eden dönem ortalamaya katılmaz', () {
      // Regresyon: devam eden dönem eskiden sabit 5 gün sayılıp ortalamayı
      // kullanıcının gerçek verisinden saptırıyordu.
      final logs = [
        completed('a', DateTime(2026, 1, 1), DateTime(2026, 1, 8)), // 8 gün
        completed('b', DateTime(2026, 2, 1), DateTime(2026, 2, 8)), // 8 gün
        PeriodLog(id: 'c', startDate: DateTime(2026, 3, 1)), // devam ediyor
      ];

      final info = service.getCycleInfo(logs, userPeriodLength: 5);
      expect(info.averagePeriodLength, 8);
    });

    test('tamamlanmış dönem yoksa kullanıcı ayarına düşer', () {
      final logs = [PeriodLog(id: 'a', startDate: DateTime(2026, 3, 1))];
      final info = service.getCycleInfo(logs, userPeriodLength: 6);
      expect(info.averagePeriodLength, 6);
    });
  });

  group('settingsUpdatedAt kuralı', () {
    // İki log arası 40 gün → hesaplanan ortalama 40.
    final logs = [
      completed('a', DateTime(2026, 1, 1), DateTime(2026, 1, 5)),
      completed('b', DateTime(2026, 2, 10), DateTime(2026, 2, 14)),
    ];

    test('son regl ayar değişikliğinden sonraysa yeni ayar kullanılır', () {
      final info = service.getCycleInfo(
        logs,
        userCycleLength: 28,
        settingsUpdatedAt: DateTime(2026, 2, 1), // son regl (10 Şub) sonrası
      );
      expect(info.averageCycleLength, 28);
    });

    test(
      'son regl ayar değişikliğinden önceyse hesaplanan ortalama kullanılır',
      () {
        final info = service.getCycleInfo(
          logs,
          userCycleLength: 28,
          settingsUpdatedAt: DateTime(
            2026,
            3,
            1,
          ), // son reglden sonra ayarlandı
        );
        expect(info.averageCycleLength, 40);
      },
    );

    test('ayar tarihi yoksa hesaplanan ortalama kullanılır', () {
      final info = service.getCycleInfo(logs, userCycleLength: 28);
      expect(info.averageCycleLength, 40);
    });
  });

  group('CycleInfo takvim yardımcıları', () {
    final info = service.getCycleInfo(
      [completed('a', DateTime(2026, 1, 1), DateTime(2026, 1, 5))],
      userCycleLength: 28,
      userPeriodLength: 5,
    );

    test('tahmini regl günleri işaretlenir', () {
      expect(info.isPredictedPeriod(DateTime(2026, 1, 29)), isTrue);
      expect(info.isPredictedPeriod(DateTime(2026, 2, 2)), isTrue); // +4 gün
      expect(info.isPredictedPeriod(DateTime(2026, 2, 3)), isFalse);
    });

    test('doğurganlık penceresi işaretlenir', () {
      expect(info.isFertile(DateTime(2026, 1, 10)), isTrue);
      expect(info.isFertile(DateTime(2026, 1, 16)), isTrue);
      expect(info.isFertile(DateTime(2026, 1, 17)), isFalse);
    });

    test('yumurtlama günü işaretlenir', () {
      expect(info.isOvulationDay(DateTime(2026, 1, 15)), isTrue);
      expect(info.isOvulationDay(DateTime(2026, 1, 16)), isFalse);
    });
  });

  group('faz belirleme', () {
    final info = service.getCycleInfo(
      [completed('a', DateTime(2026, 1, 1), DateTime(2026, 1, 5))],
      userCycleLength: 28,
      userPeriodLength: 5,
    );

    test('regl günleri menstruation fazıdır', () {
      expect(info.getPhaseForDay(1), CyclePhase.menstruation);
      expect(info.getPhaseForDay(5), CyclePhase.menstruation);
    });

    test('yumurtlama penceresi (gün 12-15) ovulation fazıdır', () {
      expect(info.getPhaseForDay(12), CyclePhase.ovulation);
      expect(info.getPhaseForDay(15), CyclePhase.ovulation);
    });

    test('arada kalan günler foliküler fazdır', () {
      expect(info.getPhaseForDay(8), CyclePhase.follicular);
    });

    test('yumurtlama sonrası luteal fazdır', () {
      expect(info.getPhaseForDay(20), CyclePhase.luteal);
    });

    test('geçersiz gün unknown döner', () {
      expect(info.getPhaseForDay(0), CyclePhase.unknown);
    });
  });
}
