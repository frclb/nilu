import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/services/insights_service.dart';

PeriodLog _period(String id, DateTime start, {DateTime? end}) =>
    PeriodLog(id: id, startDate: start, endDate: end);

DailyLog _log(
  DateTime date, {
  List<String> symptoms = const [],
  List<String> moods = const [],
  String? flow,
  String? notes,
}) => DailyLog(
  date: date,
  symptoms: symptoms,
  moods: moods,
  flowIntensity: flow,
  notes: notes,
);

void main() {
  _regularityAndPhaseTests();

  group('cycleLengths', () {
    test('tek regl kaydından döngü uzunluğu çıkarılamaz', () {
      // Döngünün bitmesi için bir sonrakinin başlaması gerekir.
      final logs = [_period('1', DateTime(2026, 1, 1))];
      expect(InsightsService.cycleLengths(logs), isEmpty);
    });

    test('kayıt yokken boş döner', () {
      expect(InsightsService.cycleLengths(const []), isEmpty);
    });

    test('ardışık başlangıçlar arasındaki gün sayısını verir', () {
      final logs = [
        _period('1', DateTime(2026, 1, 1)),
        _period('2', DateTime(2026, 1, 29)), // 28 gün
        _period('3', DateTime(2026, 2, 27)), // 29 gün
      ];

      final points = InsightsService.cycleLengths(logs);

      expect(points.map((p) => p.lengthInDays).toList(), [28, 29]);
      expect(points.first.startDate, DateTime(2026, 1, 1));
    });

    test('kayıt sırası karışık olsa da tarihe göre hesaplar', () {
      final logs = [
        _period('3', DateTime(2026, 2, 27)),
        _period('1', DateTime(2026, 1, 1)),
        _period('2', DateTime(2026, 1, 29)),
      ];

      expect(
        InsightsService.cycleLengths(logs).map((p) => p.lengthInDays).toList(),
        [28, 29],
      );
    });

    test('takibe ara verilen dönem döngü sayılmaz', () {
      // Aradaki 6 aylık boşluk bir döngü değil, kayıt tutulmamış bir aralık.
      // Grafiğe girerse ölçeği bozar ve kullanıcı 180 günlük bir döngü
      // geçirmiş gibi görünür.
      final logs = [
        _period('1', DateTime(2026, 1, 1)),
        _period('2', DateTime(2026, 1, 29)),
        _period('3', DateTime(2026, 7, 28)), // ~180 gün
        _period('4', DateTime(2026, 8, 25)), // 28 gün
      ];

      expect(
        InsightsService.cycleLengths(logs).map((p) => p.lengthInDays).toList(),
        [28, 28],
      );
    });

    test('aynı reglin parçası gibi duran kayıtlar atlanır', () {
      final logs = [
        _period('1', DateTime(2026, 1, 1)),
        _period('2', DateTime(2026, 1, 4)), // 3 gün — döngü değil
        _period('3', DateTime(2026, 2, 1)),
      ];

      expect(
        InsightsService.cycleLengths(logs).map((p) => p.lengthInDays).toList(),
        [28],
      );
    });

    test('limit en yeni döngüleri tutar', () {
      final logs = [
        for (var i = 0; i < 10; i++)
          _period('$i', DateTime(2026, 1, 1).add(Duration(days: i * 28))),
      ];

      final points = InsightsService.cycleLengths(logs, limit: 3);

      expect(points.length, 3);
      expect(
        points.last.startDate,
        DateTime(2026, 1, 1).add(const Duration(days: 8 * 28)),
      );
    });
  });

  group('averageLength / variation', () {
    test('nokta yokken null döner — varsayılan uydurulmaz', () {
      expect(InsightsService.averageLength(const []), isNull);
      expect(InsightsService.variation(const []), isNull);
    });

    test('tek noktadan değişkenlik hesaplanmaz', () {
      final points = [
        CycleLengthPoint(startDate: DateTime(2026, 1, 1), lengthInDays: 28),
      ];
      expect(InsightsService.averageLength(points), 28);
      expect(InsightsService.variation(points), isNull);
    });

    test('ortalama yuvarlanır, değişkenlik uç farkıdır', () {
      final points = [
        CycleLengthPoint(startDate: DateTime(2026, 1, 1), lengthInDays: 26),
        CycleLengthPoint(startDate: DateTime(2026, 2, 1), lengthInDays: 29),
        CycleLengthPoint(startDate: DateTime(2026, 3, 1), lengthInDays: 32),
      ];

      expect(InsightsService.averageLength(points), 29);
      expect(InsightsService.variation(points), 6);
    });
  });

  group('symptomFrequencies', () {
    test('kayıt yokken boş döner', () {
      expect(InsightsService.symptomFrequencies(const []), isEmpty);
    });

    test('boş kayıtlar paydayı şişirmez', () {
      // Takvimde gün seçmek boş bir DailyLog üretebiliyor; bunlar sayılırsa
      // her yüzde yapay olarak düşük çıkar.
      final logs = [
        _log(DateTime(2026, 1, 1), symptoms: ['cramp']),
        _log(DateTime(2026, 1, 2)), // tamamen boş
        _log(DateTime(2026, 1, 3)), // tamamen boş
      ];

      final result = InsightsService.symptomFrequencies(logs);

      expect(result.single.code, 'cramp');
      expect(result.single.loggedDayCount, 1);
      expect(result.single.percentage, 100);
    });

    test('yalnızca ruh hâli girilen gün paydaya dahildir', () {
      final logs = [
        _log(DateTime(2026, 1, 1), symptoms: ['cramp']),
        _log(DateTime(2026, 1, 2), moods: ['happy']),
      ];

      expect(InsightsService.symptomFrequencies(logs).single.percentage, 50);
    });

    test('çoktan aza sıralar ve limiti uygular', () {
      final logs = [
        _log(DateTime(2026, 1, 1), symptoms: ['cramp', 'headache']),
        _log(DateTime(2026, 1, 2), symptoms: ['cramp', 'fatigue']),
        _log(DateTime(2026, 1, 3), symptoms: ['cramp']),
        _log(DateTime(2026, 1, 4), symptoms: ['headache', 'bloating']),
      ];

      final result = InsightsService.symptomFrequencies(logs, limit: 2);

      expect(result.map((f) => f.code).toList(), ['cramp', 'headache']);
      expect(result.first.dayCount, 3);
      expect(result.first.percentage, 75);
    });

    test('aynı semptom bir günde iki kez sayılmaz', () {
      final logs = [
        _log(DateTime(2026, 1, 1), symptoms: ['cramp', 'cramp']),
      ];

      expect(InsightsService.symptomFrequencies(logs).single.dayCount, 1);
    });

    test('eşit sayıda görülenler kararlı sırada gelir', () {
      // Sıralama kayıt sırasına bağlı olsaydı ekran her açılışta değişirdi.
      final forward = [
        _log(DateTime(2026, 1, 1), symptoms: ['acne']),
        _log(DateTime(2026, 1, 2), symptoms: ['bloating']),
      ];
      final reversed = [
        _log(DateTime(2026, 1, 2), symptoms: ['bloating']),
        _log(DateTime(2026, 1, 1), symptoms: ['acne']),
      ];

      expect(
        InsightsService.symptomFrequencies(forward).map((f) => f.code).toList(),
        InsightsService.symptomFrequencies(
          reversed,
        ).map((f) => f.code).toList(),
      );
    });

    test('since verilince eski kayıtlar dışlanır', () {
      final logs = [
        _log(DateTime(2025, 12, 1), symptoms: ['headache']),
        _log(DateTime(2026, 1, 5), symptoms: ['cramp']),
      ];

      final result = InsightsService.symptomFrequencies(
        logs,
        since: DateTime(2026, 1, 1),
      );

      expect(result.single.code, 'cramp');
      expect(result.single.loggedDayCount, 1);
    });
  });

  group('loggedDayCount', () {
    test('yalnızca dolu kayıtları sayar', () {
      final logs = [
        _log(DateTime(2026, 1, 1), symptoms: ['cramp']),
        _log(DateTime(2026, 1, 2), notes: 'yorgunum'),
        _log(DateTime(2026, 1, 3), flow: 'medium'),
        _log(DateTime(2026, 1, 4)),
      ];

      expect(InsightsService.loggedDayCount(logs), 3);
    });
  });
}

