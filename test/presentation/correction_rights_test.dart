import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/core/navigation/route_names.dart';
import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/day_detail_bottom_sheet.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
import 'package:period_tracker/presentation/pregnancy/end_pregnancy_screen.dart';
import 'package:period_tracker/presentation/pregnancy/past_pregnancies_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Düzeltme hakkı: kullanıcının verisi kullanıcının.
///
/// Ölçüm yalnızca bugüne girilebiliyordu; dün akşamki tansiyon ya da
/// muayenedeki kilo hiç yazılamıyordu. Yanlışlıkla eklenen bir gebelik
/// silinemiyor, yalnızca "sonlandırılabiliyor" ve geçmiş gebeliklerde
/// kalıyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  String gun(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<(CalendarViewModel, BuildContext)> ac(
    WidgetTester tester,
    String? tarih,
  ) async {
    final router = await pumpRouter(
      tester,
      routes: pregnancyRoutes(const SizedBox(key: Key('kok'))),
    );
    final kok = tester.element(find.byKey(const Key('kok')));
    router.pushNamed(RouteNames.logEntry, queryParameters: {'date': ?tarih});
    await settleAsync(tester);
    return (kok.read<CalendarViewModel>(), kok);
  }

  Future<void> yaz(WidgetTester tester, String alan, String deger) async {
    final f = find.byKey(Key(alan));
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.enterText(f, deger);
    await tester.pump();
  }

  group('geçmiş güne ölçüm', () {
    testWidgets('üç gün önceye girilen tansiyon o güne yazılıyor', (
      tester,
    ) async {
      await seedPregnancy();
      final (takvim, _) = await ac(tester, gun(daysAgo(3)));
      final ctx = tester.element(find.byType(LogEntryScreen));
      expect(
        find.text(ctx.tr('log_date_today', params: {'day': '', 'month': ''})),
        findsNothing,
      );

      await yaz(tester, 'log_measure_systolic', '118');
      await yaz(tester, 'log_measure_diastolic', '76');
      await tester.tap(find.text(ctx.tr('log_save_button')));
      await settleAsync(tester);

      final o = takvim.getDailyLogForDate(daysAgo(3));
      expect((o.systolic, o.diastolic), (118, 76));
      expect(takvim.getDailyLogForDate(today).systolic, isNull);
    });

    testWidgets('gelecek gün bugüne çekiliyor', (tester) async {
      await seedPregnancy();
      final (takvim, _) = await ac(
        tester,
        gun(today.add(const Duration(days: 5))),
      );
      final ctx = tester.element(find.byType(LogEntryScreen));
      await yaz(tester, 'log_measure_weight', '64');
      await tester.tap(find.text(ctx.tr('log_save_button')));
      await settleAsync(tester);
      expect(takvim.getDailyLogForDate(today).weightKg, 64);
    });

    testWidgets('gün sayfası gebelikte ölçüm girişine götürüyor', (
      tester,
    ) async {
      await seedPregnancy();
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => DayDetailBottomSheet(date: daysAgo(2)),
                  ),
                  child: const Text('ac'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ac'));
      await settleAsync(tester);
      await tester.tap(find.byKey(const Key('day_detail_measure')));
      await settleAsync(tester);
      expect(find.byType(LogEntryScreen), findsOneWidget);
      expect(
        tester.widget<LogEntryScreen>(find.byType(LogEntryScreen)).date,
        daysAgo(2),
      );
    });
  });

  group('gebelik kaydını silme', () {
    testWidgets('sonlandırma ekranından silinince evre döngüye dönüyor', (
      tester,
    ) async {
      final g = await seedPregnancy();
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const EndPregnancyScreen()),
      );
      final ctx = tester.element(find.byType(EndPregnancyScreen));
      final vm = ctx.read<PregnancyViewModel>();
      expect(vm.stage, LifeStage.pregnancy);

      await tester.ensureVisible(find.byKey(const Key('preg_delete')));
      await tester.tap(find.byKey(const Key('preg_delete')));
      await tester.pumpAndSettle();
      expect(find.text(ctx.tr('preg_delete_body')), findsOneWidget);
      await tester.tap(find.byKey(const Key('preg_delete_confirm')));
      await settleAsync(tester);

      expect(find.text(homeMarker), findsOneWidget);
      expect(vm.stage, LifeStage.cycle);
      expect(vm.pregnancies, isEmpty);
      expect(
        await tester.runAsync(() => const CareRepository().forPregnancy(g.id)),
        isEmpty,
        reason: 'Randevular ve hatırlatıcılar da gitmeli',
      );
      expect(
        vm.pastPregnancies,
        isEmpty,
        reason: 'Geçmiş gebeliklerde "bitmiş" görünmemeli',
      );
    });

    testWidgets('geçmiş gebelikler listesinden silinebiliyor', (tester) async {
      final g = await seedPostpartum(daysSinceBirth: 120);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PastPregnanciesScreen()),
      );
      await tester.tap(find.byKey(Key('past_preg_delete_${g.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('preg_delete_confirm')));
      await settleAsync(tester);

      expect(find.byKey(Key('past_preg_${g.id}')), findsNothing);
      expect(
        await tester.runAsync(() => const PregnancyRepository().getAll()),
        isEmpty,
      );
    });
  });
}
