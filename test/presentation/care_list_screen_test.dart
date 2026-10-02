import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/pregnancy/care_list_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Randevular: Türkiye şeması, kendi randevuları, düzenleme.
///
/// Kalemi düzenleyen alt sayfa ViewModel'i kendi bağlamından okuyor. Bu
/// testler sağlayıcıları uygulamadaki gibi `MaterialApp`'in üstüne koyuyor
/// ([pumpRouter]); ilk rotanın içine koysaydık sayfa sağlayıcıyı göremez,
/// "kaydet" testte hata verir, uygulamada çalışırdı — ya da tersi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  for (final boyut in screenSizes.entries) {
    testWidgets('Türkiye şeması, 24+2 — ${boyut.key}', (tester) async {
      await seedPregnancy(weeks: 24, days: 2);
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const CareListScreen()),
        size: boyut.value,
      );
      expect(find.byType(CareListScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'düzen hatası');
      final ctx = tester.element(find.byType(CareListScreen));

      expect(
        find.text(ctx.upper(ctx.tr('care_group_now'))),
        findsOneWidget,
        reason: '24. haftada 24–28. hafta izlemi şimdi',
      );
      // Liste tembel kuruluyor: telefonda son bölümler kaydırmadan çizilmiyor.
      final gecmis = find.text(ctx.upper(ctx.tr('care_group_past')));
      await tester.scrollUntilVisible(gecmis, 300);
      expect(gecmis, findsOneWidget, reason: 'İlk izlemler geçti');
      final kaynak = find.text(ctx.tr('care_source_antenatal'));
      await tester.scrollUntilVisible(kaynak, 300);
      expect(
        kaynak,
        findsOneWidget,
        reason: 'Şablonun kaynağı ekranda yazmalı',
      );
      expect(rawKeysOnScreen(tester), isEmpty);
    });
  }

  testWidgets('kendi randevusunu ekliyor; boş başlık kaydedilemiyor', (
    tester,
  ) async {
    await seedPregnancy();
    await pumpRouter(tester, routes: pregnancyRoutes(const CareListScreen()));
    final vm = tester
        .element(find.byType(CareListScreen))
        .read<PregnancyViewModel>();
    final once = vm.currentEvents.length;

    await tester.tap(find.byKey(const Key('care_add')));
    await tester.pumpAndSettle();

    FilledButton kaydet() =>
        tester.widget<FilledButton>(find.byKey(const Key('care_add_save')));
    expect(kaydet().onPressed, isNull);
    await tester.enterText(find.byKey(const Key('care_add_title')), '   ');
    await tester.pump();
    expect(kaydet().onPressed, isNull, reason: 'Yalnız boşluk kaydedildi');

    await tester.enterText(
      find.byKey(const Key('care_add_title')),
      'Diş kontrolü',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('care_add_save')));
    await settleAsync(tester);

    expect(vm.currentEvents.length, once + 1);
    expect(find.text('Diş kontrolü'), findsOneWidget);
  });

  testWidgets('şablon kalemi "yapıldı" işaretleniyor ve silinemiyor', (
    tester,
  ) async {
    await seedPregnancy(weeks: 24, days: 2);
    await pumpRouter(tester, routes: pregnancyRoutes(const CareListScreen()));
    final ctx = tester.element(find.byType(CareListScreen));
    final vm = ctx.read<PregnancyViewModel>();

    final baslik = ctx.tr('care_tr_visit_3_title');
    await tester.tap(find.text(baslik));
    await tester.pumpAndSettle();

    expect(
      find.text(ctx.tr('care_delete')),
      findsNothing,
      reason:
          'Bakanlık şemasının kalemi silinmemeli; yapılmadıysa '
          'işaretlenmeden kalır',
    );

    await tester.tap(find.text(ctx.tr('care_done')));
    await tester.pump();
    await tester.tap(find.text(ctx.tr('care_save')));
    await settleAsync(tester);

    final kalem = vm.currentEvents.firstWhere((e) => e.code == 'tr_visit_3');
    expect(kalem.done, isTrue);
  });

  testWidgets('kendi randevusu silinebiliyor', (tester) async {
    await seedPregnancy();
    await pumpRouter(tester, routes: pregnancyRoutes(const CareListScreen()));
    final ctx = tester.element(find.byType(CareListScreen));
    final vm = ctx.read<PregnancyViewModel>();
    await tester.runAsync(() => vm.addCustomEvent(title: 'Diş kontrolü'));
    await settleAsync(tester);

    await tester.tap(find.text('Diş kontrolü'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ctx.tr('care_delete')));
    await settleAsync(tester);

    expect(vm.currentEvents.where((e) => e.isCustom), isEmpty);
    expect(find.text('Diş kontrolü'), findsNothing);
  });

  testWidgets('şablonsuz gebelik: boş durum, kaynak notu yok', (tester) async {
    await seedPregnancy(template: null);
    await pumpRouter(tester, routes: pregnancyRoutes(const CareListScreen()));
    final ctx = tester.element(find.byType(CareListScreen));

    expect(find.text(ctx.tr('care_empty')), findsOneWidget);
    expect(find.text(ctx.tr('care_source_antenatal')), findsNothing);
  });

  testWidgets('lohusalıkta gebelik kalemleri gizli, lohusa izlemleri görünür', (
    tester,
  ) async {
    await seedPostpartum(daysSinceBirth: 10);
    await pumpRouter(tester, routes: pregnancyRoutes(const CareListScreen()));
    final ctx = tester.element(find.byType(CareListScreen));

    expect(find.text(ctx.tr('care_tr_visit_1_title')), findsNothing);
    expect(find.text(ctx.tr('care_tr_screen_anomaly_title')), findsNothing);
    expect(find.text(ctx.tr('care_tr_pp_visit_5_title')), findsOneWidget);
    final kaynak = find.text(ctx.tr('care_source_postnatal'));
    await tester.scrollUntilVisible(kaynak, 300);
    expect(kaynak, findsOneWidget);
    expect(find.text(ctx.tr('care_source_antenatal')), findsNothing);
  });
}
