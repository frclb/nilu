import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/home/home_screen.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_ring.dart';

import 'screen_harness.dart';

/// Halkanın hareketi: bugünün nabzı sınırlı, "Hareketi Azalt"a uyuluyor.
///
/// Nabız sürekli atsaydı ana ekran açık kaldıkça her kare yeniden çizilir,
/// pil gider ve ekran hiç "durulmazdı". Hareketi Azalt açıkken 1,7 saniyelik
/// dizi yenilemesi ve nabız, bu ayarı açan kullanıcıyı rahatsız eden şeyin
/// ta kendisi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(mockMissingPlatformChannels);

  dynamic painter(WidgetTester tester) => tester
      .widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(CycleRing),
              matching: find.byType(CustomPaint),
            )
            .first,
      )
      .painter;

  double progress(WidgetTester tester) => painter(tester).progress as double;
  double pulse(WidgetTester tester) => painter(tester).pulse as double;

  /// Üç gündür süren regl: bitirmek halkanın düzenini değiştiriyor.
  Future<HomeScreen> ac(WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({'onboarding_complete': true});
    await CycleSettingsRepository().saveCycleSettings(
      cycleLength: 28,
      periodLength: 6,
    );
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await const PeriodRepository().savePeriodLogs([
      PeriodLog(id: 'p', startDate: today.subtract(const Duration(days: 2))),
    ]);
    const screen = HomeScreen();
    await pumpScreen(tester, screen, size: const Size(390, 844));
    return screen;
  }

  testWidgets('bugünün nabzı üç kez atıp duruyor', (tester) async {
    await ac(tester);

    // Açılıştaki yenileme bitti, nabız başladı. Periyodik bir değeri tek
    // anda ölçmek döngü sınırına denk gelebiliyor; iki saniye boyunca
    // örnekleniyor.
    final ornekler = <double>[];
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      ornekler.add(pulse(tester));
    }
    expect(
      ornekler.any((v) => v > 0 && v < 1),
      isTrue,
      reason: 'Dizi yerine oturduktan sonra bugün nabız atmalı',
    );

    // Üç atış (3 × 1,6 sn) bitince hiçbir şey çalışmıyor.
    await tester.pump(const Duration(seconds: 6));
    expect(pulse(tester), 0, reason: 'Bitince boncukta halka asılı kalmamalı');
    expect(
      tester.binding.transientCallbackCount,
      0,
      reason: 'Ana ekran durulmalı: sürekli bir canlandırma pil harcar',
    );
  });

  testWidgets('Hareketi Azalt: yenileme anında, nabız yok', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final screen = await ac(tester);
    await tester.pump(const Duration(milliseconds: 2400));
    expect(pulse(tester), 0, reason: 'Hareketi Azalt açıkken nabız yok');

    final ctx = tester.element(find.byWidget(screen));
    await tester.tap(find.text(ctx.tr('home_period_end')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      progress(tester),
      1.0,
      reason: 'Halka düzeni değişti ama dizi yenilemesi atlanmalı',
    );
    expect(pulse(tester), 0);
  });
}
