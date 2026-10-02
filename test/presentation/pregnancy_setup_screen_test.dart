import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/localization/date_names.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_setup_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Gebeliği işaretleme.
///
/// Uygulama son adet tarihini zaten biliyor; kullanıcıya tekrar sormak
/// yerine ön dolu geliyor. Bu ekranın tek işi doğru gebeliği doğru şablonla
/// açmak: yanlış tarih bütün bakım takvimini kaydırır, yanlış şablon başka
/// ülkenin takvimini dayatır.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  Finder baslat() => find.byKey(const Key('preg_setup_start'));
  bool etkin(WidgetTester t) =>
      t.widget<FilledButton>(baslat()).onPressed != null;

  for (final boyut in screenSizes.entries) {
    testWidgets('düzen — ${boyut.key}', (tester) async {
      await seedCycles(lastStartAgo: 20);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PregnancySetupScreen()),
        size: boyut.value,
      );
      expect(find.byType(PregnancySetupScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'düzen hatası');
      expect(rawKeysOnScreen(tester), isEmpty);
    });
  }

  testWidgets(
    'son adet tarihi ön dolu; başlatınca Türkiye şemasıyla açılıyor',
    (tester) async {
      await seedCycles(lastStartAgo: 20);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PregnancySetupScreen()),
      );
      final ctx = tester.element(find.byType(PregnancySetupScreen));
      // Ekran başlatınca kapanıyor; bağlamı ondan sonra geçersiz.
      final vm = ctx.read<PregnancyViewModel>();
      final takvim = ctx.read<CalendarViewModel>();

      expect(
        etkin(tester),
        isTrue,
        reason:
            'Son adet tarihi biliniyor; hiçbir şey seçmeden başlatılabilmeli',
      );

      // Naegele: son adet + 280 gün (28 günlük döngü, düzeltme yok).
      final edd = daysAgo(20).add(const Duration(days: 280));
      expect(
        find.text(
          ctx.tr(
            'preg_setup_due_result',
            params: {
              'date': '${edd.day} ${ctx.monthName(edd.month)} ${edd.year}',
            },
          ),
        ),
        findsOneWidget,
      );

      await tester.ensureVisible(baslat());
      await tester.tap(baslat());
      await settleAsync(tester);

      expect(
        find.text(homeMarker),
        findsOneWidget,
        reason: 'Ana sekmeye dönmeli',
      );
      expect(vm.stage, LifeStage.pregnancy);
      expect(vm.current!.estimatedDueDate, edd);
      expect(vm.current!.careTemplate, 'tr');
      expect(vm.currentEvents, isNotEmpty);
      expect(
        takvim.lifeStage,
        LifeStage.pregnancy,
        reason: 'Takvim koruması gebeliği duymadı',
      );
    },
  );

  testWidgets('Türkçe dışında başka ülkenin takvimi dayatılmıyor', (
    tester,
  ) async {
    await seedCycles(lastStartAgo: 20);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancySetupScreen()),
      locale: const Locale('en'),
    );
    final vm = tester
        .element(find.byType(PregnancySetupScreen))
        .read<PregnancyViewModel>();

    await tester.ensureVisible(baslat());
    await tester.tap(baslat());
    await settleAsync(tester);

    expect(vm.stage, LifeStage.pregnancy);
    expect(vm.current!.careTemplate, isNull);
    expect(vm.currentEvents, isEmpty);
  });

  group('döngü uzunluğu', () {
    String yontem(BuildContext ctx, String key, int n) =>
        ctx.tr(key, params: {'n': '$n'});

    testWidgets('kayıtlardan çıkıyorsa onunla hesaplanıp öyle söyleniyor', (
      tester,
    ) async {
      // 30 günlük iki döngü; son regl 20 gün önce.
      await const PeriodRepository().savePeriodLogs([
        for (final once in [80, 50, 20])
          PeriodLog(
            id: 'p$once',
            startDate: daysAgo(once),
            endDate: daysAgo(once - 4),
          ),
      ]);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PregnancySetupScreen()),
      );
      final ctx = tester.element(find.byType(PregnancySetupScreen));

      expect(
        find.text(yontem(ctx, 'preg_setup_due_method_lmp', 30)),
        findsOneWidget,
      );
      expect(
        find.text(yontem(ctx, 'preg_setup_due_method_lmp_assumed', 30)),
        findsNothing,
      );
      // Naegele, döngü düzeltmesiyle: son adet + 280 + (30 − 28).
      final edd = daysAgo(20).add(const Duration(days: 282));
      expect(
        find.text(
          ctx.tr(
            'preg_setup_due_result',
            params: {
              'date': '${edd.day} ${ctx.monthName(edd.month)} ${edd.year}',
            },
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('bilinmiyorsa 28 "senin döngün" diye sunulmuyor', (
      tester,
    ) async {
      // Tek kayıt, kaydedilmiş süre yok: aralık çıkmıyor, 28 varsayılan.
      await const PeriodRepository().savePeriodLogs([
        PeriodLog(id: 'tek', startDate: daysAgo(20), endDate: daysAgo(16)),
      ]);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const PregnancySetupScreen()),
      );
      final ctx = tester.element(find.byType(PregnancySetupScreen));

      expect(
        find.text(yontem(ctx, 'preg_setup_due_method_lmp_assumed', 28)),
        findsOneWidget,
      );
      expect(
        find.text(yontem(ctx, 'preg_setup_due_method_lmp', 28)),
        findsNothing,
      );
    });
  });

  testWidgets('profilden açılınca "ne değişecek": tahminler de duruyor', (
    tester,
  ) async {
    await seedCycles(lastStartAgo: 20);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancySetupScreen()),
    );
    final ctx = tester.element(find.byType(PregnancySetupScreen));
    expect(
      find.text(ctx.upper(ctx.tr('preg_setup_changes_section'))),
      findsOneWidget,
    );
    expect(find.text(ctx.tr('preg_setup_change_predictions')), findsOneWidget);
    expect(
      find.text(ctx.upper(ctx.tr('preg_setup_good_to_know'))),
      findsNothing,
    );
  });

  testWidgets('tahmini doğum geçmişse başlatılamıyor', (tester) async {
    // Tek kayıt, 290 gün önce: son adete göre doğum 10 gün önceydi.
    await const PeriodRepository().savePeriodLogs([
      PeriodLog(id: 'eski', startDate: daysAgo(290), endDate: daysAgo(286)),
    ]);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancySetupScreen()),
    );
    final ctx = tester.element(find.byType(PregnancySetupScreen));

    expect(etkin(tester), isFalse);
    expect(find.text(ctx.tr('preg_setup_due_passed')), findsOneWidget);
  });

  testWidgets('hekimin tarihi: tarih seçilene kadar kapalı, seçilince '
      'hekimden diye kaydediliyor', (tester) async {
    await seedCycles(lastStartAgo: 20);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancySetupScreen()),
    );
    final ctx = tester.element(find.byType(PregnancySetupScreen));
    final vm = ctx.read<PregnancyViewModel>();
    final tamam = MaterialLocalizations.of(ctx).okButtonLabel;

    await tester.tap(find.text(ctx.tr('preg_setup_from_clinician')));
    await tester.pump();
    expect(etkin(tester), isFalse, reason: 'Tarih yokken başlatılmamalı');

    // Seçici bugünle açılıyor; onaylamak bugünü seçer.
    await tester.tap(find.byKey(const Key('preg_setup_pick_date')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tamam));
    await tester.pumpAndSettle();
    expect(etkin(tester), isTrue);

    await tester.ensureVisible(baslat());
    await tester.tap(baslat());
    await settleAsync(tester);

    final g = vm.current!;
    expect(g.dueDateFromClinician, isTrue);
    expect(g.estimatedDueDate, today);
  });

  testWidgets('kapatılmamış son regl gebeliğin içine uzanmıyor', (
    tester,
  ) async {
    // Açık kayıt bugüne kadar uzanıyor (`PeriodLog.lastRecordedDay`).
    // "Reglim bitti"ye basmayı unutup haftalar sonra gebeliğini işaretleyen
    // kullanıcının takviminde bütün gebelik regl günü olarak boyanıyordu.
    await const PeriodRepository().savePeriodLogs([
      PeriodLog(id: 'p1', startDate: daysAgo(96), endDate: daysAgo(92)),
      PeriodLog(id: 'p2', startDate: daysAgo(68), endDate: daysAgo(64)),
      PeriodLog(id: 'acik', startDate: daysAgo(40)),
    ]);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const PregnancySetupScreen()),
    );
    final takvim = tester
        .element(find.byType(PregnancySetupScreen))
        .read<CalendarViewModel>();
    expect(
      takvim.isPeriodDay(today),
      isTrue,
      reason: 'Ön koşul: açık kayıt bugüne uzanıyor',
    );

    await tester.ensureVisible(baslat());
    await tester.tap(baslat());
    await settleAsync(tester);

    final acik = takvim.periodLogs.firstWhere((l) => l.id == 'acik');
    expect(
      acik.endDate,
      daysAgo(36),
      reason: 'Planlanan regl süresi (5 gün) sonunda kapanmalı',
    );
    expect(takvim.isPeriodDay(today), isFalse);
    expect(takvim.isPeriodDay(daysAgo(20)), isFalse);
    expect(
      takvim.isPeriodDay(daysAgo(38)),
      isTrue,
      reason: 'Kayıt silinmemeli',
    );
  });
}
