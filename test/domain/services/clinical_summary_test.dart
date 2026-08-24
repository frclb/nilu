import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/clinical_summary.dart';
import 'package:period_tracker/domain/services/cycle_alert.dart';

PeriodLog period(int id, DateTime start, {int? days}) => PeriodLog(
  id: '$id',
  startDate: start,
  endDate: days == null ? null : start.add(Duration(days: days - 1)),
);

void main() {
  group('ClinicalSummary', () {
    test('veri yoksa hiçbir sayı uydurulmaz', () {
      final s = ClinicalSummary.build(periodLogs: [], dailyLogs: []);
      expect(s.hasData, isFalse);
      expect(s.observedCycles, 0);
      expect(s.averageCycleDays, isNull);
      expect(s.shortestCycleDays, isNull);
      expect(s.longestCycleDays, isNull);
      expect(s.averagePeriodDays, isNull);
      expect(s.alerts, isEmpty);
    });

    test('gözlenmiş döngüleri ve uçları hesaplar', () {
      final logs = [
        period(1, DateTime(2026, 1, 1), days: 5),
        period(2, DateTime(2026, 1, 29), days: 5), // 28
        period(3, DateTime(2026, 2, 24), days: 4), // 26
        period(4, DateTime(2026, 3, 26), days: 6), // 30
      ];
      final s = ClinicalSummary.build(periodLogs: logs, dailyLogs: []);
      expect(s.observedCycles, 3);
      expect(s.shortestCycleDays, 26);
      expect(s.longestCycleDays, 30);
      expect(s.variationDays, 4);
      expect(s.averageCycleDays, 28);
    });

    test('devam eden dönem regl ortalamasına katılmaz', () {
      // Bitmemiş bir dönemin gerçek uzunluğu bilinmiyor.
      final logs = [
        period(1, DateTime(2026, 1, 1), days: 4),
        period(2, DateTime(2026, 1, 29), days: 6),
        period(3, DateTime(2026, 2, 26)), // devam ediyor
      ];
      final s = ClinicalSummary.build(periodLogs: logs, dailyLogs: []);
      expect(s.averagePeriodDays, 5);
      expect(s.longestPeriodDays, 6);
    });

    test('ağrı günlerini ayrı ayrı sayar', () {
      final logs = [
        DailyLog(date: DateTime(2026, 1, 1), painLevel: 'mild'),
        DailyLog(
          date: DateTime(2026, 1, 2),
          painLevel: 'severe',
          painLimitedActivity: true,
        ),
        DailyLog(
          date: DateTime(2026, 1, 3),
          painLevel: 'severe',
          painLimitedActivity: true,
        ),
        DailyLog(date: DateTime(2026, 1, 4), moods: ['calm']),
      ];
      final s = ClinicalSummary.build(periodLogs: [], dailyLogs: logs);
      expect(s.painDays, 3);
      expect(s.severePainDays, 2);
      expect(s.painLimitedDays, 2);
    });

    test('yoğun akış günlerini sayar', () {
      final logs = [
        DailyLog(date: DateTime(2026, 1, 1), flowIntensity: 'heavy'),
        DailyLog(date: DateTime(2026, 1, 2), flowIntensity: 'heavy'),
        DailyLog(date: DateTime(2026, 1, 3), flowIntensity: 'light'),
      ];
      final s = ClinicalSummary.build(periodLogs: [], dailyLogs: logs);
      expect(s.heavyFlowDays, 2);
    });

    test('en sık üç belirtiyi verir', () {
      final logs = [
        for (var i = 0; i < 5; i++)
          DailyLog(
            date: DateTime(2026, 1, 1).add(Duration(days: i)),
            symptoms: const ['cramp', 'headache', 'bloating', 'acne'],
          ),
      ];
      final s = ClinicalSummary.build(periodLogs: [], dailyLogs: logs);
      expect(s.topSymptoms.length, 3);
    });

    test('kayıt aralığını verir', () {
      final logs = [
        DailyLog(date: DateTime(2026, 3, 10), symptoms: const ['cramp']),
        DailyLog(date: DateTime(2026, 1, 5), symptoms: const ['cramp']),
        // İçeriği olmayan gün aralığı genişletmemeli.
        DailyLog(date: DateTime(2026, 6, 1)),
      ];
      final s = ClinicalSummary.build(periodLogs: [], dailyLogs: logs);
      expect(s.firstLoggedDay, DateTime(2026, 1, 5));
      expect(s.lastLoggedDay, DateTime(2026, 3, 10));
    });

    test('eşik dışı döngülerde uyarı taşınır', () {
      final logs = [
        period(1, DateTime(2026, 1, 1), days: 5),
        period(2, DateTime(2026, 1, 21), days: 5), // 20
        period(3, DateTime(2026, 2, 10), days: 5), // 20
        period(4, DateTime(2026, 3, 1), days: 5), // 19
      ];
      final s = ClinicalSummary.build(periodLogs: logs, dailyLogs: []);
      expect(s.alerts, contains(CycleAlert.consistentlyShort));
    });
  });
}
