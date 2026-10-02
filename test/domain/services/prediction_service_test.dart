import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/calendar_day.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

PeriodLog completed(String id, DateTime start, DateTime end) =>
    PeriodLog(id: id, startDate: start, endDate: end);

void main() {
  _chainTests();

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
      expect(info.predictedNextPeriod!.daysSince(info.ovulationDay!), 14);
    });

    test('14 gün kuralı 28 dışındaki döngülerde de geçerlidir', () {
      final info = service.getCycleInfo(logs, userCycleLength: 31);
      expect(info.predictedNextPeriod!.daysSince(info.ovulationDay!), 14);
    });

    test('doğurganlık penceresi yumurtlama -5 / +1 gündür', () {
      final info = service.getCycleInfo(logs, userCycleLength: 28);
      expect(info.fertileWindowStart, DateTime(2026, 1, 10));
      expect(info.fertileWindowEnd, DateTime(2026, 1, 16));
    });

    test('ileri tahminler sonraki reglden başlar ve artan sıradadır', () {
      // Bu test eskiden `hasLength(3)` ve "ilk tahmin sonraki reglden
      // SONRA" diyordu. İkisi de kusuru sabitliyordu: zincir sonraki regli
      // atlıyordu (o döngünün doğurganlık penceresi hiç üretilmiyordu) ve
      // üç döngüden sonrası boş kalıyordu.
      final info = service.getCycleInfo(logs, userCycleLength: 28);
      expect(
        info.futurePredictions,
        hasLength(PredictionService.forecastCycleCount),
      );

      final starts = info.futurePredictions.map((p) => p.startDate).toList();
      expect(starts.first, info.predictedNextPeriod);
      for (var i = 0; i < starts.length - 1; i++) {
        expect(starts[i + 1].isAfter(starts[i]), isTrue);
      }
    });

    test('her ileri tahminde yumurtlama kendi döngüsünün içindedir', () {
      // Eski hâli `startDate - ovulationDay == 14` bekliyordu, yani
      // yumurtlamanın döngü başlangıcından ÖNCE olmasını. Doğrusu: o
      // döngünün başlangıcından `uzunluk - 14` gün sonra.
      final info = service.getCycleInfo(logs, userCycleLength: 28);
      for (final p in info.futurePredictions) {
        expect(
          p.ovulationDay!.daysSince(p.startDate),
          info.averageCycleLength - PredictionService.lutealPhaseDays,
        );
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

/// Tahmin zincirinin tutarlılığı.
///
/// Kullanıcı takvimi değiştirdiğinde doğurganlık penceresinin kayması
/// buradaki üç kusurdan geliyordu.
void _chainTests() {
  PeriodLog log(String id, int month, int day) =>
      PeriodLog(id: id, startDate: DateTime(2026, month, day));

  /// Ortalaması 30 gün olan gerçekçi bir geçmiş (33/28/28).
  final gecmis = [
    log('1', 5, 20),
    log('2', 6, 22),
    log('3', 7, 20),
    log('4', 8, 17),
  ];

  group('tahmin zinciri', () {
    test('regl aralıkları baştan sona aynı uzunlukta', () {
      // Regresyon: mevcut döngü hesaplanan ortalamayı (30), gelecek döngüler
      // ise kullanıcı ayarını (28) kullanıyordu. Kullanıcı takvimde önce 30
      // günlük, sonra aniden 28 günlük aralıklar görüyordu.
      final info = PredictionService().getCycleInfo(
        gecmis,
        userCycleLength: 28,
      );

      final baslangiclar = info.futurePredictions
          .map((p) => p.startDate)
          .toList();
      expect(baslangiclar.first, info.predictedNextPeriod);

      for (var i = 0; i < baslangiclar.length - 1; i++) {
        expect(
          baslangiclar[i + 1].daysSince(baslangiclar[i]),
          info.averageCycleLength,
          reason: '${i + 1}. ve ${i + 2}. tahmin arası',
        );
      }
    });

    test('her tahmin döngüsünün yumurtlaması kendi döngüsündedir', () {
      // Regresyon: yumurtlama `başlangıç - 14` olarak hesaplanıyordu, yani
      // bir önceki döngüye aitti. Kayıt içinde başlangıç ile yumurtlama
      // birbirine uymuyordu.
      final info = PredictionService().getCycleInfo(
        gecmis,
        userCycleLength: 28,
      );

      for (final p in info.futurePredictions) {
        final gun = p.ovulationDay!.daysSince(p.startDate);
        expect(
          gun,
          info.averageCycleLength - 14,
          reason: '${p.startDate} döngüsünün yumurtlaması',
        );
        expect(gun, greaterThan(0), reason: 'yumurtlama döngü içinde olmalı');
      }
    });

    test('tahmin edilen her reglin doğurganlık penceresi vardır', () {
      // Regresyon: son tahmin döngüsünün yumurtlaması hiç üretilmiyordu.
      final info = PredictionService().getCycleInfo(
        gecmis,
        userCycleLength: 28,
      );

      for (final p in info.futurePredictions) {
        expect(p.ovulationDay, isNotNull, reason: '${p.startDate}');
        expect(p.fertileStart, isNotNull, reason: '${p.startDate}');
        expect(p.fertileEnd, isNotNull, reason: '${p.startDate}');
      }
    });

    test('sonraki aylar için yeterli tahmin üretilir', () {
      // Takvimde ileri sayfalanabiliyor; birkaç ay sonrası boş kalmamalı.
      final info = PredictionService().getCycleInfo(
        gecmis,
        userCycleLength: 28,
      );

      final son = info.futurePredictions.last.startDate;
      expect(
        son.daysSince(info.lastPeriodStart!),
        greaterThanOrEqualTo(330),
        reason: 'en az bir yıl ileri tahmin',
      );
    });

    test('araya karışan tek gün doğurganlığı kaydırmaz', () {
      // Kullanıcının bildirdiği durum: takvimde bir gün işaretlemek
      // doğurganlık penceresini bir hafta öteliyordu.
      final temiz = PredictionService().getCycleInfo(
        gecmis,
        userCycleLength: 28,
      );

      final kirli = PredictionService().getCycleInfo([
        ...gecmis,
        log('5', 8, 20), // reglin bitiminden 3 gün sonra tek gün
      ], userCycleLength: 28);

      expect(kirli.averageCycleLength, temiz.averageCycleLength);
      expect(
        kirli.ovulationDay!.daysSince(kirli.lastPeriodStart!),
        temiz.ovulationDay!.daysSince(temiz.lastPeriodStart!),
      );
    });
  });
}
