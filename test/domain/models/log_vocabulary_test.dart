import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';

void main() {
  group('normalize — kanonik kodlar', () {
    test('zaten kod olan değer aynen döner', () {
      expect(LogVocabulary.normalize('cramp', LogVocabulary.symptoms), 'cramp');
      expect(LogVocabulary.normalize('happy', LogVocabulary.moods), 'happy');
    });

    test('tanınmayan değer null döner', () {
      expect(LogVocabulary.normalize('zzz', LogVocabulary.symptoms), isNull);
    });

    test('yanlış kategoriye ait kod kabul edilmez', () {
      // 'happy' geçerli bir ruh hâli ama semptom değil.
      expect(LogVocabulary.normalize('happy', LogVocabulary.symptoms), isNull);
    });
  });

  group('normalize — eski Türkçe etiketler', () {
    test('semptomlar', () {
      expect(
        LogVocabulary.normalize('Baş Ağrısı', LogVocabulary.symptoms),
        'headache',
      );
      expect(
        LogVocabulary.normalize('Karın Ağrısı', LogVocabulary.symptoms),
        'cramp',
      );
      expect(LogVocabulary.normalize('Kramp', LogVocabulary.symptoms), 'cramp');
      expect(
        LogVocabulary.normalize('Sivilce', LogVocabulary.symptoms),
        'acne',
      );
      expect(
        LogVocabulary.normalize('İştah Artışı', LogVocabulary.symptoms),
        'appetite',
      );
      expect(
        LogVocabulary.normalize('Bel Ağrısı', LogVocabulary.symptoms),
        'backache',
      );
    });

    test('ruh hâli', () {
      expect(LogVocabulary.normalize('Mutlu', LogVocabulary.moods), 'happy');
      expect(
        LogVocabulary.normalize('Hassas', LogVocabulary.moods),
        'sensitive',
      );
      expect(
        LogVocabulary.normalize('Sinirli', LogVocabulary.moods),
        'irritable',
      );
      expect(LogVocabulary.normalize('Yorgun', LogVocabulary.moods), 'tired');
    });

    test('akış yoğunluğu ve cinsel aktivite', () {
      expect(
        LogVocabulary.normalize('Hafif', LogVocabulary.flowIntensities),
        'light',
      );
      expect(
        LogVocabulary.normalize('Yoğun', LogVocabulary.flowIntensities),
        'heavy',
      );
      expect(
        LogVocabulary.normalize('Korunmalı', LogVocabulary.sexualActivities),
        'protected',
      );
      expect(
        LogVocabulary.normalize('Korunmasız', LogVocabulary.sexualActivities),
        'unprotected',
      );
    });

    test('büyük/küçük harf ve Türkçe karakter farkı önemsizdir', () {
      expect(
        LogVocabulary.normalize('bas agrisi', LogVocabulary.symptoms),
        'headache',
      );
      expect(
        LogVocabulary.normalize('BAŞ AĞRISI', LogVocabulary.symptoms),
        'headache',
      );
      expect(
        LogVocabulary.normalize('  Yorgunluk  ', LogVocabulary.symptoms),
        'fatigue',
      );
    });
  });

  group('normalize — eski İngilizce etiketler', () {
    test('İngilizce kaydedilmiş değerler de kurtarılır', () {
      expect(
        LogVocabulary.normalize('Cramps', LogVocabulary.symptoms),
        'cramp',
      );
      expect(
        LogVocabulary.normalize('Tenderness', LogVocabulary.symptoms),
        'tender',
      );
      expect(
        LogVocabulary.normalize('Anxious', LogVocabulary.moods),
        'anxious',
      );
      expect(
        LogVocabulary.normalize('Heavy', LogVocabulary.flowIntensities),
        'heavy',
      );
    });
  });

  group('normalizeAll', () {
    test('tanınmayanları düşürür ve tekrarları teke indirir', () {
      final result = LogVocabulary.normalizeAll([
        'Kramp',
        'Karın Ağrısı',
        'bilinmeyen',
        'Baş Ağrısı',
      ], LogVocabulary.symptoms);
      // 'Kramp' ve 'Karın Ağrısı' aynı koda çözülür.
      expect(result, ['cramp', 'headache']);
    });

    test('boş girdi boş liste döner', () {
      expect(LogVocabulary.normalizeAll([], LogVocabulary.symptoms), isEmpty);
    });
  });

  group('DailyLog geriye dönük uyumluluk', () {
    test('çevrilmiş etiketle kaydedilmiş eski log okunabilir', () {
      // Uygulamanın eski sürümünün yazdığı biçim.
      const legacy =
          '{"date":"2026-03-01T00:00:00.000",'
          '"symptoms":["Baş Ağrısı","Şişkinlik"],'
          '"notes":"test",'
          '"flowIntensity":"Orta",'
          '"moods":["Sinirli"],'
          '"sexualActivity":"Korunmalı"}';

      final log = DailyLog.fromJson(legacy);

      expect(log.symptoms, ['headache', 'bloating']);
      expect(log.flowIntensity, 'medium');
      expect(log.moods, ['irritable']);
      expect(log.sexualActivity, 'protected');
      expect(log.notes, 'test');
    });

    test('iki ekranın farklı sözcükleri aynı koda düşer', () {
      // Takvim ekranı "Karın Ağrısı", log ekranı "Kramp" yazıyordu.
      const fromCalendar =
          '{"date":"2026-03-01T00:00:00.000","symptoms":["Karın Ağrısı"]}';
      const fromLogEntry =
          '{"date":"2026-03-01T00:00:00.000","symptoms":["Kramp"]}';

      expect(
        DailyLog.fromJson(fromCalendar).symptoms,
        DailyLog.fromJson(fromLogEntry).symptoms,
      );
    });

    test('yeni kayıtlar gidiş-dönüşte değişmez', () {
      final original = DailyLog(
        date: DateTime(2026, 3, 1),
        symptoms: const ['cramp', 'acne'],
        moods: const ['calm'],
        flowIntensity: 'light',
        sexualActivity: 'none',
        notes: 'ok',
      );

      final restored = DailyLog.fromJson(original.toJson());

      expect(restored.symptoms, original.symptoms);
      expect(restored.moods, original.moods);
      expect(restored.flowIntensity, original.flowIntensity);
      expect(restored.sexualActivity, original.sexualActivity);
    });

    test('bozuk/bilinmeyen değerler sessizce düşer, exception atmaz', () {
      const weird =
          '{"date":"2026-03-01T00:00:00.000",'
          '"symptoms":["???"],"flowIntensity":"bilinmiyor"}';

      final log = DailyLog.fromJson(weird);
      expect(log.symptoms, isEmpty);
      expect(log.flowIntensity, isNull);
    });
  });

  test('lokalizasyon anahtarları beklenen biçimde üretilir', () {
    expect(LogVocabulary.symptomKey('cramp'), 'log_symptom_cramp');
    expect(LogVocabulary.moodKey('happy'), 'log_mood_happy');
    expect(LogVocabulary.flowKey('light'), 'log_flow_light');
    expect(LogVocabulary.sexualActivityKey('protected'), 'log_sex_protected');
  });
}
