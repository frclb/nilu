import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/home/home_screen.dart';
import 'package:period_tracker/presentation/tour/app_tour.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// İlk girişte neyin nerede olduğunu anlatan tur.
void main() {
  setUpAll(mockMissingPlatformChannels);
  // Tur durumu süreç boyunca tek: yarıda kalan bir test sonrakine sızmasın.
  setUp(() => AppTour.active.value = false);

  Future<BuildContext> open(
    WidgetTester tester, {
    required bool pending,
  }) async {
    resetStores(onboarded: true);
    await seedCycles(lastStartAgo: 10);
    if (pending) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppTour.pendingKey, true);
    }
    const screen = HomeScreen();
    await pumpScreen(tester, screen, size: const Size(390, 844));
    return tester.element(find.byWidget(screen));
  }

  Future<void> waitForTour(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('kurulumdan sonra açılıyor, adım adım ilerliyor', (tester) async {
    final ctx = await open(tester, pending: true);
    await waitForTour(tester);

    expect(find.byKey(const Key('app_tour_card')), findsOneWidget);
    expect(find.text(ctx.tr('tour_masthead_title')), findsOneWidget);
    // Sekmeler bu ekranda yok (kabuk dışında çizildi): onların adımı
    // atlanıyor, tur ekrandaki üç hedefle sınırlı.
    expect(find.text('1 / 3'), findsOneWidget);

    await tester.tap(find.byKey(const Key('app_tour_next')));
    await tester.pumpAndSettle();
    expect(find.text(ctx.tr('tour_period_title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('app_tour_next')));
    await tester.pumpAndSettle();
    expect(find.text(ctx.tr('tour_fab_title')), findsOneWidget);
    expect(find.text(ctx.tr('tour_done')), findsOneWidget);

    await tester.tap(find.byKey(const Key('app_tour_next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app_tour_card')), findsNothing);
    expect(AppTour.active.value, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AppTour.pendingKey), isNull, reason: 'bir kez');
  });

  testWidgets('"Atla" turu kapatıyor', (tester) async {
    await open(tester, pending: true);
    await waitForTour(tester);
    await tester.tap(find.byKey(const Key('app_tour_skip')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('app_tour_card')), findsNothing);
    expect(AppTour.active.value, isFalse);
  });

  testWidgets('üstte bir pencere varken bekliyor, kapanınca açılıyor', (
    tester,
  ) async {
    // Uygulamadaki gibi: ana ekran sekmenin kendi gezgininde, pencere kök
    // gezginde. Ana ekranın rotası pencere açıkken de "en üstte" sayılıyor.
    resetStores(onboarded: true);
    await seedCycles(lastStartAgo: 10);
    final tab = Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
    await pumpScreen(tester, tab, size: const Size(390, 844));
    final ctx = tester.element(find.byType(HomeScreen));
    // Bildirim izni gerekçesi gibi kök gezgindeki bir pencere; tur onun
    // üstüne isteniyor (Profil'den "yeniden izle" ile aynı yol).
    showDialog<void>(
      context: ctx,
      useRootNavigator: true,
      builder: (_) => const AlertDialog(content: Text('izin')),
    );
    await tester.pump();
    await AppTour.replay();
    await waitForTour(tester);
    expect(find.byKey(const Key('app_tour_card')), findsNothing);

    Navigator.of(ctx, rootNavigator: true).pop();
    await waitForTour(tester);
    expect(find.byKey(const Key('app_tour_card')), findsOneWidget);
  });

  testWidgets('ana ekran görünür sekme değilken bekliyor', (tester) async {
    // go_router gizli sekmeyi `TickerMode` kapalı olarak tutuyor; ekran
    // yine yerleşiyor, hedefin dikdörtgeni gerçek görünüyor. Not: burada
    // hedefi görünür yere kaydıran animasyon da duruyor, yani bekleme iki
    // yoldan geliyor; asıl sınanan, sekme görünür olunca turun açılması.
    resetStores(onboarded: true);
    await seedCycles(lastStartAgo: 10);
    final active = ValueNotifier(false);
    final tab = ValueListenableBuilder<bool>(
      valueListenable: active,
      builder: (_, on, _) => TickerMode(enabled: on, child: const HomeScreen()),
    );
    await pumpScreen(tester, tab, size: const Size(390, 844));
    await AppTour.replay();
    await waitForTour(tester);
    expect(find.byKey(const Key('app_tour_card')), findsNothing);

    active.value = true;
    await waitForTour(tester);
    expect(find.byKey(const Key('app_tour_card')), findsOneWidget);
  });

  testWidgets('istenmemişse açılmıyor', (tester) async {
    await open(tester, pending: false);
    await waitForTour(tester);
    expect(find.byKey(const Key('app_tour_card')), findsNothing);
  });

  testWidgets('tur sürerken bekleyenler bitişi bekliyor', (tester) async {
    await open(tester, pending: true);
    await waitForTour(tester);
    var released = false;
    AppTour.whenIdle().then((_) => released = true);
    await tester.pump();
    expect(released, isFalse);
    await tester.tap(find.byKey(const Key('app_tour_skip')));
    await tester.pumpAndSettle();
    expect(released, isTrue);
  });
}
