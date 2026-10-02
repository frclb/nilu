import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/calendar_day.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/cycle_intervals.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';

/// Lohusalıktan erken çıkış ("regl takibine dön").
///
/// Lohusalık doğumdan sonra 42 gün sabitti; kullanıcının çıkış yolu
/// yoktu. Erken bitiş hem evreyi hem döngü kesintisini aynı günde
/// bitirmeli: ayrı hesaplansalardı kullanıcı döngüye dönmüş olur ama
/// girdiği ilk regl hâlâ kesinti içinde sayılıp yok sayılırdı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bugun = DateTime(2026, 10, 2);
  DateTime once(int n) => bugun.subtract(Duration(days: n));

  Pregnancy dogum(int kacGunOnce) => Pregnancy.fromLmp(
    lmp: once(kacGunOnce + 275),
    cycleLength: 28,
    confirmedAt: once(kacGunOnce + 230),
    id: 'g1',
  ).ended(outcome: PregnancyOutcome.birth, at: once(kacGunOnce));

  group('evre', () {
    test('erken bitirilmediyse 42 gün lohusalık', () {
      expect(
        LifeStage.resolve([dogum(10)], today: bugun),
        LifeStage.postpartum,
      );
    });

    test('erken bitirildiyse o günden itibaren döngü', () {
      final g = dogum(25).withPostpartumEndedAt(once(5));
      expect(LifeStage.resolve([g], today: bugun), LifeStage.cycle);
      expect(LifeStage.resolve([g], today: once(6)), LifeStage.postpartum);
      expect(LifeStage.relevantPregnancy([g], today: bugun), isNull);
    });

    test('bitiş günü 42 günden sonraysa etkisiz', () {
      final g = dogum(
        10,
      ).withPostpartumEndedAt(bugun.add(const Duration(days: 60)));
      expect(LifeStage.postpartumEndOf(g), once(10).plusDays(42));
    });

    test('doğumla bitmeyen gebelikte lohusalık yok', () {
      final g = Pregnancy.fromLmp(
        lmp: once(80),
        cycleLength: 28,
        id: 'g2',
      ).ended(outcome: PregnancyOutcome.miscarriage, at: once(20));
      expect(LifeStage.postpartumEndOf(g), isNull);
    });
  });

  group('döngü kesintisi', () {
    final g = dogum(25).withPostpartumEndedAt(once(10));

    test('kesinti lohusalığın erken bitişinde kapanıyor', () {
      final kesinti = CycleBreaks.fromPregnancies([g]).single;
      expect(kesinti.end, once(10));
    });

    test('çıkıştan sonra girilen regl sayılıyor, öncesi sayılmıyor', () {
      final kayitlar = [
        PeriodLog(id: 'lohia', startDate: once(20), endDate: once(16)),
        PeriodLog(id: 'ilk', startDate: once(3), endDate: once(1)),
      ];
      expect(
        CycleIntervals.usableStarts(
          kayitlar,
          breaks: CycleBreaks.fromPregnancies([g]),
        ),
        [once(3)],
      );
    });
  });

  group('kayıt', () {
    test('erken bitiş kaydedilip okunuyor', () {
      final g = dogum(25).withPostpartumEndedAt(once(5));
      expect(Pregnancy.fromMap(g.toMap()).postpartumEndedAt, once(5));
    });

    test('doğumdan önceki erken bitiş bozuk sayılıp düşüyor', () {
      final m = dogum(25).toMap()..['postpartumEndedAt'] = '2020-01-01';
      final g = Pregnancy.fromMap(m);
      expect(g.postpartumEndedAt, isNull);
      expect(g.endedAt, once(25), reason: 'Gebeliğin kendisi kalmalı');
    });

    test('tarih düzeltmesi erken bitişi koruyor', () {
      final g = dogum(25).withPostpartumEndedAt(once(5));
      expect(
        g.withDueDate(once(20), fromClinician: true).postpartumEndedAt,
        once(5),
      );
    });
  });

  group('ViewModel', () {
    Future<PregnancyViewModel> kur(Pregnancy g) async {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      await const PregnancyRepository().upsert(g);
      final vm = PregnancyViewModel(clock: () => bugun);
      await vm.load();
      return vm;
    }

    test('regl takibine dönünce evre döngü, kayıt yerinde', () async {
      final vm = await kur(dogum(10));
      expect(vm.stage, LifeStage.postpartum);

      await vm.endPostpartum();

      expect(vm.stage, LifeStage.cycle);
      expect(vm.pregnancies.single.outcome, PregnancyOutcome.birth);
      expect(vm.pregnancies.single.postpartumEndedAt, bugun);
      final depo = await const PregnancyRepository().getAll();
      expect(depo.single.postpartumEndedAt, bugun, reason: 'Kalıcı olmalı');
    });

    test('gebelikte hiçbir şey yapmıyor', () async {
      final vm = await kur(
        Pregnancy.fromLmp(lmp: once(100), cycleLength: 28, id: 'g3'),
      );
      await vm.endPostpartum();
      expect(vm.stage, LifeStage.pregnancy);
      expect(vm.pregnancies.single.postpartumEndedAt, isNull);
    });
  });
}
