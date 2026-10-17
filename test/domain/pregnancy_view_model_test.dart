import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/data/repositories/conception_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/conception_intent.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';

/// Gebelik durumunun bellekteki tek kaynağı.
///
/// Takvim koruması, hatırlatıcılar ve ekranlar hepsi buradan besleniyor.
/// Bir işlem depoya yazıp burayı güncellemezse (ya da tersi) uygulamanın
/// iki parçası farklı evrede olduğunu sanar — gebeliği bitirmiş kullanıcı
/// regl işaretleyemez, ya da gebe kullanıcı işaretleyebilir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bugun = DateTime(2026, 6, 1);
  late PregnancyViewModel vm;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    vm = PregnancyViewModel(clock: () => bugun);
    await vm.load();
  });

  test('başlangıçta döngü evresi', () {
    expect(vm.stage, LifeStage.cycle);
    expect(vm.current, isNull);
  });

  group('gebeliği işaretleme', () {
    test('SAT\'tan kuruluyor ve depoya yazılıyor', () async {
      await vm.startFromLmp(
        lmp: DateTime(2026, 3, 1),
        cycleLength: 28,
        careTemplate: 'tr',
      );

      expect(vm.stage, LifeStage.pregnancy);
      expect(
        (await const PregnancyRepository().getActive())?.id,
        vm.current!.id,
        reason: 'Bellek ile depo aynı şeyi söylemeli',
      );
    });

    test('Türkiye şablonu seçildiyse izlemler üretiliyor', () async {
      await vm.startFromLmp(
        lmp: DateTime(2026, 3, 1),
        cycleLength: 28,
        careTemplate: 'tr',
      );
      expect(
        vm.currentEvents.where((e) => e.code == 'tr_visit_1'),
        hasLength(1),
      );
      expect(
        await const CareRepository().forPregnancy(vm.current!.id),
        hasLength(vm.currentEvents.length),
      );
    });

    test('kendi randevularını seçen kullanıcıya şablon dayatılmıyor', () async {
      await vm.startFromLmp(lmp: DateTime(2026, 3, 1), cycleLength: 28);
      expect(vm.currentEvents, isEmpty);
    });

    test('hekim tarihiyle kurulabiliyor', () async {
      await vm.startFromDueDate(dueDate: DateTime(2026, 12, 1));
      expect(vm.current!.dueDateFromClinician, isTrue);
    });

    test('süren gebelik varken ikincisi açılmıyor', () async {
      await vm.startFromLmp(lmp: DateTime(2026, 3, 1), cycleLength: 28);
      final ilk = vm.current!.id;
      await vm.startFromLmp(lmp: DateTime(2026, 4, 1), cycleLength: 28);

      expect(vm.current!.id, ilk);
      expect(await const PregnancyRepository().getAll(), hasLength(1));
    });

    test('planlama niyeti kapanıyor', () async {
      await vm.setConception(true);
      expect(vm.conception, isNotNull);

      await vm.startFromLmp(lmp: DateTime(2026, 3, 1), cycleLength: 28);

      expect(vm.conception, isNull, reason: 'Artık planlamıyor, gebe');
      expect(await const ConceptionRepository().get(), isNull);
    });
  });

  group('tarih düzeltme', () {
    test('hekim tarihi gebelik haftasını kaydırıyor', () async {
      await vm.startFromLmp(lmp: DateTime(2026, 3, 1), cycleLength: 28);
      final once = vm.current!.gestationOn(bugun)!.totalDays;

      await vm.updateDueDate(
        vm.current!.estimatedDueDate.subtract(const Duration(days: 7)),
        fromClinician: true,
      );

      expect(vm.current!.gestationOn(bugun)!.totalDays, once + 7);
      expect(vm.current!.dueDateFromClinician, isTrue);
      expect(
        (await const PregnancyRepository().getActive())!.estimatedDueDate,
        vm.current!.estimatedDueDate,
      );
    });
  });

  group('sonlandırma', () {
    test(
      'doğumda lohusalığa geçiliyor ve lohusa izlemleri üretiliyor',
      () async {
        await vm.startFromLmp(
          lmp: DateTime(2025, 9, 1),
          cycleLength: 28,
          careTemplate: 'tr',
        );
        await vm.end(PregnancyOutcome.birth, at: bugun);

        expect(vm.stage, LifeStage.postpartum);
        expect(
          vm.currentEvents.map((e) => e.code),
          containsAll(['tr_pp_visit_4', 'tr_pp_visit_5', 'tr_pp_visit_6']),
        );
      },
    );

    test('kendi randevularında doğum sonrası şablon üretilmiyor', () async {
      await vm.startFromLmp(lmp: DateTime(2025, 9, 1), cycleLength: 28);
      await vm.end(PregnancyOutcome.birth, at: bugun);
      expect(vm.currentEvents.where((e) => !e.isCustom), isEmpty);
    });

    test('düşükte doğrudan döngüye dönülüyor', () async {
      await vm.startFromLmp(
        lmp: DateTime(2026, 4, 1),
        cycleLength: 28,
        careTemplate: 'tr',
      );
      await vm.end(PregnancyOutcome.miscarriage, at: bugun);

      expect(vm.stage, LifeStage.cycle);
      expect(vm.current, isNull);
      expect(
        vm.currentEvents,
        isEmpty,
        reason: 'Döngü evresinde gösterilecek bakım kalemi yok',
      );
    });

    test('kayıtlar silinmiyor, geçmişte kalıyor', () async {
      await vm.startFromLmp(
        lmp: DateTime(2026, 4, 1),
        cycleLength: 28,
        careTemplate: 'tr',
      );
      final id = vm.current!.id;
      await vm.end(PregnancyOutcome.undisclosed, at: bugun);

      expect(vm.pregnancies.single.id, id);
      expect(await const CareRepository().forPregnancy(id), isNotEmpty);
    });

    test('her değişiklik dinleyicileri uyarıyor', () async {
      var uyari = 0;
      vm.addListener(() => uyari++);
      await vm.startFromLmp(lmp: DateTime(2026, 4, 1), cycleLength: 28);
      await vm.end(PregnancyOutcome.miscarriage, at: bugun);
      expect(uyari, greaterThanOrEqualTo(2));
      expect(vm.revision, greaterThanOrEqualTo(2));
    });
  });

  group('randevular', () {
    setUp(() async {
      await vm.startFromLmp(
        lmp: DateTime(2026, 3, 1),
        cycleLength: 28,
        careTemplate: 'tr',
      );
    });

    test('yapıldı işareti kalıcı', () async {
      final e = vm.currentEvents.first;
      await vm.saveEvent(e.copyWith(done: true));

      expect(vm.currentEvents.firstWhere((x) => x.id == e.id).done, isTrue);
      final depoda = await const CareRepository().forPregnancy(vm.current!.id);
      expect(depoda.firstWhere((x) => x.id == e.id).done, isTrue);
    });

    test('kendi randevusunu ekleyip silebiliyor', () async {
      await vm.addCustomEvent(
        title: 'Diş hekimi',
        scheduledAt: DateTime(2026, 7, 3, 14),
      );
      final ozel = vm.currentEvents.singleWhere((e) => e.isCustom);
      expect(ozel.title, 'Diş hekimi');

      await vm.removeEvent(ozel.id);
      expect(vm.currentEvents.where((e) => e.isCustom), isEmpty);
    });

    test('başka gebeliğin kalemi düzenlenemiyor', () async {
      final yabanci = CareEvent.custom(pregnancyId: 'baska', title: 'x');
      await vm.saveEvent(yabanci);
      expect(
        await const CareRepository().forPregnancy('baska'),
        isEmpty,
        reason: 'Yalnızca süren gebeliğin kalemleri yazılabilir',
      );
    });
  });

  group('planlama niyeti', () {
    test('açılıp kapanıyor ve kalıcı', () async {
      await vm.setConception(true);
      expect(vm.conception?.since, bugun);
      expect((await const ConceptionRepository().get())?.since, bugun);

      await vm.setConception(false);
      expect(vm.conception, isNull);
      expect(await const ConceptionRepository().get(), isNull);
    });

    test('zaten açıksa başlangıç tarihi korunuyor', () async {
      // Ekran yeniden açıldığında "açık" anahtarına tekrar basılırsa ASRM
      // sayacı sıfırlanmamalı.
      await const ConceptionRepository().set(
        ConceptionIntent(since: DateTime(2026, 1, 1)),
      );
      await vm.load();
      await vm.setConception(true);
      expect(vm.conception?.since, DateTime(2026, 1, 1));
    });
  });
}
