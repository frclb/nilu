import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/day_detail_bottom_sheet.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
import 'package:period_tracker/presentation/log_entry/widgets/flow_intensity_section.dart';
import 'package:period_tracker/presentation/log_entry/widgets/measurements_section.dart';
import 'package:period_tracker/presentation/log_entry/widgets/symptoms_section.dart';
import 'package:period_tracker/presentation/pregnancy/danger_signs_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Tansiyon ve kilo (Faz 2): kayıt ekranında giriş, doğrulama, uyarı.
///
/// Uyarı ücretsiz ve teşhis değil (bkz. `Vitals`): değerin hangi aralıkta
/// olduğunu ve ne yapılacağını söylüyor. Gebelikte 140/90 ve üstü hekime
/// bildirilmeli, 160/110 ve üstü acil.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

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
    expect(find.byType(LogEntryScreen), findsOneWidget);
    return takvim;
  }

  BuildContext ctx(WidgetTester tester) =>
      tester.element(find.byType(LogEntryScreen));

  Future<void> yaz(WidgetTester tester, String alan, String deger) async {
    final f = find.byKey(Key(alan));
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.enterText(f, deger);
    await tester.pump();
  }

  Future<void> kaydet(WidgetTester tester) async {
    await tester.tap(find.text(ctx(tester).tr('log_save_button')));
    await settleAsync(tester);
  }

  Future<void> tansiyon(WidgetTester tester, String b, String k) async {
    await yaz(tester, 'log_measure_systolic', b);
    await yaz(tester, 'log_measure_diastolic', k);
  }

  testWidgets('döngüde ölçüm bölümü yok', (tester) async {
    await seedCycles();
    await ac(tester);
    expect(find.byType(MeasurementsSection), findsNothing);
  });

  testWidgets('gebelikte kilo ve normal tansiyon: uyarısız kaydediliyor', (
    tester,
  ) async {
    await seedPregnancy();
    final takvim = await ac(tester);
    expect(find.byType(MeasurementsSection), findsOneWidget);

    await yaz(tester, 'log_measure_weight', '64,5');
    await tansiyon(tester, '118', '76');
    await kaydet(tester);

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(LogEntryScreen), findsNothing);
    final k = takvim.getDailyLogForDate(today);
    expect(k.weightKg, 64.5);
    expect((k.systolic, k.diastolic), (118, 76));
  });

  testWidgets('140/90 ve üstü: yüksek tansiyon uyarısı', (tester) async {
    await seedPregnancy();
    final takvim = await ac(tester);

    await tansiyon(tester, '150', '95');
    await kaydet(tester);

    expect(find.byKey(const Key('bp_high_dialog')), findsOneWidget);
    expect(
      find.textContaining('150/95'),
      findsOneWidget,
      reason: 'Uyarı ölçülen değeri söylemeli',
    );
    expect(takvim.getDailyLogForDate(today).systolic, 150);
  });

  testWidgets('160/110 ve üstü: ağır uyarı, kanamadan önce geliyor', (
    tester,
  ) async {
    await seedPregnancy();
    await ac(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(FlowIntensitySection),
        matching: find.text(ctx(tester).tr('log_flow_spotting')),
      ),
    );
    await tester.pump();
    await tansiyon(tester, '165', '112');
    await kaydet(tester);

    expect(find.byKey(const Key('bp_severe_dialog')), findsOneWidget);
    expect(find.byKey(const Key('preg_bleeding_dialog')), findsNothing);
  });

  testWidgets('geçersiz ölçüm: kaydedilmiyor, ekran açık kalıyor', (
    tester,
  ) async {
    await seedPregnancy();
    final takvim = await ac(tester);

    // Tansiyonun tek değeri.
    await yaz(tester, 'log_measure_systolic', '120');
    await kaydet(tester);
    expect(find.byType(LogEntryScreen), findsOneWidget);
    expect(find.text(ctx(tester).tr('log_measure_invalid')), findsOneWidget);
    expect(takvim.getDailyLogForDate(today).hasContent, isFalse);

    // Yazım hatası.
    await tansiyon(tester, '1205', '80');
    await kaydet(tester);
    expect(find.byType(LogEntryScreen), findsOneWidget);
    expect(takvim.getDailyLogForDate(today).systolic, isNull);

    // Kilo sayı değil.
    await tansiyon(tester, '', '');
    await yaz(tester, 'log_measure_weight', 'altmış');
    await kaydet(tester);
    expect(find.byType(LogEntryScreen), findsOneWidget);
    expect(takvim.getDailyLogForDate(today).weightKg, isNull);
  });

  testWidgets('ön dolu, değişmemiş yüksek tansiyon tekrar uyarmıyor', (
    tester,
  ) async {
    // Sabah ölçüp uyarıyı görmüş kullanıcı akşam yalnızca belirti ekliyor.
    await seedPregnancy();
    await const PeriodRepository().saveDailyLogs([
      DailyLog(
        date: today,
        systolic: 150,
        diastolic: 95,
        flowIntensity: 'spotting',
      ),
    ]);
    final takvim = await ac(tester);

    final b = tester.widget<TextField>(
      find.byKey(const Key('log_measure_systolic')),
    );
    expect(b.controller!.text, '150', reason: 'Ölçüm ön dolu gelmeli');

    final bulanti = find.descendant(
      of: find.byType(SymptomsSection),
      matching: find.text(ctx(tester).tr('log_symptom_nausea')),
    );
    await tester.ensureVisible(bulanti);
    await tester.pumpAndSettle();
    await tester.tap(bulanti);
    await tester.pump();
    await kaydet(tester);

    expect(find.byType(AlertDialog), findsNothing);
    final k = takvim.getDailyLogForDate(today);
    expect(k.symptoms, ['nausea']);
    expect((k.systolic, k.diastolic), (150, 95), reason: 'Ölçüm silindi');
    expect(k.flowIntensity, 'spotting');
  });

  testWidgets('ölçüm alanını boşaltmak ölçümü siliyor', (tester) async {
    await seedPregnancy();
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: today, weightKg: 64, systolic: 118, diastolic: 76),
    ]);
    final takvim = await ac(tester);

    await yaz(tester, 'log_measure_weight', '');
    await kaydet(tester);

    final k = takvim.getDailyLogForDate(today);
    expect(k.weightKg, isNull);
    expect(k.systolic, 118, reason: 'Yalnızca kilo boşaltıldı');
  });

  testWidgets(
    'lohusalıkta yüksek tansiyon lohusa tehlike listesine götürüyor',
    (tester) async {
      await seedPostpartum();
      await ac(tester);
      expect(find.byType(MeasurementsSection), findsOneWidget);

      await tansiyon(tester, '145', '92');
      await kaydet(tester);
      expect(find.byKey(const Key('bp_high_dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('warning_dialog_danger')));
      await settleAsync(tester);
      expect(
        tester.widget<DangerSignsScreen>(find.byType(DangerSignsScreen)).period,
        DangerPeriod.postpartum,
      );
      expect(find.byType(LogEntryScreen), findsNothing);
    },
  );

  testWidgets('döngüde kayıt ekranı eski ölçümlere dokunmuyor', (tester) async {
    // Gebelikte girilmiş ölçüm, gebelik bittikten sonra aynı gün kayıt
    // ekranından kaydedilince silinmemeli (bölüm görünmüyor).
    await seedCycles();
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: today, weightKg: 64, systolic: 118, diastolic: 76),
    ]);
    final takvim = await ac(tester);
    await kaydet(tester);

    final k = takvim.getDailyLogForDate(today);
    expect(k.weightKg, 64);
    expect(k.systolic, 118);
  });

  testWidgets('gün ayrıntısı ölçümleri silmiyor', (tester) async {
    await seedPregnancy();
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: today, weightKg: 64, systolic: 118, diastolic: 76),
    ]);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const SizedBox(key: Key('kok'))),
    );
    final c = tester.element(find.byKey(const Key('kok')));
    final takvim = c.read<CalendarViewModel>();
    showDayDetailSheet(c, today);
    await tester.pumpAndSettle();

    await tester.tap(find.text(c.tr('log_symptom_heartburn')));
    await settleAsync(tester);

    final k = takvim.getDailyLogForDate(today);
    expect(k.symptoms, ['heartburn']);
    expect(
      k.weightKg,
      64,
      reason:
          'Gün ayrıntısı kaydı yeniden kurarken '
          'ölçümü düşürdü',
    );
    expect(k.systolic, 118);
  });
}
