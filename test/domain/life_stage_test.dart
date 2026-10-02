import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';

/// Kullanıcının hangi evrede olduğu ve o evrede kanamanın ne anlama geldiği.
///
/// Bkz. `LIFE_STAGES.md` §1. Kanama döngüde regl, gebelikte tehlike işareti,
/// lohusalıkta lohia. Bu karar tek yerde veriliyor: aynı kural birden fazla
/// yerde yazıldığında birinin eskimesi bu oturumda defalarca görüldü.
void main() {
  final bugun = DateTime(2026, 10, 2);

  Pregnancy suren() => Pregnancy.fromLmp(
    lmp: DateTime(2026, 5, 1),
    cycleLength: 28,
    confirmedAt: DateTime(2026, 6, 10),
    id: 'suren',
  );

  Pregnancy biten(PregnancyOutcome sonuc, DateTime bitis) => Pregnancy.fromLmp(
    lmp: DateTime(2025, 12, 1),
    cycleLength: 28,
    confirmedAt: DateTime(2026, 1, 10),
    id: 'biten',
  ).ended(outcome: sonuc, at: bitis);

  group('evre çözümlemesi', () {
    test('kayıt yokken döngü', () {
      expect(LifeStage.resolve(const [], today: bugun), LifeStage.cycle);
    });

    test('süren gebelik varken gebelik', () {
      expect(LifeStage.resolve([suren()], today: bugun), LifeStage.pregnancy);
    });

    test('doğumdan sonraki 42 gün lohusalık', () {
      final dogum = bugun.subtract(const Duration(days: 10));
      expect(
        LifeStage.resolve([biten(PregnancyOutcome.birth, dogum)], today: bugun),
        LifeStage.postpartum,
      );
    });

    test('lohusalık sınırları: 41. gün içeride, 42. gün dışarıda', () {
      // Bakanlık: lohusalık izlemi doğumu takip eden 42. güne kadar.
      // Doğum günü 0. gün sayılıyor; 42. gün döngüye dönülüyor.
      DateTime gun(int n) => DateTime(bugun.year, bugun.month, bugun.day - n);

      expect(
        LifeStage.resolve([
          biten(PregnancyOutcome.birth, gun(0)),
        ], today: bugun),
        LifeStage.postpartum,
        reason: 'doğum günü',
      );
      expect(
        LifeStage.resolve([
          biten(PregnancyOutcome.birth, gun(41)),
        ], today: bugun),
        LifeStage.postpartum,
        reason: '41. gün',
      );
      expect(
        LifeStage.resolve([
          biten(PregnancyOutcome.birth, gun(42)),
        ], today: bugun),
        LifeStage.cycle,
        reason: '42. gün döngüye dönülür',
      );
    });

    test('ölü doğumdan sonra da lohusalık', () {
      // Doğum gerçekleşti; lohia, süt ve lohusa izlemi aynı şekilde geçerli.
      expect(
        LifeStage.resolve([
          biten(
            PregnancyOutcome.stillbirth,
            bugun.subtract(const Duration(days: 5)),
          ),
        ], today: bugun),
        LifeStage.postpartum,
      );
    });

    test('erken kayıplarda doğrudan döngüye dönülür', () {
      // Lohusa izlem protokolü doğum içindir. Erken kayıptan sonraki kanama
      // bir döngü başlangıcı olarak sayılabiliyor; ama o kaydın önündeki
      // aralık (bkz. cycle_break_test) istatistikten dışlanıyor.
      for (final sonuc in [
        PregnancyOutcome.miscarriage,
        PregnancyOutcome.termination,
        PregnancyOutcome.ectopic,
        PregnancyOutcome.undisclosed,
      ]) {
        expect(
          LifeStage.resolve([
            biten(sonuc, bugun.subtract(const Duration(days: 5))),
          ], today: bugun),
          LifeStage.cycle,
          reason: sonuc.name,
        );
      }
    });

    test('süren gebelik geçmiş bir doğumdan önce gelir', () {
      // Lohusalık penceresi içinde yeniden gebe kalınması nadir ama
      // mümkün; süren gebelik her zaman kazanır.
      final eski = biten(
        PregnancyOutcome.birth,
        bugun.subtract(const Duration(days: 20)),
      );
      expect(
        LifeStage.resolve([eski, suren()], today: bugun),
        LifeStage.pregnancy,
      );
    });
  });

  group('kanamanın anlamı', () {
    test('her evre için tanımlı', () {
      expect(LifeStage.cycle.bleedingMeaning, BleedingMeaning.period);
      expect(LifeStage.pregnancy.bleedingMeaning, BleedingMeaning.warningSign);
      expect(LifeStage.postpartum.bleedingMeaning, BleedingMeaning.lochia);
    });

    test('yalnızca döngüde regl kaydı tutulur', () {
      expect(LifeStage.cycle.recordsPeriods, isTrue);
      expect(
        LifeStage.pregnancy.recordsPeriods,
        isFalse,
        reason: 'Gebelikte kanama tehlike işareti (Bakanlık listesi)',
      );
      expect(
        LifeStage.postpartum.recordsPeriods,
        isFalse,
        reason:
            'Lohia regl değil; azaldıktan sonra yeniden artarsa tehlike '
            'işareti (Bakanlık Doğum Sonu Bakım Rehberi)',
      );
    });

    test('döngü dışı evrelerde tahmin gösterilmez', () {
      expect(LifeStage.cycle.showsCyclePredictions, isTrue);
      expect(LifeStage.pregnancy.showsCyclePredictions, isFalse);
      expect(LifeStage.postpartum.showsCyclePredictions, isFalse);
    });
  });
}
