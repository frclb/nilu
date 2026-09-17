import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/cycle_agenda.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Döngü ayarları değiştiğinde ekranların uyumu.
///
/// Ana ekranda üç yüzey aynı sayıdan besleniyor: çarkın uzunluğu, ortadaki
/// "{n} gün var" cümlesi ve SIRADA listesindeki tarih. Üçü ayrı yoldan
/// hesaplandığı için birinin ayarı alıp diğerinin almaması mümkün — ve
/// böyle bir ayrışma ancak kullanıcı ekranda görünce fark edilir.
void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 10));

  PeriodLog log(int id, DateTime s) => PeriodLog(
    id: '$id',
    startDate: s,
    endDate: s.add(const Duration(days: 4)),
  );

  /// Tek kayıtlı dönem: ortalama çıkaracak veri yok.
  final single = [log(1, start)];

  /// İki dönem: aralarında 30 gün, yani gerçek bir ortalama var.
  final withHistory = [
    log(1, start.subtract(const Duration(days: 30))),
    log(2, start),
  ];

  CycleInfo infoFor(
    List<PeriodLog> logs, {
    int cycleLength = 28,
    int periodLength = 5,
    DateTime? updatedAt,
    bool hormonal = false,
  }) => PredictionService().getCycleInfo(
    logs,
    userCycleLength: cycleLength,
    userPeriodLength: periodLength,
    settingsUpdatedAt: updatedAt,
    hormonalContraception: hormonal,
  );

  group('üç yüzey aynı sayıyı söylüyor', () {
    // Çark `averageCycleLength` kadar çiçek diziyor, başlık
    // `daysUntilNextPeriod` sayıyor, ajanda `predictedNextPeriod` tarihini
    // gösteriyor. Üçü ayrışırsa kullanıcı çelişkiyi tek bakışta görür.
    for (final length in [21, 28, 35, 45]) {
      test('$length günlük döngü ayarı', () {
        final info = infoFor(single, cycleLength: length);

        expect(
          info.averageCycleLength,
          length,
          reason: 'çark ayarı almamış',
        );

        final agenda = CycleAgenda.upcoming(info, now: now);
        final nextPeriod = agenda.where(
          (e) => e.kind == AgendaKind.periodStart,
        );
        expect(nextPeriod, isNotEmpty, reason: 'ajandada regl yok');

        expect(
          nextPeriod.first.daysAway,
          info.daysUntilNextPeriod,
          reason: 'ajanda ile başlık farklı gün sayıyor',
        );
      });
    }
  });

  group('ayar değişikliği geçmişe işlemiyor', () {
    // Ekrandaki söz: "Yapılan değişiklikler yalnızca bugünden itibaren
    // geçerli olacaktır." Yeterli geçmiş varken bu tutuluyor.
    test('ayardan önce başlayan dönem ortalamayı kullanıyor', () {
      final info = infoFor(
        withHistory,
        cycleLength: 45,
        periodLength: 9,
        updatedAt: today,
      );

      expect(
        info.averageCycleLength,
        30,
        reason: 'kayıtlı ortalama korunmalı',
      );
      expect(info.averagePeriodLength, 5);
    });

    test('ayardan sonra başlayan dönem yeni ayarı kullanıyor', () {
      final info = infoFor(
        withHistory,
        cycleLength: 45,
        periodLength: 9,
        updatedAt: start.subtract(const Duration(days: 1)),
      );

      expect(info.averageCycleLength, 45);
      expect(info.averagePeriodLength, 9);
    });

    test('aynı gün değişen ayar geçerli', () {
      final info = infoFor(
        withHistory,
        cycleLength: 45,
        updatedAt: start,
      );

      expect(info.averageCycleLength, 45);
    });
  });

  group('geçmiş yokken ayar doğrudan uygulanıyor', () {
    // Ortalama çıkaracak veri yoksa kullanıcının kendi beyanı en iyi
    // tahmin. Burada `settingsUpdatedAt` kapısı devreye girmiyor — bu
    // bilinçli: alternatif, kullanıcının az önce girdiği sayıyı yok sayıp
    // 28 varsayılanında ısrar etmek olurdu.
    test('tek dönem kayıtlıyken döngü uzunluğu ayardan geliyor', () {
      final info = infoFor(single, cycleLength: 35, updatedAt: today);
      expect(info.averageCycleLength, 35);
    });

    test('hiç kayıt yokken de ayar geçerli', () {
      final info = infoFor(const [], cycleLength: 35, periodLength: 7);
      expect(info.averageCycleLength, 35);
      expect(info.averagePeriodLength, 7);
    });
  });

  group('hormonal doğum kontrolü', () {
    test('doğurganlık hiçbir yerde üretilmiyor', () {
      // Ekranlarda tek tek gizlemek yerine kaynakta üretmemek: yeni bir
      // ekran eklendiğinde gizlemeyi unutma riski kalmıyor.
      final info = infoFor(single, hormonal: true);

      expect(info.ovulationDay, isNull);
      expect(info.fertileWindowStart, isNull);
      expect(info.fertileWindowEnd, isNull);
      expect(info.fertilityTracked, isFalse);
    });

    test('ajandada doğurganlık satırı yok', () {
      final agenda = CycleAgenda.upcoming(
        infoFor(single, hormonal: true),
        now: now,
      );

      expect(
        agenda.map((e) => e.kind),
        everyElement(AgendaKind.periodStart),
        reason: 'baskılanmış döngüde yumurtlama listelenmemeli',
      );
      expect(agenda, isNotEmpty, reason: 'regl tahmini yine de sunulmalı');
    });

    test('kapalıyken doğurganlık geri geliyor', () {
      final info = infoFor(single, hormonal: false);
      expect(info.ovulationDay, isNotNull);
      expect(
        CycleAgenda.upcoming(info, now: now).map((e) => e.kind),
        contains(AgendaKind.fertileStart),
      );
    });
  });

  group('uç ayar değerleri', () {
    test('çok kısa döngüde ajanda bozulmuyor', () {
      final info = infoFor(single, cycleLength: 21);
      final agenda = CycleAgenda.upcoming(info, now: now);

      expect(agenda, isNotEmpty);
      expect(
        agenda.every((e) => e.daysAway > 0),
        isTrue,
        reason: 'geçmiş tarih "yaklaşan" diye listelenmemeli',
      );
    });

    test('regl uzunluğu döngüden uzun olamaz gibi davranmıyor', () {
      // Kullanıcı 10 günlük regl + 21 günlük döngü girebilir; faz
      // hesabı yine de anlamlı kalmalı, hata atmamalı.
      final info = infoFor(const [], cycleLength: 21, periodLength: 10);

      expect(info.getPhaseForDay(1), CyclePhase.menstruation);
      expect(info.getPhaseForDay(10), CyclePhase.menstruation);
      expect(info.getPhaseForDay(21), isNot(CyclePhase.unknown));
    });
  });
}
