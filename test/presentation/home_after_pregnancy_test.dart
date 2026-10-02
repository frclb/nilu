import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/home/home_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Gebelik bittikten sonra döngü ana ekranı.
///
/// Döngü istatistiği kesintiden sonraki regl başlangıçlarından hesaplanıyor;
/// gebelik bitip henüz regl girilmemişse ortada "gün" yok. Başlık o zaman
/// "Henüz kayıt yok" diyordu: kayıtları olan, çoğu zaman bir kaybın hemen
/// ardındaki kullanıcıya hem yanlış hem incitici bir cümle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  /// Gebelik öncesi düzenli döngüler; gebelik [bitti] gün önce [sonuc]
  /// ile bitti.
  Future<void> gebelikSonrasi({
    required int bitti,
    required int sure,
    required PregnancyOutcome sonuc,
  }) async {
    final lmp = daysAgo(bitti + sure);
    await seedCycles(lastStartAgo: bitti + sure);
    final g = Pregnancy.fromLmp(
      lmp: lmp,
      cycleLength: 28,
      confirmedAt: lmp.add(const Duration(days: 35)),
      id: 'g1',
    );
    await const PregnancyRepository().upsert(
      g.ended(outcome: sonuc, at: daysAgo(bitti)),
    );
  }

  Future<BuildContext> ac(WidgetTester tester, {Size? boyut}) async {
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const HomeScreen()),
      size: boyut ?? const Size(390, 844),
    );
    expect(tester.takeException(), isNull, reason: 'düzen hatası');
    return tester.element(find.byType(HomeScreen));
  }

  for (final boyut in screenSizes.entries) {
    testWidgets('düşükten 3 gün sonra — ${boyut.key}', (tester) async {
      await gebelikSonrasi(
        bitti: 3,
        sure: 70,
        sonuc: PregnancyOutcome.miscarriage,
      );
      final ctx = await ac(tester, boyut: boyut.value);

      expect(ctx.read<CalendarViewModel>().lifeStage, LifeStage.cycle);
      expect(
        find.text(ctx.tr('home_headline_after_pregnancy')),
        findsOneWidget,
      );
      expect(
        find.text(ctx.tr('home_headline_no_data')),
        findsNothing,
        reason: 'Kayıtları olan kullanıcıya "henüz kayıt yok"',
      );
      expect(
        find.text(ctx.tr('home_period_start'), skipOffstage: false),
        findsOneWidget,
        reason: 'İlk regli buradan işaretleyebilmeli',
      );
    });
  }

  testWidgets('lohusalık bittikten sonra da ilk regl bekleniyor', (
    tester,
  ) async {
    await gebelikSonrasi(bitti: 50, sure: 278, sonuc: PregnancyOutcome.birth);
    final ctx = await ac(tester);
    expect(ctx.read<CalendarViewModel>().lifeStage, LifeStage.cycle);
    expect(find.text(ctx.tr('home_headline_after_pregnancy')), findsOneWidget);
  });

  testWidgets('ilk regl girilince normal başlığa dönüyor', (tester) async {
    await gebelikSonrasi(
      bitti: 40,
      sure: 70,
      sonuc: PregnancyOutcome.miscarriage,
    );
    // Kesintiden sonraki ilk regl, 10 gün önce başlayıp bitti.
    final eski = await const PeriodRepository().getPeriodLogs();
    await const PeriodRepository().savePeriodLogs([
      ...eski,
      PeriodLog(id: 'ilk', startDate: daysAgo(10), endDate: daysAgo(6)),
    ]);
    final ctx = await ac(tester);

    expect(find.text(ctx.tr('home_headline_after_pregnancy')), findsNothing);
    expect(
      find.text(ctx.tr('home_headline_cycle_day', params: {'n': '11'})),
      findsOneWidget,
      reason: 'Kesintiden sonra tek döngü var: tahmin yok, yalnızca döngü günü',
    );
  });

  testWidgets('hiç gebelik yokken boş durum değişmedi', (tester) async {
    final ctx = await ac(tester);
    expect(find.text(ctx.tr('home_headline_no_data')), findsOneWidget);
    expect(find.text(ctx.tr('home_headline_after_pregnancy')), findsNothing);
  });
}
