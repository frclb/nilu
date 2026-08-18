import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/data_export_service.dart';

/// Testlerde çeviri yerine anahtarın kendisi kullanılır: kontrol edilen şey
/// metnin çevirisi değil, dosyanın yapısı ve verinin doğruluğu.
String _tr(String key, {Map<String, String>? params}) {
  if (params == null || params.isEmpty) return key;
  final rendered = params.entries.map((e) => '${e.key}=${e.value}').join(',');
  return '$key($rendered)';
}

void main() {
  group('CSV', () {
    test('kayıt yokken yalnızca başlık satırı döner', () {
      final csv = DataExportService.buildCsv(
        dailyLogs: const [],
        periodLogs: const [],
      );

      expect(csv.split('\n').length, 1);
      expect(csv, startsWith('date,is_period,flow'));
    });

    test('boş kayıtlar satır üretmez', () {
      final csv = DataExportService.buildCsv(
        dailyLogs: [DailyLog(date: DateTime(2026, 3, 1))],
        periodLogs: const [],
      );

      expect(csv.split('\n').length, 1);
    });

    test('regl günleri işaretlenir', () {
      final csv = DataExportService.buildCsv(
        dailyLogs: [
          DailyLog(date: DateTime(2026, 3, 2), symptoms: const ['cramp']),
          DailyLog(date: DateTime(2026, 3, 9), symptoms: const ['acne']),
        ],
        periodLogs: [
          PeriodLog(
            id: '1',
            startDate: DateTime(2026, 3, 1),
            endDate: DateTime(2026, 3, 5),
          ),
        ],
      );

      final lines = csv.split('\n');
      expect(lines[1], contains('"2026-03-02","yes"'));
      expect(lines[2], contains('"2026-03-09","no"'));
    });

    test('nottaki virgül sütunları kaydırmaz', () {
      // Alanlar tırnaklanmasa "yorgun, bitkin" iki sütun olurdu.
      final csv = DataExportService.buildCsv(
        dailyLogs: [
          DailyLog(date: DateTime(2026, 3, 1), notes: 'yorgun, bitkin'),
        ],
        periodLogs: const [],
      );

      expect(csv, contains('"yorgun, bitkin"'));
      expect(csv.split('\n')[1].split('","').length, 7);
    });

    test('nottaki tırnak ikilenir', () {
      final csv = DataExportService.buildCsv(
        dailyLogs: [
          DailyLog(date: DateTime(2026, 3, 1), notes: 'çok "kötü" gün'),
        ],
        periodLogs: const [],
      );

      expect(csv, contains('"çok ""kötü"" gün"'));
    });

    test('satırlar tarihe göre sıralanır', () {
      final csv = DataExportService.buildCsv(
        dailyLogs: [
          DailyLog(date: DateTime(2026, 3, 9), symptoms: const ['acne']),
          DailyLog(date: DateTime(2026, 3, 2), symptoms: const ['cramp']),
        ],
        periodLogs: const [],
      );

      final lines = csv.split('\n');
      expect(lines[1], startsWith('"2026-03-02"'));
      expect(lines[2], startsWith('"2026-03-09"'));
    });

    test('tarih biçimi dilden bağımsızdır', () {
      final csv = DataExportService.buildCsv(
        dailyLogs: [
          DailyLog(date: DateTime(2026, 1, 5), symptoms: const ['cramp']),
        ],
        periodLogs: const [],
      );

      // ISO 8601: tablo programları ve doktorlar aynı şeyi okur.
      expect(csv, contains('"2026-01-05"'));
    });
  });

  group('özet metni', () {
    test('veri yokken bile geçerli bir belge üretir', () {
      final summary = DataExportService.buildSummary(
        periodLogs: const [],
        dailyLogs: const [],
        generatedAt: DateTime(2026, 8, 18),
        translate: _tr,
      );

      expect(summary, contains('export_title'));
      expect(summary, contains('export_no_cycles'));
      expect(summary, contains('export_no_logs'));
    });

    test('döngü uzunlukları ve ortalama yazılır', () {
      final summary = DataExportService.buildSummary(
        periodLogs: [
          PeriodLog(id: '1', startDate: DateTime(2026, 1, 1)),
          PeriodLog(id: '2', startDate: DateTime(2026, 1, 29)),
          PeriodLog(id: '3', startDate: DateTime(2026, 2, 26)),
        ],
        dailyLogs: const [],
        generatedAt: DateTime(2026, 3, 1),
        translate: _tr,
      );

      expect(summary, contains('export_average(days=28)'));
      expect(summary, contains('2026-01-01 — 28'));
    });

    test('kayıtlar en yeniden eskiye sıralanır', () {
      final summary = DataExportService.buildSummary(
        periodLogs: const [],
        dailyLogs: [
          DailyLog(date: DateTime(2026, 3, 1), symptoms: const ['cramp']),
          DailyLog(date: DateTime(2026, 3, 5), symptoms: const ['acne']),
        ],
        generatedAt: DateTime(2026, 3, 6),
        translate: _tr,
      );

      expect(
        summary.indexOf('2026-03-05'),
        lessThan(summary.indexOf('2026-03-01')),
      );
    });

    test('boş kayıtlar belgeye girmez', () {
      final summary = DataExportService.buildSummary(
        periodLogs: const [],
        dailyLogs: [DailyLog(date: DateTime(2026, 3, 1))],
        generatedAt: DateTime(2026, 3, 2),
        translate: _tr,
      );

      expect(summary, contains('export_no_logs'));
      expect(summary, isNot(contains('2026-03-01\n')));
    });

    test('not metni belgeye aynen geçer', () {
      final summary = DataExportService.buildSummary(
        periodLogs: const [],
        dailyLogs: [
          DailyLog(date: DateTime(2026, 3, 1), notes: 'ağrı kesici aldım'),
        ],
        generatedAt: DateTime(2026, 3, 2),
        translate: _tr,
      );

      expect(summary, contains('ağrı kesici aldım'));
    });
  });
}
