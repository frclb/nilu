import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/cycle_alert.dart';

/// Regl dışında tekrarlayan kanamanın tespiti.
///
/// NHS ve ACOG'un ayrıca sorduğu bulgu bu. İki yönde de yanılmak pahalı:
/// kaçırırsak kullanıcı hekime gittiğinde söyleyecek bir şeyi olmaz,
/// gereksiz yere uyarırsak sağlıklı birini korkuturuz ve kartın geri
/// kalanına olan güveni de yok ederiz.
void main() {
  /// Sabit bir zemin: testler bugünün tarihine göre kaymamalı.
  final base = DateTime(2026, 3, 1);
  DateTime day(int offset) => base.add(Duration(days: offset));

  PeriodLog period(int startOffset, int endOffset) => PeriodLog(
    id: 'p$startOffset',
    startDate: day(startOffset),
    endDate: day(endOffset),
  );

  DailyLog bleed(int offset, [String code = LogVocabulary.spotting]) =>
      DailyLog(date: day(offset), flowIntensity: code);

  /// 1-5 ve 29-33 arası iki regl; aradaki günler "ara" sayılır.
  final periods = [period(0, 4), period(28, 32)];

  List<DateTime> episodes(List<DailyLog> logs) =>
      CycleAlertService.intermenstrualEpisodes(
        dailyLogs: logs,
        periodLogs: periods,
        breaks: const [],
      );

  bool alerted(List<DailyLog> logs) => CycleAlertService.evaluate(
    const [],
    dailyLogs: logs,
    periodLogs: periods,
    breaks: const [],
  ).contains(CycleAlert.recurrentIntermenstrualBleeding);

  group('atak sayımı', () {
    test('ayrı günler ayrı atak', () {
      expect(episodes([bleed(12), bleed(20)]), hasLength(2));
    });

    test('arka arkaya günler tek atak', () {
      // İki gün süren bir lekelenme iki olay değil; öyle sayılsaydı tek
      // seferlik bir kanama uyarı üretirdi.
      expect(episodes([bleed(12), bleed(13), bleed(14)]), hasLength(1));
    });

    test('aynı gün iki kez sayılmaz', () {
      expect(episodes([bleed(12), bleed(12)]), hasLength(1));
    });
  });

  group('reglin kenarı ara kanama değil', () {
    test('dönemin içi sayılmaz', () {
      expect(episodes([bleed(2)]), isEmpty);
    });

    test('başlangıçtan iki gün önce sayılmaz', () {
      // Reglin hemen öncesinde lekelenmek olağan.
      expect(episodes([bleed(26), bleed(27)]), isEmpty);
    });

    test('bitişten iki gün sonra sayılmaz', () {
      expect(episodes([bleed(5), bleed(6)]), isEmpty);
    });

    test('payın dışı sayılır', () {
      // Sınırın hemen ötesi: 4. gün bitişe +3.
      expect(episodes([bleed(7)]), hasLength(1));
    });
  });

  group('hangi kayıt kanama sayılır', () {
    test('gerçek akış da sayılır', () {
      // Regl dışında yoğun kanama, lekelenmeden daha da önemli bir bulgu.
      expect(episodes([bleed(12, 'heavy'), bleed(20, 'light')]), hasLength(2));
    });

    test('"yok" sayılmaz', () {
      expect(episodes([bleed(12, 'none'), bleed(20, 'none')]), isEmpty);
    });

    test('akışsız kayıt sayılmaz', () {
      expect(
        episodes([
          DailyLog(date: day(12), symptoms: const ['cramps']),
        ]),
        isEmpty,
      );
    });
  });

  group('uyarı eşiği', () {
    test('iki atak uyarır', () {
      expect(alerted([bleed(12), bleed(20)]), isTrue);
    });

    test('tek atak uyarmaz', () {
      // Yumurtlama kanaması yaygın ve iyi huylu. Tek seferlik bir olayda
      // uyarı çıkarmak sağlıklı birini boş yere korkutur.
      expect(alerted([bleed(12)]), isFalse);
    });

    test('hiç kanama yoksa uyarmaz', () {
      expect(alerted(const []), isFalse);
    });

    test('regl kaydı yoksa uyarmaz', () {
      // Hangi kanamanın "ara"da kaldığı bilinemez; uyarı tahmin olurdu.
      expect(
        CycleAlertService.evaluate(
          const [],
          dailyLogs: [bleed(12), bleed(20)],
          periodLogs: const [],
          breaks: const [],
        ),
        isEmpty,
      );
    });

    test('az döngüyle de uyarır', () {
      // Döngü uzunluğu uyarıları üç gözlem istiyor; ara kanama için
      // beklemek, bulgunun kendisini geciktirmek olurdu.
      expect(alerted([bleed(12), bleed(20)]), isTrue);
    });
  });

  group('devam eden dönem', () {
    test('bitişi bilinmeyen dönemin günleri sayılmaz', () {
      // Bitiş tarihi yokken dönem "bugün bitti" sayılsaydı, sonraki
      // günlerdeki akış ara kanama diye işaretlenirdi.
      final ongoing = [PeriodLog(id: 'o', startDate: day(40))];
      expect(
        CycleAlertService.intermenstrualEpisodes(
          dailyLogs: [bleed(42), bleed(43)],
          periodLogs: ongoing,
          breaks: const [],
        ),
        isEmpty,
      );
    });
  });
}
