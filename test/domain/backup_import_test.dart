import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/backup_import_service.dart';

/// JSON yedeğinin geri yüklenmesi.
///
/// Dışa aktarma "tam yedek (JSON)" diyordu ama geri yükleme yoktu.
///
/// Buradaki en önemli iddia **veri kaybı olmaması**: kullanıcı elindeki tek
/// yedeği yanlış zamanda açtığında aylarca kaydını kaybedebilirdi ve bu
/// geri alınamaz. Cihazdaki kayıt her zaman kazanıyor; içe aktarma
/// yalnızca eksik olanı ekliyor.
void main() {
  final today = DateTime(2026, 4, 1);

  PeriodLog period(int id, DateTime start, [DateTime? end]) =>
      PeriodLog(id: '$id', startDate: start, endDate: end);

  DailyLog daily(DateTime date, {String? flow, List<String>? symptoms}) =>
      DailyLog(
        date: date,
        flowIntensity: flow,
        symptoms: symptoms ?? const [],
      );

  String backup({
    List<PeriodLog> periods = const [],
    List<DailyLog> logs = const [],
  }) => jsonEncode({
    'exportedAt': today.toIso8601String(),
    'periodLogs': periods.map((l) => l.toMap()).toList(),
    'dailyLogs': logs.map((l) => l.toMap()).toList(),
  });

  ImportedData run(
    String json, {
    List<PeriodLog> periods = const [],
    List<DailyLog> logs = const [],
  }) => BackupImportService.merge(
    json: json,
    periodLogs: periods,
    dailyLogs: logs,
    today: today,
  );

  group('boş cihaza geri yükleme', () {
    test('dönemler ve günlük kayıtlar geliyor', () {
      final result = run(
        backup(
          periods: [period(1, DateTime(2026, 3, 1), DateTime(2026, 3, 5))],
          logs: [daily(DateTime(2026, 3, 2), flow: 'heavy')],
        ),
      );

      expect(result.report.succeeded, isTrue);
      expect(result.periodLogs, hasLength(1));
      expect(result.dailyLogs, hasLength(1));
      expect(result.report.periodsAdded, 1);
      expect(result.report.dailyAdded, 1);
    });

    test('alanlar korunuyor', () {
      // Yedek `toMap()` ile yazılıyor; okurken bir alan düşerse kullanıcı
      // geri yüklediğini sanır ama verisi eksik olur.
      final original = DailyLog(
        date: DateTime(2026, 3, 2),
        flowIntensity: 'medium',
        symptoms: const ['cramp'],
        moods: const ['irritable'],
        sexualActivity: 'protected',
        painLevel: 'severe',
        painLimitedActivity: true,
        painLocations: const ['pelvis'],
        painContexts: const ['intercourse'],
        notes: 'bir not',
      );

      final restored = run(backup(logs: [original])).dailyLogs.single;

      expect(restored.flowIntensity, 'medium');
      expect(restored.symptoms, ['cramp']);
      expect(restored.moods, ['irritable']);
      expect(restored.sexualActivity, 'protected');
      expect(restored.painLevel, 'severe');
      expect(restored.painLimitedActivity, isTrue);
      expect(restored.painLocations, ['pelvis']);
      expect(restored.painContexts, ['intercourse']);
      expect(restored.notes, 'bir not');
    });

    test('dönemin bitiş tarihi korunuyor', () {
      final restored = run(
        backup(
          periods: [period(1, DateTime(2026, 3, 1), DateTime(2026, 3, 5))],
        ),
      ).periodLogs.single;

      expect(restored.endDate, DateTime(2026, 3, 5));
    });
  });

  group('mevcut veri kazanıyor', () {
    test('aynı gündeki kayıt üzerine yazılmıyor', () {
      final mine = daily(DateTime(2026, 3, 2), flow: 'light');
      final result = run(
        backup(logs: [daily(DateTime(2026, 3, 2), flow: 'heavy')]),
        logs: [mine],
      );

      expect(result.dailyLogs, hasLength(1));
      expect(result.dailyLogs.single.flowIntensity, 'light');
      expect(result.report.dailyAdded, 0);
      expect(result.report.alreadyPresent, 1);
    });

    test('çakışan dönem eklenmiyor', () {
      // Yalnızca başlangıç tarihini karşılaştırmak yetmez: bir gün kayık
      // başlayan iki kayıt üst üste biner ve döngü uzunluğu bozulur.
      final result = run(
        backup(
          periods: [period(2, DateTime(2026, 3, 2), DateTime(2026, 3, 6))],
        ),
        periods: [period(1, DateTime(2026, 3, 1), DateTime(2026, 3, 5))],
      );

      expect(result.periodLogs, hasLength(1));
      expect(result.report.periodsAdded, 0);
      expect(result.report.alreadyPresent, 1);
    });

    test('çakışmayan dönem ekleniyor', () {
      // Karşı taraf: kural fazla geniş olsaydı hiçbir dönem geri gelmezdi.
      final result = run(
        backup(
          periods: [period(2, DateTime(2026, 2, 1), DateTime(2026, 2, 5))],
        ),
        periods: [period(1, DateTime(2026, 3, 1), DateTime(2026, 3, 5))],
      );

      expect(result.periodLogs, hasLength(2));
      expect(result.report.periodsAdded, 1);
    });

    test('hiçbir mevcut kayıt kaybolmuyor', () {
      final mine = [
        daily(DateTime(2026, 1, 5), flow: 'heavy'),
        daily(DateTime(2026, 2, 8), symptoms: const ['cramp']),
      ];

      final result = run(
        backup(logs: [daily(DateTime(2026, 3, 9), flow: 'light')]),
        logs: mine,
      );

      for (final log in mine) {
        expect(
          result.dailyLogs.any((l) => l.date == log.date),
          isTrue,
          reason: '${log.date} kayboldu',
        );
      }
    });
  });

  group('bozuk ve yabancı dosyalar', () {
    test('JSON olmayan dosya reddediliyor', () {
      final result = run('bu bir yedek değil');

      expect(result.report.failure, ImportFailure.unreadable);
      expect(result.report.totalAdded, 0);
    });

    test('başka bir uygulamanın JSON dosyası reddediliyor', () {
      final result = run(jsonEncode({'tracks': [], 'artist': 'x'}));

      expect(result.report.failure, ImportFailure.wrongFormat);
    });

    test('JSON dizisi reddediliyor', () {
      expect(run('[1,2,3]').report.failure, ImportFailure.wrongFormat);
    });

    test('boş yedek ayrı bildiriliyor', () {
      // Geçerli ama içi boş: "başarısız" demek yanlış olur, "hiçbir şey
      // eklenmedi" demek gerekiyor.
      expect(run(backup()).report.failure, ImportFailure.empty);
    });

    test('bozuk tek kayıt dosyanın tamamını düşürmüyor', () {
      final json = jsonEncode({
        'dailyLogs': [
          {'date': 'tarih değil'},
          daily(DateTime(2026, 3, 2), flow: 'heavy').toMap(),
        ],
      });

      final result = run(json);

      expect(result.report.succeeded, isTrue);
      expect(result.report.dailyAdded, 1);
      expect(result.report.invalid, 1);
    });

    test('bozuk kayıt sessizce yutulmuyor', () {
      final json = jsonEncode({
        'dailyLogs': [
          {'date': 'tarih değil'},
        ],
      });

      expect(run(json).report.invalid, 1);
    });
  });

  group('gelecek tarihli dönem elenir', () {
    test('yarın başlayan dönem alınmıyor', () {
      // Uygulamanın hiçbir yerinde üretilemiyor; saati yanlış bir cihazdan
      // gelen böyle bir kayıt bütün tahminleri bozardı.
      final result = run(
        backup(periods: [period(1, today.add(const Duration(days: 1)))]),
      );

      expect(result.periodLogs, isEmpty);
      expect(result.report.invalid, 1);
    });

    test('bugün başlayan dönem alınıyor', () {
      final result = run(backup(periods: [period(1, today)]));

      expect(result.periodLogs, hasLength(1));
    });
  });

  group('sıralama', () {
    test('dönemler tarihe göre sıralı dönüyor', () {
      final result = run(
        backup(
          periods: [
            period(2, DateTime(2026, 3, 1)),
            period(1, DateTime(2026, 1, 1)),
          ],
        ),
      );

      expect(
        result.periodLogs.map((l) => l.startDate),
        [DateTime(2026, 1, 1), DateTime(2026, 3, 1)],
      );
    });
  });
}
