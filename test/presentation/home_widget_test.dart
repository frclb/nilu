import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/datasources/widget_datasource.dart';
import 'package:period_tracker/domain/models/calendar_day.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/domain/models/home_widget_entry.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/models/pregnancy_month.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/pregnancy/care_text.dart';
import 'package:period_tracker/presentation/widgets_preview/home_widget_plan.dart';
import 'package:period_tracker/presentation/widgets_preview/home_widget_sync.dart';
import 'package:period_tracker/presentation/widgets_preview/widgets_preview_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Yayımlananları kaydeden widget kaynağı.
class _SahteYayin extends WidgetDatasource {
  _SahteYayin();

  final List<List<HomeWidgetEntry>> yayinlar = [];
  final List<String> eskimis = [];

  @override
  Future<void> publish(
    List<HomeWidgetEntry> entries, {
    required String staleText,
  }) async {
    yayinlar.add(entries);
    eskimis.add(staleText);
  }
}

/// Ana ekran widget'ı.
///
/// Widget metni kendisi Türkçe kuruyordu: gebelikte "Kayıt ekle",
/// gecikmede "bugün başlıyor" yazıyordu ve uygulama açılmadıkça gece
/// yarısından sonra da dünün sayısını gösteriyordu. Önizleme ekranı ise
/// örnek sayılar ve olmayan bir partner widget'ı gösteriyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  // Avrupa'da 25 Ekim'de saat geri alınıyor; 14 gün bu geçişi kapsıyor.
  final b = DateTime(2026, 10, 20);
  DateTime g(int n) => b.plusDays(n);

  Future<BuildContext> baglam(
    WidgetTester tester, {
    Locale locale = const Locale('tr'),
  }) async {
    late BuildContext ctx;
    await pumpScreen(
      tester,
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox.shrink();
        },
      ),
      size: const Size(390, 844),
      locale: locale,
    );
    return ctx;
  }

  /// 10. döngü günü: 28 günlük döngü, regl 5 gün sürdü.
  CycleInfo dongu({int gun = 10, int kalan = 18}) => CycleInfo(
    lastPeriodStart: g(1 - gun),
    predictedNextPeriod: g(kalan),
    currentPeriodLength: 5,
    currentPeriodEnd: g(5 - gun),
  );

  group('plan', () {
    testWidgets('döngü günü, evre ve regle kalan gün', (tester) async {
      final ctx = await baglam(tester);
      final e = HomeWidgetPlan.entryFor(
        ctx,
        b,
        cycle: dongu(),
        pregnancies: const [],
      );
      expect(e.hasData, isTrue);
      expect(e.label, 'DÖNGÜ GÜNÜ');
      expect(e.value, '10');
      expect(e.caption, ctx.tr('phase_title_follicular'));
      expect(e.detail, ctx.tr('widget_period_in', params: {'n': '18'}));
      expect(e.colorKey, 'follicular');
      expect(e.progress, closeTo(10 / 27, 1e-9));
      expect(
        e.spoken,
        startsWith(ctx.tr('home_headline_cycle_day', params: {'n': '10'})),
      );
    });

    testWidgets('14 gün, takvim günleriyle; sayaç her gün ilerliyor', (
      tester,
    ) async {
      final ctx = await baglam(tester);
      final liste = HomeWidgetPlan.build(
        ctx,
        cycle: dongu(gun: 10, kalan: 2),
        pregnancies: const [],
        today: b.add(const Duration(hours: 15)),
      );
      expect(liste, hasLength(HomeWidgetPlan.days));
      expect(liste.map((e) => e.toJson()['date']), [
        for (var i = 20; i <= 31; i++) '2026-10-$i',
        '2026-11-01',
        '2026-11-02',
      ]);
      expect(liste.map((e) => e.value), [for (var i = 10; i < 24; i++) '$i']);
      expect(liste[1].detail, ctx.tr('widget_period_in_one'));
      expect(liste[2].detail, ctx.tr('widget_period_today'));
      expect(liste[2].progress, 1.0);
      expect(liste[3].detail, ctx.tr('widget_period_late_one'));
      expect(liste[5].detail, ctx.tr('widget_period_late', params: {'n': '3'}));
    });

    testWidgets('gecikmede evre ve halka yok', (tester) async {
      // Regl gelmiş ama işaretlenmemiş olabilir: döngünün nerede olduğu
      // bilinmiyor.
      final ctx = await baglam(tester);
      final e = HomeWidgetPlan.entryFor(
        ctx,
        b,
        cycle: dongu(gun: 31, kalan: -3),
        pregnancies: const [],
      );
      expect(e.caption, isEmpty);
      expect(e.progress, isNull);
      expect(e.colorKey, 'unknown');
      expect(e.detail, ctx.tr('widget_period_late', params: {'n': '3'}));
    });

    testWidgets('regl sırasında "regle 26 gün" yazılmıyor', (tester) async {
      final ctx = await baglam(tester);
      final e = HomeWidgetPlan.entryFor(
        ctx,
        b,
        cycle: CycleInfo(
          lastPeriodStart: g(-1),
          predictedNextPeriod: g(27),
          currentPeriodLength: 2,
        ),
        pregnancies: const [],
      );
      expect(e.value, '2');
      expect(e.caption, ctx.tr('phase_title_menstruation'));
      expect(e.detail, isEmpty);
      expect(e.colorKey, 'menstruation');
    });

    testWidgets('kayıt yokken veri yok; gebelikten sonra ilk regl', (
      tester,
    ) async {
      final ctx = await baglam(tester);
      final bos = HomeWidgetPlan.entryFor(
        ctx,
        b,
        cycle: CycleInfo(),
        pregnancies: const [],
      );
      expect(bos.hasData, isFalse);
      expect(bos.detail, ctx.tr('widget_empty'));

      final sonra = HomeWidgetPlan.entryFor(
        ctx,
        b,
        cycle: CycleInfo(),
        pregnancies: const [],
        afterPregnancy: true,
      );
      expect(sonra.hasData, isFalse);
      expect(sonra.detail, ctx.tr('home_headline_after_pregnancy'));
    });

    testWidgets('gebelik: panodaki metinlerin aynısı', (tester) async {
      final ctx = await baglam(tester);
      final p = Pregnancy.fromLmp(
        lmp: g(-(24 * 7 + 2)),
        cycleLength: 28,
        confirmedAt: g(-100),
        id: 'g1',
      );
      final e = HomeWidgetPlan.entryFor(
        ctx,
        b,
        cycle: dongu(),
        pregnancies: [p],
      );
      final ga = p.gestationOn(b)!;
      expect(e.label, 'GEBELİK', reason: 'Türkçe büyük İ');
      expect(e.value, '24+2');
      expect(e.caption, ctx.monthLabel(PregnancyMonth.of(ga).number));
      expect(e.detail, ctx.dueCountdown(p.estimatedDueDate.daysSince(b)));
      expect(e.spoken, startsWith(ctx.gestationSentence(ga)));
      expect(e.spoken, isNot(contains('+')), reason: 'Sesli okunuyor');
      expect(e.colorKey, 'pregnancy');
      expect(e.progress, closeTo(170 / 280, 1e-9));
    });

    testWidgets('lohusalık bitince sonraki günler döngü', (tester) async {
      final ctx = await baglam(tester);
      final dogum = g(-37);
      final p = Pregnancy.fromLmp(
        lmp: dogum.plusDays(-278),
        cycleLength: 28,
        confirmedAt: dogum.plusDays(-230),
        id: 'g1',
      ).ended(outcome: PregnancyOutcome.birth, at: dogum);

      final liste = HomeWidgetPlan.build(
        ctx,
        cycle: CycleInfo(),
        pregnancies: [p],
        today: b,
        afterPregnancy: true,
      );
      expect(liste.first.label, ctx.upper(ctx.tr('pp_label')));
      expect(liste.first.value, ctx.tr('pp_day', params: {'n': '37'}));
      expect(liste.first.colorKey, 'postpartum');
      // 42. gün artık döngü (bkz. `LifeStage.postpartumEnd`).
      expect(liste[4].colorKey, 'postpartum');
      expect(liste[5].hasData, isFalse);
      expect(liste[5].detail, ctx.tr('home_headline_after_pregnancy'));

      final dogumGunu = HomeWidgetPlan.entryFor(
        ctx,
        dogum,
        cycle: CycleInfo(),
        pregnancies: [p],
      );
      expect(dogumGunu.value, ctx.tr('pp_day_birth'), reason: '"0. gün" değil');
    });

    testWidgets('uygulamanın dilinde', (tester) async {
      final ctx = await baglam(tester, locale: const Locale('en'));
      final e = HomeWidgetPlan.entryFor(
        ctx,
        b,
        cycle: dongu(),
        pregnancies: const [],
      );
      expect(e.label, 'CYCLE DAY');
      expect(e.detail, 'Period in 18 days');
    });
  });

  group('Swift ile sözleşme', () {
    final swift = File('ios/CycleWidget/CycleWidget.swift').readAsStringSync();

    test('alan adları aynı', () {
      final govde = RegExp(
        r'struct WidgetDay: Decodable \{(.*?)\n\}',
        dotAll: true,
      ).firstMatch(swift)!.group(1)!;
      final alanlar = RegExp(
        r'^\s+let (\w+):',
        multiLine: true,
      ).allMatches(govde).map((m) => m.group(1)).toSet();
      expect(
        alanlar,
        HomeWidgetEntry(date: b, hasData: true).toJson().keys.toSet(),
      );
    });

    test('depo, grup ve tür adları aynı', () {
      expect(swift, contains('forKey: "entries"'));
      expect(swift, contains('forKey: "staleText"'));
      expect(swift, contains('"${WidgetDatasource.appGroupId}"'));
      expect(swift, contains('kind = "${WidgetDatasource.iOSWidgetName}"'));
    });

    test('her renk anahtarının Swift karşılığı var', () {
      for (final k in [
        for (final p in CyclePhase.values)
          if (p != CyclePhase.unknown) p.name,
        'pregnancy',
        'postpartum',
      ]) {
        expect(swift, contains('"$k"'), reason: k);
      }
    });
  });

  group('eşitleme', () {
    Future<_SahteYayin> kur(
      WidgetTester tester, {
      DateTime Function()? clock,
    }) async {
      final yayin = _SahteYayin();
      await pumpScreen(
        tester,
        HomeWidgetSync(
          datasource: yayin,
          clock: clock,
          child: const SizedBox.shrink(),
        ),
        size: const Size(390, 844),
      );
      return yayin;
    }

    testWidgets('içerik değişince bir kez yazılıyor', (tester) async {
      await seedCycles();
      final yayin = await kur(tester);
      expect(yayin.yayinlar, hasLength(1));
      expect(yayin.yayinlar.single, hasLength(HomeWidgetPlan.days));
      expect(yayin.yayinlar.single.first.value, '21');
      expect(
        yayin.eskimis.single,
        tester.element(find.byType(HomeWidgetSync)).tr('widget_open_app'),
      );

      // Uygulama öne geldi ama hiçbir şey değişmedi.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(yayin.yayinlar, hasLength(1));

      final vm = tester
          .element(find.byType(HomeWidgetSync))
          .read<CalendarViewModel>();
      await tester.runAsync(() => vm.togglePeriodDay(today));
      await tester.pump();
      expect(yayin.yayinlar, hasLength(2));
      expect(yayin.yayinlar.last.first.value, '1');
    });

    testWidgets('gün değişince yeniden yazılıyor', (tester) async {
      await seedCycles();
      var saat = DateTime.now();
      final yayin = await kur(tester, clock: () => saat);
      expect(yayin.yayinlar, hasLength(1));

      saat = saat.add(const Duration(days: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(yayin.yayinlar, hasLength(2));
      expect(
        yayin.yayinlar.last.first.toJson()['date'],
        yayin.yayinlar.first[1].toJson()['date'],
      );
    });

    testWidgets('gebelik yüklenmeden döngü yazılmıyor', (tester) async {
      // Gebe kullanıcının widget'ına bir an için döngü girdisi yazılırdı.
      await seedCycles();
      await seedPregnancy();
      final takvim = CalendarViewModel();
      final gebelik = PregnancyViewModel();
      final yayin = _SahteYayin();
      await tester.runAsync(takvim.refreshData);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: takvim),
            ChangeNotifierProvider.value(value: gebelik),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            locale: const Locale('tr'),
            supportedLocales: const [Locale('tr')],
            home: HomeWidgetSync(
              datasource: yayin,
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump();
      expect(find.byType(HomeWidgetSync), findsOneWidget);
      expect(yayin.yayinlar, isEmpty, reason: 'Gebelik henüz yüklenmedi');

      await tester.runAsync(gebelik.load);
      await tester.pump();
      expect(yayin.yayinlar, hasLength(1));
      expect(yayin.yayinlar.single.first.colorKey, 'pregnancy');
    });
  });

  group('önizleme', () {
    testWidgets('bugünün gerçek içeriği, örnek veri yok', (tester) async {
      await seedCycles();
      await pumpScreen(
        tester,
        const WidgetsPreviewScreen(),
        size: const Size(390, 844),
      );
      final ctx = tester.element(find.byType(WidgetsPreviewScreen));
      expect(
        find.descendant(
          of: find.byKey(const Key('widget_preview_small')),
          matching: find.text('21'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('widget_preview_medium')),
          matching: find.text('21'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Ayşe'), findsNothing);
      expect(find.text(ctx.tr('widgets_how_to_add')), findsOneWidget);
      expect(rawKeysOnScreen(tester), isEmpty);
    });

    testWidgets('gebelikte gebelik haftası', (tester) async {
      await seedPregnancy();
      await pumpScreen(
        tester,
        const WidgetsPreviewScreen(),
        size: const Size(390, 844),
      );
      expect(find.text('24+2'), findsNWidgets(2));
    });
  });
}
