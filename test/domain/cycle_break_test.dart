import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/insights_service.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';

/// Gebelik aralığı döngü istatistiğine karışmamalı.
///
/// Döngü uzunluğu ardışık iki regl başlangıcı arasındaki fark. Gebelik bunun
/// arasına girdiğinde ortaya döngü olmayan bir aralık çıkıyor:
///
/// - Tam süreli gebelik (~10 ay) 90 günlük üst sınırı aştığı için zaten
///   dışlanıyordu.
/// - **Erken kayıp aşmıyor.** SAT'tan 8. haftadaki düşüğe 56 gün — makul
///   bir "döngü" gibi ortalamaya giriyor, uyarı kartını tetikleyebiliyor.
/// - En kötüsü: doğumdan sonra ilk regl gelene dek son kayıt **gebelik
///   öncesi** SAT. Tahmin servisi ondan ileri sayıp lohusa bir anneye
///   "reglin 250 gün gecikti" diyordu.
void main() {
  DateTime g(int ay, int gun, [int yil = 2026]) => DateTime(yil, ay, gun);

  PeriodLog log(String id, DateTime s, [int gun = 5]) => PeriodLog(
    id: id,
    startDate: s,
    endDate: s.add(Duration(days: gun - 1)),
  );

  // Gebelik öncesi düzenli 28 günlük geçmiş, SAT 1 Ocak.
  final oncesi = [
    log('a', g(10, 9, 2025)),
    log('b', g(11, 6, 2025)),
    log('c', g(12, 4, 2025)),
    log('sat', g(1, 1)),
  ];

  group('aralık dışlama', () {
    test('erken kayıp sahte bir döngü üretmiyor', () {
      final gebelik = Pregnancy.fromLmp(
        lmp: g(1, 1),
        cycleLength: 28,
        confirmedAt: g(2, 1),
      ).ended(outcome: PregnancyOutcome.miscarriage, at: g(2, 26));

      // Düşük kanaması regl olarak işaretlendi (klinikte de 1. gün
      // sayılabiliyor), ardından ilk gerçek regl.
      final kayitlar = [...oncesi, log('dusuk', g(2, 26)), log('ilk', g(4, 1))];
      final kesintiler = CycleBreaks.fromPregnancies([gebelik]);

      final uzunluklar = InsightsService.cycleLengths(
        kayitlar,
        breaks: kesintiler,
      ).map((p) => p.lengthInDays);

      expect(
        uzunluklar,
        isNot(contains(56)),
        reason:
            'SAT ile düşük arası (56 gün) döngü değil, gebelik. Ortalamaya '
            'girerse "uzun döngü" uyarısını haksız yere tetikler.',
      );
      expect(
        uzunluklar,
        [28, 28, 28, 34],
        reason:
            'Gebelik öncesi döngüler ve düşükten sonraki ilk döngü '
            'korunmalı — yalnızca gebeliği kapsayan aralık çıkıyor',
      );
    });

    test('gebelik öncesi son döngü korunuyor', () {
      // SAT aralığın **bitişi** olduğunda o döngü gebeliği kapsamıyor.
      final gebelik = Pregnancy.fromLmp(
        lmp: g(1, 1),
        cycleLength: 28,
        confirmedAt: g(2, 1),
      );
      final uzunluklar = InsightsService.cycleLengths(
        oncesi,
        breaks: CycleBreaks.fromPregnancies([gebelik]),
      ).map((p) => p.lengthInDays);

      expect(uzunluklar, [28, 28, 28]);
    });

    test('kesinti yokken davranış değişmiyor', () {
      expect(
        InsightsService.cycleLengths(
          oncesi,
          breaks: const [],
        ).map((p) => p.lengthInDays),
        [28, 28, 28],
      );
    });

    test('doğumda kesinti lohusalığı da kapsıyor', () {
      final gebelik = Pregnancy.fromLmp(
        lmp: g(1, 1),
        cycleLength: 28,
        confirmedAt: g(2, 1),
      ).ended(outcome: PregnancyOutcome.birth, at: g(10, 8));

      final kesinti = CycleBreaks.fromPregnancies([gebelik]).single;
      expect(kesinti.start, gebelik.gestationStart);
      expect(
        kesinti.end,
        g(10, 8).add(const Duration(days: 42)),
        reason: 'Lohusalık (42 gün) da döngü değil',
      );
    });

    test('süren gebeliğin kesintisi açık uçlu', () {
      final gebelik = Pregnancy.fromLmp(
        lmp: g(1, 1),
        cycleLength: 28,
        confirmedAt: g(2, 1),
      );
      expect(CycleBreaks.fromPregnancies([gebelik]).single.end, isNull);
    });
  });

  group('tahmin', () {
    final servis = PredictionService();

    test('doğumdan sonra eski SAT\'tan tahmin yapılmıyor', () {
      final gebelik = Pregnancy.fromLmp(
        lmp: g(1, 1),
        cycleLength: 28,
        confirmedAt: g(2, 1),
      ).ended(outcome: PregnancyOutcome.birth, at: g(10, 8));

      // Doğumdan 4 ay sonra, henüz regl yok.
      final info = servis.getCycleInfo(
        oncesi,
        breaks: CycleBreaks.fromPregnancies([gebelik]),
        today: DateTime(2027, 2, 8),
      );

      expect(
        info.lastPeriodStart,
        isNull,
        reason:
            'Son kayıt gebelik öncesi SAT. Ondan ileri sayılırsa lohusa '
            'anneye "reglin 250+ gün gecikti" deniyor.',
      );
      expect(info.predictedNextPeriod, isNull);
      expect(info.fertileWindowStart, isNull);
    });

    test('ilk regl geldiğinde bile hemen tarih tahmin edilmiyor', () {
      // Doğum sonrası ilk döngüler düzensiz (emzirmede daha da). Bir döngü
      // tamamlanmadan tarih vermek kendinden emin bir yanlış olur.
      final gebelik = Pregnancy.fromLmp(
        lmp: g(1, 1),
        cycleLength: 28,
        confirmedAt: g(2, 1),
      ).ended(outcome: PregnancyOutcome.birth, at: g(10, 8));

      final info = servis.getCycleInfo(
        [...oncesi, log('ilk', DateTime(2027, 2, 1))],
        breaks: CycleBreaks.fromPregnancies([gebelik]),
        today: DateTime(2027, 2, 3),
      );

      expect(
        info.lastPeriodStart,
        DateTime(2027, 2, 1),
        reason: 'Bugünkü regl görülmeli',
      );
      expect(
        info.predictedNextPeriod,
        isNull,
        reason: 'Gebelik sonrası tamamlanmış döngü yok',
      );
      expect(
        info.fertileWindowStart,
        isNull,
        reason:
            'Bilinmeyen doğurganlık penceresi "güvenli gün" gibi '
            'görünmemeli',
      );
    });

    test('gebelik sonrası bir döngü tamamlanınca tahmin dönüyor', () {
      final gebelik = Pregnancy.fromLmp(
        lmp: g(1, 1),
        cycleLength: 28,
        confirmedAt: g(2, 1),
      ).ended(outcome: PregnancyOutcome.birth, at: g(10, 8));

      final info = servis.getCycleInfo(
        [
          ...oncesi,
          log('ilk', DateTime(2027, 2, 1)),
          log('ikinci', DateTime(2027, 3, 3)),
        ],
        breaks: CycleBreaks.fromPregnancies([gebelik]),
        today: DateTime(2027, 3, 5),
      );

      expect(info.lastPeriodStart, DateTime(2027, 3, 3));
      expect(info.predictedNextPeriod, isNotNull);
    });

    test('süren gebelikte tahmin üretilmiyor', () {
      final gebelik = Pregnancy.fromLmp(
        lmp: g(1, 1),
        cycleLength: 28,
        confirmedAt: g(2, 1),
      );
      final info = servis.getCycleInfo(
        oncesi,
        breaks: CycleBreaks.fromPregnancies([gebelik]),
        today: g(5, 1),
      );

      expect(info.predictedNextPeriod, isNull);
      expect(
        info.fertileWindowStart,
        isNull,
        reason: 'Gebe birine doğurganlık penceresi göstermek anlamsız',
      );
    });

    test('kesinti yokken tahmin eskisi gibi', () {
      final info = servis.getCycleInfo(oncesi, today: g(1, 3));
      expect(info.lastPeriodStart, g(1, 1));
      expect(info.predictedNextPeriod, g(1, 29));
    });
  });
}
