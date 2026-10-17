import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/phase_guide.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/calendar/widgets/day_detail_bottom_sheet.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_masthead.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Döngüye özgü metinler yalnızca döngüde; bilinmeyen döngü süresi
/// "senin döngün" diye yazılmıyor.
///
/// Üçü de simülatörde görüldü: gebe kullanıcıya takvimin gün sayfası
/// "Doğurganlık şansı: düşük", günün özeti "regl günlerini işaretledikçe
/// tahminler netleşir" diyordu; kurulumu gebelik yolundan yapan kullanıcı
/// gebelik bitince halkada hiç söylemediği "28 günlük döngü"yü görüyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  final evreler = <String, Future<void> Function()>{
    'döngü': () => seedCycles(),
    'gebelik': () => seedPregnancy(),
    'lohusalık': () => seedPostpartum(),
  };

  Iterable<String> metinler(BuildContext ctx, Iterable<String> anahtarlar) =>
      anahtarlar.map((k) => ctx.tr(k));

  group('gün sayfasında doğurganlık satırı', () {
    const anahtarlar = [
      'day_detail_fertility_low',
      'day_detail_fertility_high',
      'day_detail_fertility_peak',
    ];
    for (final e in evreler.entries) {
      testWidgets(e.key, (tester) async {
        await e.value();
        await pumpRouter(
          tester,
          routes: pregnancyRoutes(const SizedBox(key: Key('kok'))),
        );
        final ctx = tester.element(find.byKey(const Key('kok')));
        showDayDetailSheet(ctx, today);
        await tester.pumpAndSettle();

        final gorunen = metinler(
          ctx,
          anahtarlar,
        ).where((m) => find.text(m).evaluate().isNotEmpty);
        expect(
          gorunen,
          e.key == 'döngü' ? hasLength(1) : isEmpty,
          reason: e.key == 'döngü'
              ? 'Döngüde doğurganlık satırı olmalı'
              : 'Gebelikte ve lohusalıkta doğurganlık tahmini yok',
        );
      });
    }
  });

  group('günün özetinde döngü evresi', () {
    for (final e in evreler.entries) {
      testWidgets(e.key, (tester) async {
        await e.value();
        await pumpRouter(
          tester,
          routes: pregnancyRoutes(const CalendarScreen()),
          size: const Size(390, 2400),
        );
        final ctx = tester.element(find.byType(CalendarScreen));
        final basliklar = metinler(
          ctx,
          CyclePhase.values.map((p) => PhaseGuide.forPhase(p).titleKey),
        );
        final gorunen = basliklar.where(
          (m) => find.text(m).evaluate().isNotEmpty,
        );
        expect(
          gorunen,
          e.key == 'döngü' ? isNotEmpty : isEmpty,
          reason: e.key == 'döngü'
              ? 'Döngüde evre bloğu olmalı'
              : 'Gebelikte ve lohusalıkta "tahminler netleşir" denmemeli',
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('halkada döngü süresi', () {
    Future<BuildContext> ac(WidgetTester tester) async {
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(
          const Scaffold(body: SingleChildScrollView(child: CycleMasthead())),
        ),
      );
      return tester.element(find.byType(CycleMasthead));
    }

    String sure(BuildContext ctx, int n) =>
        ctx.tr('home_ring_cycle_length', params: {'n': '$n'});

    testWidgets('gebelik yolundan gelen: süre söylenmedi, kayıt yok', (
      tester,
    ) async {
      // Kurulumda "Hamileyim": döngü ayarı yazılmadı. Gebelik düşükle
      // bitti; ardından henüz regl kaydı yok.
      await const PregnancyRepository().upsert(
        Pregnancy.fromLmp(
          lmp: daysAgo(150),
          cycleLength: 28,
          id: 'g',
        ).ended(outcome: PregnancyOutcome.miscarriage, at: daysAgo(80)),
      );
      final ctx = await ac(tester);
      expect(
        find.text(ctx.tr('home_ring_cycle_length_unknown')),
        findsOneWidget,
      );
      expect(find.text(sure(ctx, 28)), findsNothing);
    });

    testWidgets('kurulumda söylenen süre yazılıyor', (tester) async {
      await const CycleSettingsRepository().saveInitialSettings(
        cycleLength: 30,
        periodLength: 5,
      );
      await const PeriodRepository().savePeriodLogs([
        PeriodLog(id: 'p', startDate: daysAgo(10), endDate: daysAgo(6)),
      ]);
      final ctx = await ac(tester);
      expect(find.text(sure(ctx, 30)), findsOneWidget);
      expect(find.text(ctx.tr('home_ring_cycle_length_unknown')), findsNothing);
    });

    testWidgets('kayıtlardan çıkan süre yazılıyor', (tester) async {
      await seedCycles();
      final ctx = await ac(tester);
      expect(find.text(sure(ctx, 28)), findsOneWidget);
    });
  });
}
