import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/pregnancy/care_text.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Takvimde gebelik: seçili günün haftası ve ayı, randevular, tahmini doğum.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  Future<BuildContext> ac(WidgetTester tester) async {
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const CalendarScreen()),
      size: const Size(390, 1400),
    );
    return tester.element(find.byType(CalendarScreen));
  }

  Finder cip() => find.byKey(const Key('calendar_day_chip'));
  String cipMetni(WidgetTester tester) => tester.widget<Text>(cip()).data!;

  testWidgets('gebelikte başlıkta döngü günü değil hafta ve ay', (
    tester,
  ) async {
    await seedPregnancy(weeks: 24, days: 2);
    final ctx = await ac(tester);
    expect(cipMetni(tester), '24+2 · ${ctx.monthLabel(6)}');
    expect(tester.takeException(), isNull);
  });

  testWidgets('bugünkü randevu hücrede işaretli ve başlıkta yazılı', (
    tester,
  ) async {
    final g = await seedPregnancy(weeks: 24, days: 2);
    await const CareRepository().upsert(
      CareEvent.custom(
        pregnancyId: g.id,
        title: 'Diş kontrolü',
        scheduledAt: DateTime(today.year, today.month, today.day, 10, 30),
      ),
    );
    await ac(tester);
    expect(find.byKey(const Key('calendar_appointment_mark')), findsOneWidget);
    expect(find.text('Diş kontrolü · 10:30'), findsOneWidget);
  });

  testWidgets('tahmini doğum günü yıldızla işaretli', (tester) async {
    final g = await seedPregnancy(weeks: 39, days: 0);
    final ctx = await ac(tester);
    final takvim = ctx.read<CalendarViewModel>();
    final edd = g.estimatedDueDate;
    while (takvim.currentMonth.month != edd.month ||
        takvim.currentMonth.year != edd.year) {
      takvim.nextMonth();
    }
    takvim.selectDate(edd);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar_due_mark')), findsOneWidget);
    expect(find.text(ctx.tr('calendar_due_date')), findsOneWidget);
    expect(cipMetni(tester), '40+0 · ${ctx.monthLabel(9)}');
  });

  testWidgets('lohusalıkta doğumdan sonraki gün', (tester) async {
    await seedPostpartum(daysSinceBirth: 10);
    final ctx = await ac(tester);
    expect(
      cipMetni(tester),
      ctx.tr('care_summary_pp_day', params: {'n': '10'}),
    );
  });

  testWidgets('lejant: gebelikte randevu ve tahmini doğum var', (tester) async {
    await seedPregnancy();
    final ctx = await ac(tester);
    expect(find.text(ctx.tr('calendar_legend_appointment')), findsOneWidget);
    expect(find.text(ctx.tr('calendar_legend_due')), findsOneWidget);
  });

  testWidgets('lejant: döngüde yok', (tester) async {
    await seedCycles();
    final ctx = await ac(tester);
    expect(find.text(ctx.tr('calendar_legend_appointment')), findsNothing);
    expect(find.text(ctx.tr('calendar_legend_due')), findsNothing);
  });

  testWidgets('düşükle biten gebeliğin haftası takvimde görünmüyor', (
    tester,
  ) async {
    final g = Pregnancy.fromLmp(
      lmp: daysAgo(70),
      cycleLength: 28,
      confirmedAt: daysAgo(30),
      id: 'g1',
    ).ended(outcome: PregnancyOutcome.miscarriage, at: daysAgo(5));
    await const PregnancyRepository().upsert(g);
    final ctx = await ac(tester);
    final takvim = ctx.read<CalendarViewModel>();
    // Gebeliğin içindeki bir gün; takvim o aya götürülüyor.
    final hedef = daysAgo(10);
    expect(
      !hedef.isBefore(g.gestationStart) && hedef.isBefore(g.endedAt!),
      isTrue,
      reason: 'Ön koşul: gün gebeliğin içinde',
    );
    while (takvim.currentMonth.month != hedef.month ||
        takvim.currentMonth.year != hedef.year) {
      takvim.previousMonth();
    }
    takvim.selectDate(hedef);
    await tester.pumpAndSettle();

    final metin = cip().evaluate().isEmpty ? '' : cipMetni(tester);
    expect(metin, isNot(contains('+')), reason: 'Kaybın haftası gösterildi');
  });
}
