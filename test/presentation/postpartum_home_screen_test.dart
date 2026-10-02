import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/pregnancy/danger_signs_screen.dart';
import 'package:period_tracker/presentation/pregnancy/postpartum_home_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Lohusalıkta ana sekme.
///
/// Lohia burada regl değil, **seyri izlenen** kanama. Seçim günün kaydına
/// yazılıyor; aynı günün belirtileri, notu kaybolmamalı. Seyir rehberdeki
/// tehlike örüntüsüne uyduğunda pano bunu söylemeli.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  for (final boyut in screenSizes.entries) {
    testWidgets('doğumdan sonra 10. gün — ${boyut.key}', (tester) async {
      await seedPostpartum(daysSinceBirth: 10);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PostpartumHomeScreen()),
        size: boyut.value,
      );
      expect(find.byType(PostpartumHomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'düzen hatası');
      final ctx = tester.element(find.byType(PostpartumHomeScreen));

      expect(find.text(ctx.tr('pp_day', params: {'n': '10'})), findsOneWidget);
      for (final kod in LogVocabulary.flowIntensities) {
        expect(find.byKey(Key('pp_lochia_$kod')), findsOneWidget);
      }
      expect(
        find.byKey(const Key('pp_lochia_concern')),
        findsNothing,
        reason: 'Kayıt yokken kaygı kartı',
      );
      expect(rawKeysOnScreen(tester), isEmpty);
    });
  }

  testWidgets('lohia seçimi bugünün kaydına yazılıyor, diğer alanlar kalıyor', (
    tester,
  ) async {
    await seedPostpartum(daysSinceBirth: 10);
    await const PeriodRepository().saveDailyLogs([
      DailyLog(
        date: today,
        symptoms: const ['fatigue'],
        moods: const ['calm'],
        notes: 'emzirme zor',
      ),
    ]);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PostpartumHomeScreen()),
    );
    final takvim = tester
        .element(find.byType(PostpartumHomeScreen))
        .read<CalendarViewModel>();

    await tester.ensureVisible(find.byKey(const Key('pp_lochia_medium')));
    await tester.tap(find.byKey(const Key('pp_lochia_medium')));
    await settleAsync(tester);

    final kayit = takvim.getDailyLogForDate(today);
    expect(kayit.flowIntensity, 'medium');
    expect(kayit.symptoms, ['fatigue'], reason: 'Belirti silindi');
    expect(kayit.moods, ['calm'], reason: 'Ruh hâli silindi');
    expect(kayit.notes, 'emzirme zor', reason: 'Not silindi');
    expect(
      takvim.isPeriodDay(today),
      isFalse,
      reason: 'Lohia regl olarak kaydedildi',
    );
    final secili = tester.widget<ChoiceChip>(
      find.byKey(const Key('pp_lochia_medium')),
    );
    expect(secili.selected, isTrue);
  });

  testWidgets('azaldıktan sonra yeniden artan kanama: kaygı kartı', (
    tester,
  ) async {
    await seedPostpartum(daysSinceBirth: 10);
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: daysAgo(8), flowIntensity: 'heavy'),
      DailyLog(date: daysAgo(5), flowIntensity: 'light'),
      DailyLog(date: daysAgo(1), flowIntensity: 'medium'),
    ]);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PostpartumHomeScreen()),
    );
    final ctx = tester.element(find.byType(PostpartumHomeScreen));

    expect(find.byKey(const Key('pp_lochia_concern')), findsOneWidget);
    expect(find.text(ctx.tr('pp_concern_reincrease_title')), findsOneWidget);

    await tester.tap(find.text(ctx.tr('pp_concern_action')));
    await settleAsync(tester);
    final ekran = tester.widget<DangerSignsScreen>(
      find.byType(DangerSignsScreen),
    );
    expect(ekran.period, DangerPeriod.postpartum);
  });

  testWidgets('azalarak süren kanama: kart yok', (tester) async {
    await seedPostpartum(daysSinceBirth: 10);
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: daysAgo(8), flowIntensity: 'heavy'),
      DailyLog(date: daysAgo(5), flowIntensity: 'medium'),
      DailyLog(date: daysAgo(1), flowIntensity: 'light'),
    ]);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PostpartumHomeScreen()),
    );
    expect(find.byKey(const Key('pp_lochia_concern')), findsNothing);
  });
}
