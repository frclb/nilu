import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/vitals.dart';

/// Tansiyon ve kilo: eşikler, kabul aralıkları ve kayıt.
void main() {
  group('tansiyon eşikleri (NICE NG133, ACOG PB 222)', () {
    test('140/90 altı normal', () {
      expect(Vitals.classify(139, 89), BloodPressureLevel.normal);
      expect(Vitals.classify(110, 70), BloodPressureLevel.normal);
    });

    test('büyük ya da küçükten biri 140/90 eşiğini geçince yüksek', () {
      expect(Vitals.classify(140, 80), BloodPressureLevel.high);
      expect(Vitals.classify(120, 90), BloodPressureLevel.high);
      expect(Vitals.classify(159, 109), BloodPressureLevel.high);
    });

    test('160/110 ve üstü ağır', () {
      expect(Vitals.classify(160, 100), BloodPressureLevel.severe);
      expect(Vitals.classify(150, 110), BloodPressureLevel.severe);
    });
  });

  group('kabul aralıkları', () {
    test('kilo', () {
      expect(Vitals.isPlausibleWeight(29.9), isFalse);
      expect(Vitals.isPlausibleWeight(30), isTrue);
      expect(Vitals.isPlausibleWeight(250), isTrue);
      expect(Vitals.isPlausibleWeight(250.1), isFalse);
    });

    test('tansiyon', () {
      expect(Vitals.isPlausibleBloodPressure(120, 80), isTrue);
      expect(
        Vitals.isPlausibleBloodPressure(80, 120),
        isFalse,
        reason: 'Alanlar karışmış',
      );
      expect(Vitals.isPlausibleBloodPressure(69, 50), isFalse);
      expect(Vitals.isPlausibleBloodPressure(251, 90), isFalse);
      expect(Vitals.isPlausibleBloodPressure(120, 39), isFalse);
      expect(Vitals.isPlausibleBloodPressure(1205, 80), isFalse);
    });

    test('ondalık virgül de nokta da kabul', () {
      expect(Vitals.parseDecimal('64,5'), 64.5);
      expect(Vitals.parseDecimal('64.5'), 64.5);
      expect(Vitals.parseDecimal(' 64 '), 64);
      expect(Vitals.parseDecimal('altmış'), isNull);
    });
  });

  group('kayıt', () {
    final gun = DateTime(2026, 9, 1);

    test('ölçümler kaydedilip okunuyor', () {
      final k = DailyLog(
        date: gun,
        weightKg: 64.5,
        systolic: 118,
        diastolic: 76,
      );
      final o = DailyLog.fromMap(k.toMap());
      expect(o.weightKg, 64.5);
      expect(o.systolic, 118);
      expect(o.diastolic, 76);
    });

    test('ölçümsüz eski kayıt okunuyor', () {
      final o = DailyLog.fromMap({
        'date': gun.toIso8601String(),
        'symptoms': ['headache'],
      });
      expect(o.weightKg, isNull);
      expect(o.systolic, isNull);
      expect(o.symptoms, ['headache']);
    });

    test('aralık dışı ölçüm okunurken düşüyor', () {
      // Bozuk bir yedek hekime giden özete "1205 mmHg" koymasın.
      final o = DailyLog.fromMap({
        'date': gun.toIso8601String(),
        'weightKg': 1205,
        'systolic': 80,
        'diastolic': 120,
      });
      expect(o.weightKg, isNull);
      expect(o.systolic, isNull);
      expect(o.diastolic, isNull);
    });

    test('tansiyonun tek değeri tek başına kalmıyor', () {
      final o = DailyLog.fromMap({
        'date': gun.toIso8601String(),
        'systolic': 120,
      });
      expect(o.systolic, isNull);
      expect(o.diastolic, isNull);
    });

    test('yalnızca ölçüm girilmiş gün içerikli sayılıyor', () {
      expect(DailyLog(date: gun, weightKg: 60).hasContent, isTrue);
      expect(
        DailyLog(date: gun, systolic: 120, diastolic: 80).hasContent,
        isTrue,
      );
    });
  });

  group('copyWith', () {
    final dolu = DailyLog(
      date: DateTime(2026, 9, 1),
      symptoms: const ['nausea'],
      notes: 'not',
      flowIntensity: 'spotting',
      moods: const ['calm'],
      sexualActivity: 'protected',
      painLevel: 'mild',
      painLimitedActivity: true,
      painLocations: const ['abdomen'],
      painContexts: const ['intercourse'],
      weightKg: 64.5,
      systolic: 118,
      diastolic: 76,
    );

    test('argümansız kopya her alanı koruyor', () {
      // Bir alan kopyada unutulursa kaydın dört yolundan biri onu her
      // kayıtta siler. `toMap` bütün alanları içerdiği için karşılaştırma
      // yeni eklenen alanları da kapsıyor.
      expect(dolu.copyWith().toMap(), dolu.toMap());
    });

    test('akışı değiştirmek ölçümleri silmiyor', () {
      final y = dolu.withFlowIntensity('light');
      expect(y.flowIntensity, 'light');
      expect(y.weightKg, 64.5);
      expect(y.systolic, 118);
      expect(y.sexualActivity, 'protected');
    });

    test('ağrı kaldırılınca yeri, bağlamı ve kısıtlaması da düşüyor', () {
      // Klinik özet "aktiviteyi engelleyen ağrı" günlerini bayraktan
      // sayıyor; ağrısı kaldırılmış gün orada sayılmamalı.
      final y = dolu.copyWith(clearPain: true);
      expect(y.painLevel, isNull);
      expect(y.painLocations, isEmpty);
      expect(y.painContexts, isEmpty);
      expect(y.painLimitedActivity, isFalse);
      expect(y.weightKg, 64.5, reason: 'Ölçüm etkilenmemeli');
    });

    test('ölçümler ayrı ayrı temizlenebiliyor', () {
      final y = dolu.copyWith(clearWeight: true);
      expect(y.weightKg, isNull);
      expect(y.systolic, 118);
      final z = dolu.copyWith(clearBloodPressure: true);
      expect(z.systolic, isNull);
      expect(z.diastolic, isNull);
      expect(z.weightKg, 64.5);
    });
  });
}
