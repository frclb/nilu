import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/clinical_summary.dart';

/// Ağrının yeri ve bağlamı.
///
/// Şiddet tek başına bir tablo çizmiyordu: her ay bir gün alt karnı ağrıyan
/// kullanıcıyla ağrısı ilişkide ve tuvalette de olan kullanıcı aynı
/// görünüyordu. İkincisi NICE'ın endometriozisten şüphelenmek için saydığı
/// bulguları taşıyor.
void main() {
  DailyLog log(
    int day, {
    String? level,
    List<String> locations = const [],
    List<String> contexts = const [],
  }) => DailyLog(
    date: DateTime(2026, 3, day),
    painLevel: level,
    painLocations: locations,
    painContexts: contexts,
  );

  group('kalıcılık', () {
    test('yer ve bağlam kaydedilip geri okunuyor', () {
      final original = log(
        1,
        level: 'severe',
        locations: const ['abdomen', 'legs'],
        contexts: const ['intercourse'],
      );

      final restored = DailyLog.fromJson(original.toJson());

      expect(restored.painLocations, ['abdomen', 'legs']);
      expect(restored.painContexts, ['intercourse']);
      expect(restored.painLevel, 'severe');
    });

    test('eski kayıtlar boş listeyle okunuyor', () {
      // Alan eklenmeden önce yazılmış kayıtlar hâlâ okunabilmeli.
      final restored = DailyLog.fromMap({
        'date': DateTime(2026, 3, 1).toIso8601String(),
        'painLevel': 'mild',
      });

      expect(restored.painLocations, isEmpty);
      expect(restored.painContexts, isEmpty);
    });

    test('tanınmayan kod düşüyor', () {
      final restored = DailyLog.fromMap({
        'date': DateTime(2026, 3, 1).toIso8601String(),
        'painLocations': ['abdomen', 'kolum'],
        'painContexts': ['dans_ederken'],
      });

      expect(restored.painLocations, ['abdomen']);
      expect(restored.painContexts, isEmpty);
    });
  });

  group('klinik özet', () {
    ClinicalSummary summarize(List<DailyLog> logs) => ClinicalSummary.build(
      periodLogs: [
        PeriodLog(
          id: 'p',
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 5),
        ),
      ],
      dailyLogs: logs,
      breaks: const [],
    );

    test('gün sayıları bölgeye göre toplanıyor', () {
      final summary = summarize([
        log(1, level: 'moderate', locations: const ['abdomen']),
        log(2, level: 'severe', locations: const ['abdomen', 'lower_back']),
        log(3, level: 'mild', locations: const ['lower_back']),
      ]);

      final counts = {
        for (final f in summary.painLocationDays) f.code: f.dayCount,
      };
      expect(counts, {'abdomen': 2, 'lower_back': 2});
    });

    test('hiç kaydedilmemiş kod listede yok', () {
      final summary = summarize([
        log(1, locations: const ['abdomen']),
      ]);

      expect(summary.painLocationDays.map((f) => f.code), ['abdomen']);
    });

    test('en çok kaydedilen başta', () {
      final summary = summarize([
        log(1, contexts: const ['bowel']),
        log(2, contexts: const ['bowel', 'intercourse']),
        log(3, contexts: const ['bowel']),
      ]);

      expect(summary.painContextDays.first.code, 'bowel');
      expect(summary.painContextDays.first.dayCount, 3);
    });

    test('eşit sayılar sözlük sırasıyla çözülüyor', () {
      // `List.sort` Dart'ta kararlı değil; eşitlik açıkça çözülmezse aynı
      // veri iki farklı sırada çıkabilir. Hekime gösterilen bir çıktıda
      // bu olmamalı.
      final first = summarize([
        log(1, contexts: const ['urination', 'intercourse']),
      ]).painContextDays.map((f) => f.code).toList();
      final second = summarize([
        log(1, contexts: const ['intercourse', 'urination']),
      ]).painContextDays.map((f) => f.code).toList();

      expect(first, second);
      expect(
        first.indexOf('intercourse'),
        lessThan(first.indexOf('urination')),
        reason: 'sözlük sırası korunmalı',
      );
    });

    test('ağrı kaydı yoksa listeler boş', () {
      expect(summarize([log(1)]).painLocationDays, isEmpty);
      expect(summarize([log(1)]).painContextDays, isEmpty);
    });
  });

  group('sözlük', () {
    test('NICE bulguları bağlam listesinde', () {
      // Üçü de "endometriozisten şüphelen" maddelerinde geçiyor; listeden
      // biri düşerse o bulgu hiç kaydedilemez hâle gelir.
      expect(
        LogVocabulary.painContexts,
        containsAll(['intercourse', 'bowel', 'urination']),
      );
    });

    test('kodların hepsi benzersiz', () {
      expect(
        LogVocabulary.painLocations.toSet(),
        hasLength(LogVocabulary.painLocations.length),
      );
      expect(
        LogVocabulary.painContexts.toSet(),
        hasLength(LogVocabulary.painContexts.length),
      );
    });
  });
}
