import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/pregnancy/postpartum_home_screen.dart';
import 'package:period_tracker/presentation/profile/profile_settings_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Lohusalıktan "regl takibine dön".
///
/// Önceden lohusalıktan çıkmanın yolu yoktu: kullanıcı 42 gün boyunca
/// lohusa panosunda kalıyordu, ilk regli gelse bile işaretleyemiyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  Future<void> onayla(WidgetTester tester) async {
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pp_return_dialog')), findsOneWidget);
    await tester.tap(find.byKey(const Key('pp_return_confirm')));
    await settleAsync(tester);
  }

  testWidgets('profilden dönülüyor; ilk regl işaretlenebiliyor', (
    tester,
  ) async {
    await seedPostpartum(daysSinceBirth: 20);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const ProfileSettingsScreen()),
    );
    final ctx = tester.element(find.byType(ProfileSettingsScreen));
    final gebelik = ctx.read<PregnancyViewModel>();
    final takvim = ctx.read<CalendarViewModel>();
    expect(gebelik.stage, LifeStage.postpartum);
    expect(
      await tester.runAsync(() => takvim.togglePeriodDay(today)),
      isFalse,
      reason: 'Ön koşul: lohusalıkta regl işaretlenemiyor',
    );

    final satir = find.text(ctx.tr('pp_return_to_cycle'));
    await tester.scrollUntilVisible(satir, 300);
    await tester.tap(satir);
    await onayla(tester);

    expect(find.text(homeMarker), findsOneWidget, reason: 'Ana sekmeye dön');
    expect(gebelik.stage, LifeStage.cycle);
    expect(takvim.lifeStage, LifeStage.cycle);

    // Dönüşten sonra girilen regl kesintinin dışında: tahmin buradan
    // yeniden başlayacak.
    expect(await tester.runAsync(() => takvim.togglePeriodDay(today)), isTrue);
    await settleAsync(tester);
    expect(takvim.cycleInfo.lastPeriodStart, today);
  });

  testWidgets('vazgeçince lohusalık sürüyor', (tester) async {
    await seedPostpartum(daysSinceBirth: 20);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const ProfileSettingsScreen()),
    );
    final ctx = tester.element(find.byType(ProfileSettingsScreen));
    final satir = find.text(ctx.tr('pp_return_to_cycle'));
    await tester.scrollUntilVisible(satir, 300);
    await tester.tap(satir);
    await tester.pumpAndSettle();
    await tester.tap(find.text(ctx.tr('cancel')));
    await settleAsync(tester);

    expect(ctx.read<PregnancyViewModel>().stage, LifeStage.postpartum);
  });

  testWidgets('lohusa panosundan da dönülüyor', (tester) async {
    await seedPostpartum(daysSinceBirth: 5);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PostpartumHomeScreen()),
    );
    final gebelik = tester
        .element(find.byType(PostpartumHomeScreen))
        .read<PregnancyViewModel>();

    final dugme = find.byKey(const Key('pp_return_button'));
    await tester.scrollUntilVisible(dugme, 300);
    await tester.tap(dugme);
    await onayla(tester);

    expect(gebelik.stage, LifeStage.cycle);
  });
}
