import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/core/navigation/route_names.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/past_periods_screen.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/profile/cycle_settings_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Geçmiş reglleri toplu ekleme ekranı ve giriş noktaları.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  List<RouteBase> rotalar(Widget ilk) => [
    GoRoute(path: '/', builder: (_, _) => ilk),
    GoRoute(
      path: '/past_periods',
      name: RouteNames.pastPeriods,
      builder: (_, _) => const PastPeriodsScreen(),
    ),
  ];

  Finder gun(DateTime d) =>
      find.byKey(Key('past_periods_day_${d.year}_${d.month}_${d.day}'));

  Future<void> dokun(WidgetTester tester, Finder f) async {
    await tester.scrollUntilVisible(
      f,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
  }

  Future<CalendarViewModel> ac(WidgetTester tester) async {
    final router = await pumpRouter(
      tester,
      routes: rotalar(const SizedBox(key: Key('kok'))),
    );
    final takvim = tester
        .element(find.byKey(const Key('kok')))
        .read<CalendarViewModel>();
    router.pushNamed(RouteNames.pastPeriods);
    await settleAsync(tester);
    return takvim;
  }

  testWidgets('seçilen başlangıçlar ekleniyor, ekran kapanıyor', (
    tester,
  ) async {
    // 10, 38 ve 66 gün önce başlamış üç dönem.
    await seedCycles(lastStartAgo: 10);
    final takvim = await ac(tester);

    final kaydet = find.byKey(const Key('past_periods_save'));
    expect(
      tester.widget<FilledButton>(kaydet).onPressed,
      isNull,
      reason: 'Seçim yokken eklenecek bir şey yok',
    );

    await dokun(tester, gun(daysAgo(94)));
    await dokun(tester, gun(daysAgo(122)));
    expect(tester.widget<FilledButton>(kaydet).onPressed, isNotNull);

    await tester.tap(kaydet);
    await settleAsync(tester);

    expect(find.byType(PastPeriodsScreen), findsNothing);
    expect(takvim.periodLogs, hasLength(5));
    expect(takvim.isPeriodDay(daysAgo(94)), isTrue);
    expect(takvim.isPeriodDay(daysAgo(122)), isTrue);
    await tester.runAsync(() async {
      expect(await const PeriodRepository().getPeriodLogs(), hasLength(5));
    });
  });

  testWidgets('kayıtlı ve gelecek günler seçilemiyor', (tester) async {
    await seedCycles(lastStartAgo: 10);
    await ac(tester);

    for (final d in [daysAgo(10), daysAgo(8)]) {
      await tester.scrollUntilVisible(
        gun(d),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.widget<InkWell>(gun(d)).onTap, isNull, reason: '$d');
    }
    final yarin = today.add(const Duration(days: 1));
    if (yarin.month == today.month) {
      expect(tester.widget<InkWell>(gun(yarin)).onTap, isNull);
    }
  });

  testWidgets('seçili güne yeniden dokununca seçim kalkıyor', (tester) async {
    await seedCycles(lastStartAgo: 10);
    await ac(tester);

    await dokun(tester, gun(daysAgo(94)));
    await dokun(tester, gun(daysAgo(94)));
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('past_periods_save')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('gebelikte hiçbir şey eklenmiyor', (tester) async {
    await seedPregnancy();
    final takvim = await ac(tester);
    final once = takvim.periodLogs.length;
    expect(await takvim.addPastPeriodStarts([daysAgo(400)]), 0);
    expect(takvim.periodLogs, hasLength(once));
  });

  testWidgets('geçmiş gebeliğin aralığına regl eklenmiyor', (tester) async {
    // 160 gün önce başlayıp 100 gün önce düşükle biten gebelik: evre döngü,
    // ama aradaki günlerde kanama regl değil.
    final g = Pregnancy.fromLmp(
      lmp: daysAgo(160),
      cycleLength: 28,
      confirmedAt: daysAgo(130),
      id: 'g',
    ).ended(outcome: PregnancyOutcome.miscarriage, at: daysAgo(100));
    await tester.runAsync(() => const PregnancyRepository().upsert(g));
    await seedCycles(lastStartAgo: 10);
    final takvim = await ac(tester);

    expect(takvim.isInPregnancyBreak(daysAgo(130)), isTrue);
    await tester.scrollUntilVisible(
      gun(daysAgo(130)),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<InkWell>(gun(daysAgo(130))).onTap, isNull);
    expect(await takvim.addPastPeriodStarts([daysAgo(130)]), 0);
  });

  group('döngü ayarları', () {
    testWidgets('giriş satırı ekranı açıyor', (tester) async {
      await seedCycles(lastStartAgo: 10);
      await pumpRouter(tester, routes: rotalar(const CycleSettingsScreen()));
      final satir = find.byKey(const Key('cycle_settings_past_periods'));
      await tester.scrollUntilVisible(satir, 300);
      await tester.tap(satir);
      await settleAsync(tester);
      expect(find.byType(PastPeriodsScreen), findsOneWidget);
    });

    testWidgets('gebelikte giriş satırı yok', (tester) async {
      await seedPregnancy();
      await pumpRouter(tester, routes: rotalar(const CycleSettingsScreen()));
      expect(
        find.byKey(const Key('cycle_settings_past_periods')),
        findsNothing,
      );
    });

    testWidgets('gün birimi dile göre ("Gün" sabit yazılıyordu)', (
      tester,
    ) async {
      await pumpRouter(
        tester,
        routes: rotalar(const CycleSettingsScreen()),
        locale: const Locale('en'),
      );
      final ctx = tester.element(find.byType(CycleSettingsScreen));
      expect(find.textContaining('Gün'), findsNothing);
      expect(
        find.text(ctx.tr('cycle_settings_days', params: {'n': '28'})),
        findsOneWidget,
      );
    });
  });
}