/// Bu bölüm sonradan eklenen düzenlilik ve evre analizini kapsar.
void _regularityAndPhaseTests() {
  CycleLengthPoint point(int length) =>
      CycleLengthPoint(startDate: DateTime(2026, 1, 1), lengthInDays: length);

  group('regularity', () {
    test('iki ölçümden az varsa değerlendirme yapılmaz', () {
      expect(InsightsService.regularity(const []), isNull);
      expect(InsightsService.regularity([point(28)]), isNull);
    });

    test('eşikler', () {
      expect(
        InsightsService.regularity([point(28), point(31)]),
        CycleRegularity.steady,
      );
      expect(
        InsightsService.regularity([point(28), point(35)]),
        CycleRegularity.typical,
      );
      expect(
        InsightsService.regularity([point(26), point(36)]),
        CycleRegularity.irregular,
      );
    });

    test('yalnızca düzensiz durumda hekim önerisi çıkar', () {
      expect(CycleRegularity.steady.shouldSuggestConsultation, isFalse);
      expect(CycleRegularity.typical.shouldSuggestConsultation, isFalse);
      expect(CycleRegularity.irregular.shouldSuggestConsultation, isTrue);
    });
  });

  group('symptomsByPhase', () {
    final periods = [
      PeriodLog(id: '1', startDate: DateTime(2026, 3, 1)),
      PeriodLog(id: '2', startDate: DateTime(2026, 3, 29)),
    ];

    test('regl kaydı yoksa boş döner', () {
      expect(
        InsightsService.symptomsByPhase(
          'cramp',
          dailyLogs: [
            DailyLog(date: DateTime(2026, 3, 2), symptoms: const ['cramp']),
          ],
          periodLogs: const [],
          periodLength: 5,
        ),
        isEmpty,
      );
    });

    test('günler doğru evreye yerleşir', () {
      final logs = [
        DailyLog(
          date: DateTime(2026, 3, 2),
          symptoms: const ['cramp'],
        ), // gün 2
        DailyLog(
          date: DateTime(2026, 3, 8),
          symptoms: const ['cramp'],
        ), // gün 8
        DailyLog(
          date: DateTime(2026, 3, 14),
          symptoms: const ['cramp'],
        ), // gün 14
        DailyLog(
          date: DateTime(2026, 3, 25),
          symptoms: const ['cramp'],
        ), // gün 25
      ];

      final counts = InsightsService.symptomsByPhase(
        'cramp',
        dailyLogs: logs,
        periodLogs: periods,
        periodLength: 5,
      );

      expect(counts[CyclePhase.menstruation], 1);
      expect(counts[CyclePhase.follicular], 1);
      expect(counts[CyclePhase.ovulation], 1);
      expect(counts[CyclePhase.luteal], 1);
    });

    test('ilk regl kaydından önceki günler sayılmaz', () {
      // Döngü günü hesaplanamıyor; bir yere zorla koymak veriyi bozar.
      final counts = InsightsService.symptomsByPhase(
        'cramp',
        dailyLogs: [
          DailyLog(date: DateTime(2026, 2, 20), symptoms: const ['cramp']),
        ],
        periodLogs: periods,
        periodLength: 5,
      );

      expect(counts, isEmpty);
    });

    test('takip arası uzun boşluktaki kayıt sayılmaz', () {
      final counts = InsightsService.symptomsByPhase(
        'cramp',
        dailyLogs: [
          // Son regl başlangıcından 200 gün sonra: bir döngüye ait değil.
          DailyLog(date: DateTime(2026, 10, 15), symptoms: const ['cramp']),
        ],
        periodLogs: periods,
        periodLength: 5,
      );

      expect(counts, isEmpty);
    });

    test('aranmayan belirti sayılmaz', () {
      final counts = InsightsService.symptomsByPhase(
        'headache',
        dailyLogs: [
          DailyLog(date: DateTime(2026, 3, 2), symptoms: const ['cramp']),
        ],
        periodLogs: periods,
        periodLength: 5,
      );

      expect(counts, isEmpty);
    });
  });

  group('dominantPhase', () {
    final periods = [PeriodLog(id: '1', startDate: DateTime(2026, 3, 1))];

    DailyLog cramp(int day) =>
        DailyLog(date: DateTime(2026, 3, day), symptoms: const ['cramp']);

    test('gözlem azken sonuç verilmez', () {
      // İki kayıttan "çoğunlukla şu evrede" demek yanıltıcı olur.
      expect(
        InsightsService.dominantPhase(
          'cramp',
          dailyLogs: [cramp(1), cramp(2)],
          periodLogs: periods,
          periodLength: 5,
        ),
        isNull,
      );
    });

    test('baskın evre yoksa sonuç verilmez', () {
      // 2 regl / 2 luteal: "çoğunlukla" diyebilmek için çoğunluk gerekiyor.
      expect(
        InsightsService.dominantPhase(
          'cramp',
          dailyLogs: [cramp(1), cramp(2), cramp(20), cramp(21)],
          periodLogs: periods,
          periodLength: 5,
        ),
        isNull,
      );
    });

    test('baskın evre ve payı döner', () {
      final result = InsightsService.dominantPhase(
        'cramp',
        dailyLogs: [cramp(1), cramp(2), cramp(3), cramp(20)],
        periodLogs: periods,
        periodLength: 5,
      );

      expect(result, isNotNull);
      expect(result!.phase, CyclePhase.menstruation);
      expect(result.count, 3);
      expect(result.total, 4);
    });

    test('kayıt yokken null döner', () {
      expect(
        InsightsService.dominantPhase(
          'cramp',
          dailyLogs: const [],
          periodLogs: periods,
          periodLength: 5,
        ),
        isNull,
      );
    });
  });
}
