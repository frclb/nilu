import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/log_vocabulary.dart';

/// Hangi akış yoğunluğu bir regl günü başlatır?
///
/// Kayıt ekranı "akış girildiyse kanama var demektir" diyip herhangi bir
/// değer için dönemi başlatıyordu. İki ayrı sorun:
///
///   * `none` "kanama yok" demek. "Yok" seçip kaydeden kullanıcı regl
///     başlatıyordu.
///   * Lekelenme regl değil. Ara kanama NHS ve ACOG'un "hekime danış"
///     dediği ayrı bir bulgu; regl günü sayılırsa hem döngü uzunluğu
///     bozulur hem de yanlış "kısa döngü" uyarısı çıkabilir.
void main() {
  group('regl başlatan akış', () {
    test('gerçek kanama kademeleri başlatır', () {
      for (final code in ['light', 'medium', 'heavy']) {
        expect(
          LogVocabulary.startsPeriod(code),
          isTrue,
          reason: '$code bir regl günüdür',
        );
      }
    });

    test('"yok" başlatmaz', () {
      expect(
        LogVocabulary.startsPeriod('none'),
        isFalse,
        reason: '"kanama yok" kaydı regl başlatmamalı',
      );
    });

    test('lekelenme başlatmaz', () {
      expect(
        LogVocabulary.startsPeriod(LogVocabulary.spotting),
        isFalse,
        reason: 'ara kanama regl değil; döngü uzunluğunu bozmamalı',
      );
    });

    test('kayıt yokken başlatmaz', () {
      expect(LogVocabulary.startsPeriod(null), isFalse);
    });

    test('tanınmayan değer başlatmaz', () {
      expect(LogVocabulary.startsPeriod('kanama_var'), isFalse);
    });
  });

  group('kanama bildiren akış', () {
    test('lekelenme kanamadır', () {
      expect(
        LogVocabulary.isBleeding(LogVocabulary.spotting),
        isTrue,
        reason: 'lekelenme regl değil ama kanamadır — klinik özete girmeli',
      );
    });

    test('regl kademeleri kanamadır', () {
      for (final code in ['light', 'medium', 'heavy']) {
        expect(LogVocabulary.isBleeding(code), isTrue);
      }
    });

    test('"yok" kanama değildir', () {
      expect(LogVocabulary.isBleeding('none'), isFalse);
    });
  });

  group('sözlük tutarlılığı', () {
    test('regl kademeleri tam listenin içinde', () {
      expect(
        LogVocabulary.flowIntensities,
        containsAll(LogVocabulary.periodFlowIntensities),
      );
    });

    test('lekelenme tam listede ama regl kademesi değil', () {
      expect(LogVocabulary.flowIntensities, contains(LogVocabulary.spotting));
      expect(
        LogVocabulary.periodFlowIntensities,
        isNot(contains(LogVocabulary.spotting)),
      );
    });

    test('artan yoğunluk sırası korunuyor', () {
      // Ekranda soldan sağa bu sırayla çiziliyor; sıra bozulursa kullanıcı
      // "hafif"i "yoğun"un sağında görür.
      expect(LogVocabulary.flowIntensities, [
        'none',
        'spotting',
        'light',
        'medium',
        'heavy',
      ]);
    });
  });
}
