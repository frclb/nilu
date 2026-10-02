import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/pregnancy/end_pregnancy_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Gebeliği sonlandırma.
///
/// Bu tür uygulamaların en çok yara aldığı ekran: sonuç listesinin eksik
/// olması, "belirtmek istemiyorum" seçeneğinin olmaması, sonlandırmanın
/// takvime ulaşmaması (kullanıcı düşükten sonra regl işaretleyemez).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  Finder onay() => find.byKey(const Key('preg_end_confirm'));

  for (final boyut in screenSizes.entries) {
    testWidgets('her sonuç seçilebilir — ${boyut.key}', (tester) async {
      await seedPregnancy();
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const EndPregnancyScreen()),
        size: boyut.value,
      );
      expect(find.byType(EndPregnancyScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'düzen hatası');

      // Model bir sonuç kazanırsa ekranda da olmalı; yoksa o sonucu yaşayan
      // kullanıcı kendini listede bulamaz.
      for (final s in PregnancyOutcome.values) {
        expect(
          find.byKey(Key('preg_end_${s.name}'), skipOffstage: false),
          findsOneWidget,
          reason: '${s.name} seçeneği yok',
        );
      }
      expect(rawKeysOnScreen(tester), isEmpty);
    });
  }

  testWidgets('seçim yapılmadan onaylanamıyor', (tester) async {
    await seedPregnancy();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const EndPregnancyScreen()),
    );
    expect(tester.widget<FilledButton>(onay()).onPressed, isNull);
  });

  testWidgets('düşük: gebelik biter, takvim regl kaydına açılır', (
    tester,
  ) async {
    await seedPregnancy();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const EndPregnancyScreen()),
    );
    final ctx = tester.element(find.byType(EndPregnancyScreen));
    final vm = ctx.read<PregnancyViewModel>();
    final takvim = ctx.read<CalendarViewModel>();

    await tester.tap(find.byKey(const Key('preg_end_miscarriage')));
    await tester.pump();
    await tester.ensureVisible(onay());
    await tester.tap(onay());
    await settleAsync(tester);

    expect(find.text(homeMarker), findsOneWidget);
    expect(vm.pregnancies.single.outcome, PregnancyOutcome.miscarriage);
    expect(vm.pregnancies.single.endedAt, today);
    expect(vm.stage, LifeStage.cycle);
    expect(takvim.lifeStage.recordsPeriods, isTrue);
  });

  testWidgets('"belirtmek istemiyorum" de sonlandırıyor', (tester) async {
    await seedPregnancy();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const EndPregnancyScreen()),
    );
    final vm = tester
        .element(find.byType(EndPregnancyScreen))
        .read<PregnancyViewModel>();

    await tester.ensureVisible(find.byKey(const Key('preg_end_undisclosed')));
    await tester.tap(find.byKey(const Key('preg_end_undisclosed')));
    await tester.pump();
    await tester.ensureVisible(onay());
    await tester.tap(onay());
    await settleAsync(tester);

    expect(vm.pregnancies.single.outcome, PregnancyOutcome.undisclosed);
    expect(vm.stage, LifeStage.cycle);
  });

  testWidgets('doğum: lohusalığa geçer, lohusa izlemleri eklenir', (
    tester,
  ) async {
    await seedPregnancy(weeks: 39, days: 2);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const EndPregnancyScreen()),
    );
    final vm = tester
        .element(find.byType(EndPregnancyScreen))
        .read<PregnancyViewModel>();

    await tester.tap(find.byKey(const Key('preg_end_birth')));
    await tester.pump();
    await tester.ensureVisible(onay());
    await tester.tap(onay());
    await settleAsync(tester);

    expect(vm.stage, LifeStage.postpartum);
    expect(
      vm.currentEvents.where((e) => e.anchor == CareAnchor.postpartum),
      isNotEmpty,
    );
  });
}
