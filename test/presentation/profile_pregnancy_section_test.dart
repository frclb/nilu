import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/pregnancy/end_pregnancy_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_setup_screen.dart';
import 'package:period_tracker/presentation/profile/profile_settings_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Profildeki gebelik bölümü — her evrede yalnızca o evrenin işleri.
///
/// Gebelikte "gebeliğimi işaretle" ikinci bir gebelik açmaya çalışır;
/// döngüde "gebeliği sonlandır" sonlandıracak bir şey bulamaz. İkisi de
/// basılıp hiçbir şey olmayan satır demek.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  const evreler = {
    'döngü': (
      gorunur: ['profile_preg_mark', 'profile_preg_ttc'],
      gizli: ['profile_preg_due', 'profile_preg_care', 'profile_preg_end'],
    ),
    'gebelik': (
      gorunur: ['profile_preg_due', 'profile_preg_care', 'profile_preg_end'],
      gizli: ['profile_preg_mark', 'profile_preg_ttc'],
    ),
    'lohusalık': (
      gorunur: ['profile_preg_care'],
      gizli: [
        'profile_preg_mark',
        'profile_preg_ttc',
        'profile_preg_due',
        'profile_preg_end',
      ],
    ),
  };

  Future<void> kur(String evre) => switch (evre) {
    'gebelik' => seedPregnancy(),
    'lohusalık' => seedPostpartum(),
    _ => seedCycles(),
  };

  for (final e in evreler.entries) {
    for (final boyut in screenSizes.entries) {
      testWidgets('${e.key} — ${boyut.key}', (tester) async {
        await kur(e.key);
        await pumpRouter(
          tester,
          routes: pregnancyRoutes(const ProfileSettingsScreen()),
          size: boyut.value,
        );
        expect(tester.takeException(), isNull, reason: 'düzen hatası');
        final ctx = tester.element(find.byType(ProfileSettingsScreen));

        final bolum = find.text(ctx.upper(ctx.tr('profile_preg_section')));
        await tester.scrollUntilVisible(bolum, 300);
        expect(bolum, findsOneWidget);

        for (final k in e.value.gorunur) {
          final f = find.text(ctx.tr(k));
          await tester.scrollUntilVisible(f, 200);
          expect(f, findsOneWidget, reason: '$k görünmeli');
        }
        for (final k in e.value.gizli) {
          expect(
            find.text(ctx.tr(k), skipOffstage: false),
            findsNothing,
            reason: '$k bu evrede anlamsız',
          );
        }
      });
    }
  }

  testWidgets('gebe kalmaya çalışıyorum anahtarı niyeti açıp kapatıyor', (
    tester,
  ) async {
    await seedCycles();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const ProfileSettingsScreen()),
    );
    final vm = tester
        .element(find.byType(ProfileSettingsScreen))
        .read<PregnancyViewModel>();
    final anahtar = find.byKey(const Key('profile_ttc_switch'));
    await tester.scrollUntilVisible(anahtar, 300);

    await tester.tap(anahtar);
    await settleAsync(tester);
    expect(vm.conception, isNotNull);

    await tester.tap(anahtar);
    await settleAsync(tester);
    expect(vm.conception, isNull);
  });

  testWidgets('denemeye başlama tarihi yalnızca niyet açıkken, '
      'düzeltilebiliyor', (tester) async {
    await seedCycles();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const ProfileSettingsScreen()),
    );
    final ctx = tester.element(find.byType(ProfileSettingsScreen));
    final vm = ctx.read<PregnancyViewModel>();
    final satir = find.text(ctx.tr('profile_preg_ttc_since'));
    expect(satir, findsNothing, reason: 'Niyet yokken tarih anlamsız');

    final anahtar = find.byKey(const Key('profile_ttc_switch'));
    await tester.scrollUntilVisible(anahtar, 300);
    await tester.tap(anahtar);
    await settleAsync(tester);

    await tester.scrollUntilVisible(satir, 300);
    await tester.tap(satir);
    await tester.pumpAndSettle();

    final baslangic = daysAgo(90);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    String iki(int n) => n.toString().padLeft(2, '0');
    await tester.enterText(
      find.byType(TextField),
      '${iki(baslangic.day)}.${iki(baslangic.month)}.${baslangic.year}',
    );
    await tester.tap(find.text(MaterialLocalizations.of(ctx).okButtonLabel));
    await settleAsync(tester);

    expect(
      vm.conception?.since,
      DateTime(baslangic.year, baslangic.month, baslangic.day),
    );
  });

  testWidgets('gebeliğimi işaretle kurulum ekranını açıyor', (tester) async {
    await seedCycles();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const ProfileSettingsScreen()),
    );
    final ctx = tester.element(find.byType(ProfileSettingsScreen));
    final satir = find.text(ctx.tr('profile_preg_mark'));
    await tester.scrollUntilVisible(satir, 300);
    await tester.tap(satir);
    await settleAsync(tester);
    expect(find.byType(PregnancySetupScreen), findsOneWidget);
  });

  testWidgets('gebeliği sonlandır sonlandırma ekranını açıyor', (tester) async {
    await seedPregnancy();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const ProfileSettingsScreen()),
    );
    final ctx = tester.element(find.byType(ProfileSettingsScreen));
    final satir = find.text(ctx.tr('profile_preg_end'));
    await tester.scrollUntilVisible(satir, 300);
    await tester.tap(satir);
    await settleAsync(tester);
    expect(find.byType(EndPregnancyScreen), findsOneWidget);
  });
}
