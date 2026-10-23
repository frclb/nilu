import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/domain/models/calendar_day.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/pregnancy/care_list_screen.dart';
import 'package:period_tracker/presentation/pregnancy/care_text.dart';
import 'package:period_tracker/presentation/pregnancy/danger_signs_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_home_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_months_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Gebelikte ana sekme.
///
/// Panonun söylediği her şey veriden geliyor: hafta, trimester, sıradaki
/// kontrol. Biri kaysa ekran yine düzgün görünür ama yanlış bilgi verir —
/// "24+2" yerine "24+3" yazan bir pano hekimin söylediğiyle çelişir.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  for (final boyut in screenSizes.entries) {
    testWidgets('24+2 haftalık gebe — ${boyut.key}', (tester) async {
      final g = await seedPregnancy(weeks: 24, days: 2);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PregnancyHomeScreen()),
        size: boyut.value,
      );

      expect(find.byType(PregnancyHomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'düzen hatası');
      final ctx = tester.element(find.byType(PregnancyHomeScreen));

      expect(
        find.text('24+2'),
        findsOneWidget,
        reason: 'Halkanın ortasında tamamlanan hafta + gün yazmalı',
      );
      expect(
        find.text(
          ctx.tr('preg_week_day_sentence', params: {'w': '24', 'd': '2'}),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          ctx.upper(
            '${ctx.monthLabel(6)} · '
            '${ctx.tr('preg_trimester_label', params: {'n': '2'})}',
          ),
        ),
        findsOneWidget,
        reason: '24+2: 6. ay, ikinci trimester',
      );

      // Sıradaki kontrol: Türkiye şemasında 24. haftada açık kalem var.
      final vm = ctx.read<PregnancyViewModel>();
      final siradaki = NextCareCard.siradaki(vm.currentEvents, g, today);
      expect(siradaki, isNotNull);
      expect(
        siradaki!.category,
        isNot(CareCategory.supplement),
        reason: '24. haftada sıradaki iş izlem ya da tarama; D vitamini değil',
      );
      expect(find.text(ctx.careTitle(siradaki)), findsOneWidget);
      expect(find.text(ctx.tr('preg_next_care_none')), findsNothing);

      expect(find.text(ctx.tr('preg_danger_entry_title')), findsOneWidget);
      expect(rawKeysOnScreen(tester), isEmpty);
    });
  }

  testWidgets('ay kartı aylar ekranını açıyor', (tester) async {
    await seedPregnancy(weeks: 24, days: 2);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancyHomeScreen()),
    );
    final kart = find.byKey(const Key('preg_months_card'));
    await tester.ensureVisible(kart);
    // Kaydırma bir sonraki karede yerleşiyor; dokunmadan önce çiz.
    await tester.pump();
    await tester.tap(kart);
    await settleAsync(tester);
    expect(find.byType(PregnancyMonthsScreen), findsOneWidget);
  });

  testWidgets('kalan gün tahmini doğuma göre', (tester) async {
    final g = await seedPregnancy(weeks: 24, days: 2);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancyHomeScreen()),
    );
    final ctx = tester.element(find.byType(PregnancyHomeScreen));
    final kalan = g.estimatedDueDate.daysSince(today);
    expect(kalan, 280 - (24 * 7 + 2));
    expect(find.text(ctx.dueCountdown(kalan)), findsOneWidget);
  });

  testWidgets('tehlike kartı gebelik listesini açıyor', (tester) async {
    await seedPregnancy();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancyHomeScreen()),
    );
    final ctx = tester.element(find.byType(PregnancyHomeScreen));

    await tester.ensureVisible(find.text(ctx.tr('preg_danger_entry_title')));
    await tester.pump();
    await tester.tap(find.text(ctx.tr('preg_danger_entry_title')));
    await settleAsync(tester);

    final ekran = tester.widget<DangerSignsScreen>(
      find.byType(DangerSignsScreen),
    );
    expect(ekran.period, DangerPeriod.pregnancy);
  });

  testWidgets('sıradaki kontrol kartı randevuları açıyor', (tester) async {
    await seedPregnancy();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancyHomeScreen()),
    );
    final ctx = tester.element(find.byType(PregnancyHomeScreen));

    await tester.tap(find.text(ctx.upper(ctx.tr('preg_next_care'))));
    await settleAsync(tester);
    expect(find.byType(CareListScreen), findsOneWidget);
  });

  testWidgets('İngilizcede tekil ve çoğul ayrı', (tester) async {
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const SizedBox(key: Key('kok'))),
      locale: const Locale('en'),
    );
    final ctx = tester.element(find.byKey(const Key('kok')));

    final cumleler = [
      ctx.gestationSentence(const GestationalAge(24, 1)),
      ctx.dueCountdown(1),
      ctx.dueCountdown(-1),
    ];
    for (final c in cumleler) {
      expect(c, isNot(contains('1 days')), reason: c);
      expect(c, contains('1 day'), reason: c);
    }
    expect(
      ctx.gestationSentence(const GestationalAge(24, 0)),
      isNot(contains('0 day')),
      reason: 'Tam haftada gün yazılmamalı',
    );
    expect(
      ctx.gestationSentence(const GestationalAge(24, 3)),
      contains('3 days'),
    );
    expect(ctx.dueCountdown(12), contains('12 days'));
    expect(ctx.dueCountdown(-3), contains('3 days'));
    expect(ctx.dueCountdown(0), isNot(contains('0')));
  });
}
