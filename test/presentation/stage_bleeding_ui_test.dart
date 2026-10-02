import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/day_detail_bottom_sheet.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
import 'package:period_tracker/presentation/log_entry/widgets/flow_intensity_section.dart';
import 'package:period_tracker/presentation/pregnancy/danger_signs_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Regl kaydının tutulmadığı evrelerde kanama arayüzü.
///
/// Gebelikte kanama tehlike işareti, lohusalıkta lohia — ikisi de regl
/// değil. Önceden "Regl işaretle" düğmesi duruyordu, koruma basışı
/// reddediyordu ve ekran "gelecek bir tarihe regl girilemez" diyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  Finder not() => find.byKey(const Key('stage_bleeding_note'));

  group('takvim', () {
    final durumlar = <String, Future<void> Function()>{
      'döngü': () => seedCycles(),
      'gebelik': () => seedPregnancy(),
      'lohusalık': () => seedPostpartum(),
    };

    for (final d in durumlar.entries) {
      for (final boyut in screenSizes.entries) {
        testWidgets('${d.key} — ${boyut.key}', (tester) async {
          await d.value();
          await pumpRouter(
            tester,
            routes: pregnancyRoutes(const CalendarScreen()),
            size: boyut.value,
          );
          expect(find.byType(CalendarScreen), findsOneWidget);
          expect(tester.takeException(), isNull, reason: 'düzen hatası');
          final ctx = tester.element(find.byType(CalendarScreen));
          final evre = ctx.read<CalendarViewModel>().lifeStage;

          final isaretle = find.text(
            ctx.tr('calendar_mark_period'),
            skipOffstage: false,
          );
          final notEkle = find.text(
            ctx.tr('calendar_add_note'),
            skipOffstage: false,
          );
          expect(notEkle, findsOneWidget, reason: 'Not her evrede eklenir');

          if (d.key == 'döngü') {
            expect(evre, LifeStage.cycle);
            expect(isaretle, findsOneWidget);
            expect(find.byKey(const Key('stage_bleeding_note')), findsNothing);
          } else {
            expect(evre.recordsPeriods, isFalse);
            expect(
              isaretle,
              findsNothing,
              reason: 'Basılınca reddedilecek bir düğme duruyor',
            );
            expect(
              find.byKey(const Key('stage_bleeding_note'), skipOffstage: false),
              findsOneWidget,
            );
            expect(
              find.text(
                ctx.tr(
                  d.key == 'gebelik'
                      ? 'calendar_preg_bleeding_note'
                      : 'calendar_pp_bleeding_note',
                ),
                skipOffstage: false,
              ),
              findsOneWidget,
            );
          }
        });
      }
    }
  });

  testWidgets('gün ayrıntısı: gebelikte regl anahtarı yok, not var', (
    tester,
  ) async {
    await seedPregnancy();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const SizedBox(key: Key('kok'))),
    );
    final ctx = tester.element(find.byKey(const Key('kok')));
    showDayDetailSheet(ctx, today);
    await tester.pumpAndSettle();

    expect(find.text(ctx.tr('day_detail_period_toggle')), findsNothing);
    expect(not(), findsOneWidget);
  });

  testWidgets('gün ayrıntısı: döngüde regl anahtarı var', (tester) async {
    await seedCycles();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const SizedBox(key: Key('kok'))),
    );
    final ctx = tester.element(find.byKey(const Key('kok')));
    showDayDetailSheet(ctx, today);
    await tester.pumpAndSettle();

    expect(find.text(ctx.tr('day_detail_period_toggle')), findsOneWidget);
    expect(not(), findsNothing);
  });

  group('kayıt ekranı', () {
    /// Kayıt ekranını bir ana ekranın üstünde açar — uygulamadaki gibi.
    Future<BuildContext> ac(WidgetTester tester) async {
      final router = await pumpRouter(
        tester,
        routes: pregnancyRoutes(const SizedBox(key: Key('kok'))),
      );
      final ctx = tester.element(find.byKey(const Key('kok')));
      router.pushNamed('log_entry');
      await settleAsync(tester);
      expect(find.byType(LogEntryScreen), findsOneWidget);
      return ctx;
    }

    Future<void> kanamaKaydet(WidgetTester tester, BuildContext ctx) async {
      // "Orta" ağrı bölümünde de var; akış bölümüyle sınırlı.
      await tester.tap(
        find.descendant(
          of: find.byType(FlowIntensitySection),
          matching: find.text(ctx.tr('log_flow_medium')),
        ),
      );
      await tester.pump();
      await tester.tap(find.text(ctx.tr('log_save_button')));
      await settleAsync(tester);
    }

    testWidgets('gebelikte kanama: uyarı çıkıyor, regl açılmıyor', (
      tester,
    ) async {
      await seedPregnancy();
      final ctx = await ac(tester);
      final takvim = ctx.read<CalendarViewModel>();

      await kanamaKaydet(tester, ctx);

      expect(find.byKey(const Key('preg_bleeding_dialog')), findsOneWidget);
      expect(takvim.isPeriodDay(today), isFalse, reason: 'Regl açıldı');
      expect(
        takvim.getDailyLogForDate(today).flowIntensity,
        'medium',
        reason: 'Kayıt kaybolmamalı; yalnızca regl sayılmıyor',
      );

      await tester.tap(find.text(ctx.tr('ok')));
      await settleAsync(tester);
      expect(find.byType(LogEntryScreen), findsNothing);
    });

    testWidgets('uyarıdan tehlike işaretlerine gidince o ekran açık kalıyor', (
      tester,
    ) async {
      await seedPregnancy();
      final ctx = await ac(tester);

      await kanamaKaydet(tester, ctx);
      await tester.tap(find.byKey(const Key('preg_bleeding_dialog_danger')));
      await settleAsync(tester);

      // Önce: diyalog tehlike ekranını açıyor, ardından kayıt ekranını
      // kapatmak için çağrılan `pop` yeni açılan ekranı kapatıyordu.
      expect(
        find.byType(DangerSignsScreen),
        findsOneWidget,
        reason: 'Tehlike işaretleri ekranı açılıp hemen kapandı',
      );
      expect(
        tester.widget<DangerSignsScreen>(find.byType(DangerSignsScreen)).period,
        DangerPeriod.pregnancy,
      );
      expect(
        find.byType(LogEntryScreen),
        findsNothing,
        reason: 'Kayıt ekranı kapanmalı; geri dönünce yine onu görmesin',
      );

      // Geri dönünce ana ekran.
      GoRouter.of(ctx).pop();
      await settleAsync(tester);
      expect(find.byKey(const Key('kok')), findsOneWidget);
    });

    testWidgets('döngüde kanama: uyarı yok, regl başlıyor', (tester) async {
      await seedCycles(lastStartAgo: 26);
      final ctx = await ac(tester);
      final takvim = ctx.read<CalendarViewModel>();

      await kanamaKaydet(tester, ctx);

      expect(find.byKey(const Key('preg_bleeding_dialog')), findsNothing);
      expect(takvim.isPeriodDay(today), isTrue);
    });
  });
}
