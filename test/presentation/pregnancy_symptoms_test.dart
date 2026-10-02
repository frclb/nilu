import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/day_detail_bottom_sheet.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
import 'package:period_tracker/presentation/log_entry/widgets/symptoms_section.dart';
import 'package:period_tracker/presentation/pregnancy/danger_signs_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Gebelik belirti sözlüğü (Faz 2).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  group('sözlük', () {
    test('gebelik belirtisi kaydedilip okununca kaybolmuyor', () {
      // Okuma döngü listesiyle süzülseydi "bulantı" sessizce düşerdi.
      final k = DailyLog(
        date: today,
        symptoms: const ['nausea', 'headache', 'braxton_hicks'],
      );
      expect(DailyLog.fromMap(k.toMap()).symptoms, [
        'nausea',
        'headache',
        'braxton_hicks',
      ]);
    });

    test('gebelikte gebelik belirtileri önde, genel belirtiler de var', () {
      final liste = LogVocabulary.symptomsFor(LifeStage.pregnancy);
      expect(
        liste.take(LogVocabulary.pregnancySymptoms.length),
        LogVocabulary.pregnancySymptoms,
      );
      expect(liste, containsAll(LogVocabulary.symptoms));
    });

    test('döngüde ve lohusalıkta gebelik belirtileri yok', () {
      for (final evre in [LifeStage.cycle, LifeStage.postpartum]) {
        expect(
          LogVocabulary.symptomsFor(
            evre,
          ).toSet().intersection(LogVocabulary.pregnancySymptoms.toSet()),
          isEmpty,
          reason: evre.name,
        );
      }
    });

    test('uyarı belirtilerinin hepsi gebelikte seçilebiliyor', () {
      expect(
        LogVocabulary.symptomsFor(LifeStage.pregnancy),
        containsAll(LogVocabulary.pregnancyWarningSymptoms),
      );
    });
  });

  group('kayıt ekranı', () {
    Future<CalendarViewModel> ac(WidgetTester tester) async {
      final router = await pumpRouter(
        tester,
        routes: pregnancyRoutes(const SizedBox(key: Key('kok'))),
      );
      final takvim = tester
          .element(find.byKey(const Key('kok')))
          .read<CalendarViewModel>();
      router.pushNamed('log_entry');
      await settleAsync(tester);
      return takvim;
    }

    BuildContext ctx(WidgetTester tester) =>
        tester.element(find.byType(LogEntryScreen));

    Finder belirti(WidgetTester tester, String kod) => find.descendant(
      of: find.byType(SymptomsSection),
      matching: find.text(ctx(tester).tr(LogVocabulary.symptomKey(kod))),
    );

    Future<void> dokun(WidgetTester tester, Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pump();
    }

    Finder not() => find.byKey(const Key('log_preg_symptom_note'));

    testWidgets('gebelikte bulantı seçilip kaydediliyor ve kalıcı', (
      tester,
    ) async {
      await seedPregnancy();
      final takvim = await ac(tester);

      await dokun(tester, belirti(tester, 'nausea'));
      await tester.tap(find.text(ctx(tester).tr('log_save_button')));
      await settleAsync(tester);

      expect(takvim.getDailyLogForDate(today).symptoms, ['nausea']);
      final depo = await tester.runAsync(
        () => const PeriodRepository().getDailyLogs(),
      );
      expect(
        depo!.singleWhere((l) => DateUtils.isSameDay(l.date, today)).symptoms,
        ['nausea'],
        reason: 'Depodan okununca bulantı düştü',
      );
    });

    testWidgets('döngüde gebelik belirtileri listede yok', (tester) async {
      await seedCycles();
      await ac(tester);
      expect(belirti(tester, 'nausea'), findsNothing);
      expect(belirti(tester, 'headache'), findsOneWidget);
    });

    testWidgets('gebelikte baş ağrısı seçilince not çıkıyor, kaldırınca '
        'kayboluyor', (tester) async {
      await seedPregnancy();
      await ac(tester);

      expect(not(), findsNothing);
      await dokun(tester, belirti(tester, 'headache'));
      expect(not(), findsOneWidget);
      await dokun(tester, belirti(tester, 'headache'));
      expect(not(), findsNothing);

      await dokun(tester, belirti(tester, 'nausea'));
      expect(not(), findsNothing, reason: 'Bulantı tehlike listesinde değil');
    });

    testWidgets('döngüde baş ağrısı notu çıkarmıyor', (tester) async {
      await seedCycles();
      await ac(tester);
      await dokun(tester, belirti(tester, 'headache'));
      expect(not(), findsNothing);
    });

    testWidgets('not tehlike listesini açıyor; geri dönünce kayıt sürüyor', (
      tester,
    ) async {
      await seedPregnancy();
      await ac(tester);
      await dokun(tester, belirti(tester, 'swelling'));

      final eylem = find.descendant(
        of: not(),
        matching: find.text(ctx(tester).tr('danger_signs_action')),
      );
      await dokun(tester, eylem);
      await settleAsync(tester);
      expect(
        tester.widget<DangerSignsScreen>(find.byType(DangerSignsScreen)).period,
        DangerPeriod.pregnancy,
      );

      GoRouter.of(tester.element(find.byType(DangerSignsScreen))).pop();
      await settleAsync(tester);
      expect(find.byType(LogEntryScreen), findsOneWidget);
      expect(not(), findsOneWidget, reason: 'Seçim kaybolmamalı');
    });
  });

  testWidgets('gün ayrıntısı gebelikte gebelik belirtilerini gösteriyor', (
    tester,
  ) async {
    await seedPregnancy();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const SizedBox(key: Key('kok'))),
    );
    final c = tester.element(find.byKey(const Key('kok')));
    showDayDetailSheet(c, today);
    await tester.pumpAndSettle();
    expect(
      find.text(c.tr(LogVocabulary.symptomKey('heartburn'))),
      findsOneWidget,
    );
  });
}
