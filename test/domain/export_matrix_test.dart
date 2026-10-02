import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/clinical_summary.dart';
import 'package:period_tracker/domain/services/data_export_service.dart';

/// Dışa aktarılan belgenin denetimi.
///
/// Bu, hekimin eline geçen tek çıktı. Ekrandaki bir eksiklik kullanıcıya
/// görünür; buradaki eksiklik görünmez — kullanıcı kaydettiğini sanır,
/// hekim de olmayan bir şeyi değerlendiremez. O yüzden asıl iddia şu:
/// **kullanıcının girdiği hiçbir şey sessizce düşmemeli.**
void main() {
  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;

  String translate(String key, {Map<String, String>? params}) {
    var text = dictionary[key] as String? ?? key;
    params?.forEach((k, v) => text = text.replaceAll('{$k}', v));
    return text;
  }

  final generatedAt = DateTime(2026, 4, 1, 12);

  String summaryOf(List<DailyLog> logs, {List<PeriodLog> periods = const []}) =>
      DataExportService.buildSummary(
        periodLogs: periods,
        dailyLogs: logs,
        generatedAt: generatedAt,
        translate: translate,
        breaks: const [],
      );

  String csvOf(List<DailyLog> logs, {List<PeriodLog> periods = const []}) =>
      DataExportService.buildCsv(dailyLogs: logs, periodLogs: periods);

  group('kaydedilen hiçbir alan düşmüyor', () {
    // Her alan **tek başına** girilmiş bir günle sınanıyor: birleşik bir
    // kayıtta eksik alan, diğer alanlar günü ayakta tuttuğu için fark
    // edilmez.
    final cases = <String, DailyLog>{
      'yalnızca akış': DailyLog(
        date: DateTime(2026, 3, 2),
        flowIntensity: 'medium',
      ),
      'yalnızca lekelenme': DailyLog(
        date: DateTime(2026, 3, 3),
        flowIntensity: LogVocabulary.spotting,
      ),
      'yalnızca belirti': DailyLog(
        date: DateTime(2026, 3, 4),
        symptoms: const ['cramp'],
      ),
      'yalnızca ruh hâli': DailyLog(
        date: DateTime(2026, 3, 5),
        moods: const ['irritable'],
      ),
      'yalnızca not': DailyLog(date: DateTime(2026, 3, 6), notes: 'bir not'),
      'yalnızca cinsel aktivite': DailyLog(
        date: DateTime(2026, 3, 7),
        sexualActivity: 'protected',
      ),
      // Klinik olarak en ağır kayıt: yalnızca ağrı girilmiş bir gün.
      'yalnızca ağrı': DailyLog(
        date: DateTime(2026, 3, 8),
        painLevel: 'severe',
        painLimitedActivity: true,
      ),
      'yalnızca ağrı bağlamı': DailyLog(
        date: DateTime(2026, 3, 9),
        painLevel: 'moderate',
        painContexts: const ['intercourse'],
      ),
    };

    for (final entry in cases.entries) {
      test('${entry.key} — özette yer alıyor', () {
        final date = DataExportService.buildCsv(
          dailyLogs: [entry.value],
          periodLogs: const [],
        );
        expect(
          summaryOf([entry.value]),
          contains('2026-03-'),
          reason: '${entry.key} günü özetten düşmüş',
        );
        expect(date, contains('2026-03-'), reason: '${entry.key} CSV\'de yok');
      });
    }
  });

  group('ağrı ayrıntısı belgeye giriyor', () {
    final log = DailyLog(
      date: DateTime(2026, 3, 10),
      painLevel: 'severe',
      painLimitedActivity: true,
      painLocations: const ['pelvis'],
      painContexts: const ['intercourse', 'bowel'],
    );

    test('özet ağrının yerini ve bağlamını yazıyor', () {
      final text = summaryOf([log]);

      expect(
        text,
        contains(dictionary['log_pain_loc_pelvis'] as String),
        reason: 'ağrının yeri belgede yok',
      );
      expect(
        text,
        contains(dictionary['log_pain_when_intercourse'] as String),
        reason: 'ağrının bağlamı belgede yok — hekimin sorduğu ayrıntı bu',
      );
    });

    test('CSV ağrı sütunlarını taşıyor', () {
      final csv = csvOf([log]);
      final header = csv.split('\n').first;

      for (final column in [
        'pain',
        'pain_limited',
        'pain_locations',
        'pain_contexts',
      ]) {
        expect(header, contains(column), reason: '$column sütunu yok');
      }
      expect(csv, contains('severe'));
      expect(csv, contains('pelvis'));
      expect(csv, contains('intercourse'));
    });
  });

  group('belge kendisiyle çelişmiyor', () {
    test('özetteki tarih aralığı gün listesiyle uyumlu', () {
      // Klinik özet ile günlük liste iki ayrı süzgeç kullanıyordu:
      // biri ağrıyı sayıyor, diğeri saymıyordu. Sonuç, "şu tarihten şu
      // tarihe kayıt var" deyip o günleri listelemeyen bir belge.
      final logs = [
        DailyLog(
          date: DateTime(2026, 3, 1),
          painLevel: 'severe',
          painLimitedActivity: true,
        ),
      ];

      final clinical = ClinicalSummary.build(
        periodLogs: const [],
        dailyLogs: logs,
        breaks: const [],
      );

      expect(clinical.firstLoggedDay, isNotNull, reason: 'kurulum');
      expect(
        summaryOf(logs),
        contains('2026-03-01'),
        reason: 'aralıkta sayılan gün listede yok',
      );
    });
  });

  group('belgede çiğ anahtar yok', () {
    test('her alan çevrilmiş metinle yazılıyor', () {
      // `translate` tanımadığı anahtar için anahtarın kendisini döndürüyor.
      // Cinsel aktivite satırı tam olarak böyle kaçmıştı: belgede hekime
      // "log_sexual_activity: Korunmalı" diye gidiyordu.
      //
      // Aranan şey hatanın biçimi: lokalizasyon anahtarları snake_case
      // tanımlayıcı ve hiçbir dilde meşru belge içeriği değiller.
      // (Sözlüğün anahtarlarını tek tek aramak işe yaramıyor: "ok" gibi
      // kısa bir anahtar "çok", "okunabilir" içinde geçiyor.)
      final text = summaryOf(
        [
          DailyLog(
            date: DateTime(2026, 3, 3),
            flowIntensity: 'heavy',
            symptoms: const ['cramp'],
            moods: const ['irritable'],
            sexualActivity: 'protected',
            painLevel: 'severe',
            painLimitedActivity: true,
            painLocations: const ['abdomen'],
            painContexts: const ['bowel'],
            notes: 'bir not',
          ),
        ],
        periods: [
          PeriodLog(
            id: 'p',
            startDate: DateTime(2026, 3, 3),
            endDate: DateTime(2026, 3, 7),
          ),
        ],
      );

      final identifiers = RegExp(
        r'\b[a-z][a-z0-9]*(?:_[a-z0-9]+)+\b',
      ).allMatches(text).map((m) => m.group(0)).toSet();

      expect(
        identifiers,
        isEmpty,
        reason: 'çevrilmemiş anahtar belgeye sızmış: $identifiers',
      );
    });

    test('cinsel aktivite okunabilir etiketle yazılıyor', () {
      expect(
        summaryOf([
          DailyLog(date: DateTime(2026, 3, 1), sexualActivity: 'protected'),
        ]),
        contains(dictionary['log_sex_protected'] as String),
      );
    });
  });

  group('CSV biçimi', () {
    test('notlardaki virgül sütunları kaydırmıyor', () {
      final csv = csvOf([
        DailyLog(date: DateTime(2026, 3, 1), notes: 'ağrı vardı, geçti'),
      ]);
      final header = csv.split('\n').first.split(',').length;
      final row = csv.split('\n')[1];

      // Tırnaklı alanları sayarak sütun sayısını çıkar.
      final fields = RegExp(r'"(?:[^"]|"")*"').allMatches(row).length;
      expect(fields, header, reason: 'satır başlıkla aynı sütunda değil');
    });

    test('notlardaki tırnak ikileniyor', () {
      final csv = csvOf([
        DailyLog(date: DateTime(2026, 3, 1), notes: 'o "çok" ağrıdı'),
      ]);
      expect(csv, contains('""çok""'));
    });

    test('ağrı yokken pain_limited boş kalıyor', () {
      // "no" yazmak, sorulmamış bir soruya cevap verilmiş gibi durur.
      final row = csvOf([
        DailyLog(date: DateTime(2026, 3, 1), symptoms: const ['cramp']),
      ]).split('\n')[1];

      expect(row.split(',')[4], '""');
    });

    test('regl günleri işaretleniyor', () {
      final csv = csvOf(
        [
          DailyLog(date: DateTime(2026, 3, 2), symptoms: const ['cramp']),
        ],
        periods: [
          PeriodLog(
            id: 'p',
            startDate: DateTime(2026, 3, 1),
            endDate: DateTime(2026, 3, 5),
          ),
        ],
      );
      expect(csv.split('\n')[1], contains('"yes"'));
    });

    test('lekelenme günü regl sayılmıyor', () {
      final csv = csvOf([
        DailyLog(
          date: DateTime(2026, 3, 2),
          flowIntensity: LogVocabulary.spotting,
        ),
      ]);
      final row = csv.split('\n')[1];
      expect(row, contains('"no"'));
      expect(row, contains('spotting'));
    });
  });

  group('boş veri', () {
    test('kayıt yokken belge yine de üretiliyor', () {
      final text = summaryOf(const []);

      expect(text, contains(dictionary['export_title'] as String));
      expect(text, contains(dictionary['export_no_logs'] as String));
    });

    test('CSV yalnızca başlık satırı döndürüyor', () {
      expect(csvOf(const []).split('\n'), hasLength(1));
    });
  });
}
