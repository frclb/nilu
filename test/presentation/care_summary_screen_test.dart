import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/view_models/subscription_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/localization/date_names.dart';
import 'package:period_tracker/presentation/pregnancy/care_list_screen.dart';
import 'package:period_tracker/presentation/pregnancy/care_summary_screen.dart';
import 'package:period_tracker/presentation/profile/profile_settings_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

class _Abone extends SubscriptionViewModel {
  _Abone({required this.premium});
  final bool premium;

  @override
  bool get isPremium => premium;

  @override
  bool get isLoading => false;
}

/// Randevu özeti ekranı (Faz 2).
///
/// Ekranda görmek herkese açık; dosya olarak paylaşmak Premium. Paylaşılan
/// metin ekrandakiyle aynı bölümlerden üretiliyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  final paylasilan = <(String, String)>[];
  setUp(() {
    paylasilan.clear();
    CareSummaryScreen.share = (metin, ad) async => paylasilan.add((metin, ad));
  });

  /// 24+2 haftalık gebe; tansiyon, kilo, lekelenme, belirti ve notlu kalem.
  Future<void> doluGebelik() async {
    final g = await seedPregnancy(weeks: 24, days: 2);
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: daysAgo(40), weightKg: 62, systolic: 112, diastolic: 70),
      DailyLog(date: daysAgo(12), flowIntensity: 'spotting'),
      DailyLog(
        date: daysAgo(2),
        weightKg: 64.5,
        systolic: 150,
        diastolic: 95,
        symptoms: const ['nausea', 'swelling'],
      ),
    ]);
    final kalemler = await const CareRepository().getAll();
    final ilk = kalemler.firstWhere(
      (e) => e.pregnancyId == g.id && e.code == 'tr_visit_1',
    );
    await const CareRepository().upsert(
      ilk.copyWith(done: true, note: 'Demir ilacını sor'),
    );
  }

  Finder metin(String s) => find.text(s, skipOffstage: false);

  for (final boyut in screenSizes.entries) {
    testWidgets('dolu gebelik — ${boyut.key}', (tester) async {
      await doluGebelik();
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const CareSummaryScreen()),
        size: boyut.value,
      );
      expect(find.byType(CareSummaryScreen), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'düzen hatası');
      final ctx = tester.element(find.byType(CareSummaryScreen));

      for (final k in [
        'care_summary_section_pregnancy',
        'care_summary_section_bp',
        'care_summary_section_weight',
        'care_summary_section_bleeding',
        'care_summary_section_symptoms',
        'care_summary_section_care',
        'care_summary_section_notes',
      ]) {
        final f = find.text(ctx.upper(ctx.tr(k)));
        await tester.scrollUntilVisible(f, 300);
        expect(f, findsOneWidget, reason: '$k bölümü yok');
      }
      expect(rawKeysOnScreen(tester), isEmpty);
    });
  }

  testWidgets('değerler doğru satırlarda; yüksek tansiyon işaretli', (
    tester,
  ) async {
    await doluGebelik();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const CareSummaryScreen()),
    );
    final ctx = tester.element(find.byType(CareSummaryScreen));

    expect(
      metin(
        '${daysAgo(2).day} ${ctx.monthName(daysAgo(2).month)} — 150/95 mmHg',
      ),
      findsOneWidget,
    );
    expect(
      metin(
        ctx.tr(
          'care_summary_bp_high_count',
          params: {'high': '1', 'total': '2'},
        ),
      ),
      findsOneWidget,
    );
    expect(
      metin(ctx.tr('care_summary_weight_change', params: {'kg': '+2,5'})),
      findsOneWidget,
    );
    expect(
      find.textContaining(ctx.tr('log_flow_spotting'), skipOffstage: false),
      findsOneWidget,
      reason: 'Gebelikteki lekelenme listede olmalı',
    );
    expect(
      find.textContaining('Demir ilacını sor', skipOffstage: false),
      findsOneWidget,
    );
    // Yüksek tansiyon satırı ve sayımı + lekelenme = üç uyarı simgesi.
    expect(
      find.byIcon(Icons.warning_amber_rounded, skipOffstage: false),
      findsNWidgets(3),
    );
  });

  testWidgets('kayıt yokken bölümler "kayıt yok" diyor', (tester) async {
    await seedPregnancy(template: null);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const CareSummaryScreen()),
    );
    final ctx = tester.element(find.byType(CareSummaryScreen));
    // Tansiyon, kilo, kanama, belirti, kontrol, not.
    expect(metin(ctx.tr('care_summary_none')), findsNWidgets(6));
  });

  testWidgets('ücretsiz kullanıcı: paylaş ödeme ekranına götürüyor', (
    tester,
  ) async {
    await doluGebelik();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const CareSummaryScreen()),
      subscriptionViewModel: _Abone(premium: false),
    );
    await tester.tap(find.byKey(const Key('care_summary_share')));
    await settleAsync(tester);

    expect(find.text(premiumMarker), findsOneWidget);
    expect(paylasilan, isEmpty);
  });

  testWidgets('premium: ekrandaki özet dosya olarak paylaşılıyor', (
    tester,
  ) async {
    await doluGebelik();
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const CareSummaryScreen()),
      subscriptionViewModel: _Abone(premium: true),
    );
    final ctx = tester.element(find.byType(CareSummaryScreen));
    await tester.tap(find.byKey(const Key('care_summary_share')));
    await settleAsync(tester);

    expect(paylasilan, hasLength(1));
    final (dosya, ad) = paylasilan.single;
    expect(ad, matches(RegExp(r'^randevu-ozeti-\d{8}\.txt$')));
    expect(dosya, contains(ctx.tr('care_summary_title')));
    expect(
      dosya,
      contains(
        '! ${daysAgo(2).day} ${ctx.monthName(daysAgo(2).month)} — 150/95 mmHg',
      ),
      reason: 'Yüksek tansiyon metinde de işaretli olmalı',
    );
    expect(dosya, contains('Demir ilacını sor'));
    expect(dosya, contains(ctx.upper(ctx.tr('care_summary_section_bleeding'))));
  });

  testWidgets('lohusalıkta doğum sonrası ve lohia bölümleri', (tester) async {
    await seedPostpartum(daysSinceBirth: 10);
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: daysAgo(3), flowIntensity: 'light'),
    ]);
    await pumpRouter(
      tester,
      routes: pregnancyRoutes(const CareSummaryScreen()),
    );
    final ctx = tester.element(find.byType(CareSummaryScreen));

    expect(
      metin(ctx.upper(ctx.tr('care_summary_section_postpartum'))),
      findsOneWidget,
    );
    expect(
      metin(ctx.tr('care_summary_pp_day', params: {'n': '10'})),
      findsOneWidget,
    );
    expect(
      metin(ctx.upper(ctx.tr('care_summary_section_lochia'))),
      findsOneWidget,
    );
    expect(
      metin(ctx.upper(ctx.tr('care_summary_section_bleeding'))),
      findsNothing,
    );
  });

  testWidgets('randevu listesinden açılıyor', (tester) async {
    await seedPregnancy();
    await pumpRouter(tester, routes: pregnancyRoutes(const CareListScreen()));
    await tester.tap(find.byKey(const Key('care_summary_open')));
    await settleAsync(tester);
    expect(find.byType(CareSummaryScreen), findsOneWidget);
  });

  for (final evre in ['gebelik', 'lohusalık']) {
    testWidgets('$evre: profilden açılıyor', (tester) async {
      await (evre == 'gebelik' ? seedPregnancy() : seedPostpartum());
      await pumpRouter(
        tester,
        routes: pregnancyRoutes(const ProfileSettingsScreen()),
      );
      final ctx = tester.element(find.byType(ProfileSettingsScreen));
      final satir = find.text(ctx.tr('care_summary_title'));
      await tester.scrollUntilVisible(satir, 300);
      await tester.tap(satir);
      await settleAsync(tester);
      expect(find.byType(CareSummaryScreen), findsOneWidget);
    });
  }
}
