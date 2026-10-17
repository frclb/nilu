import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/core/navigation/route_names.dart';
import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/localization/date_names.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_masthead.dart';
import 'package:period_tracker/presentation/insights/prediction_info_screen.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Tahmin aralığı ve "nasıl hesaplandı" ekranı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  List<RouteBase> rotalar(Widget ilk) => [
    GoRoute(path: '/', builder: (_, _) => ilk),
    GoRoute(
      path: '/prediction_info',
      name: RouteNames.predictionInfo,
      builder: (_, _) => const PredictionInfoScreen(),
    ),
  ];

  Future<BuildContext> bilgi(WidgetTester tester) async {
    await pumpRouter(tester, routes: rotalar(const PredictionInfoScreen()));
    return tester.element(find.byType(PredictionInfoScreen));
  }

  testWidgets('ana ekranda sonraki regl aralıkla; bağlantı açıklamaya '
      'götürüyor', (tester) async {
    // 28 günlük üç döngü: aralık son başlangıç + 27 ile + 29.
    await seedCycles(lastStartAgo: 10);
    await pumpRouter(
      tester,
      routes: rotalar(
        const Scaffold(body: SingleChildScrollView(child: CycleMasthead())),
      ),
    );
    final ctx = tester.element(find.byType(CycleMasthead));
    final b = ctx.read<CalendarViewModel>().cycleInfo.basis!;
    expect(find.text(ctx.dayRange(b.earliest, b.latest)), findsOneWidget);

    final baglanti = find.byKey(const Key('home_prediction_how'));
    await tester.ensureVisible(baglanti);
    await tester.tap(baglanti);
    await settleAsync(tester);
    expect(find.byType(PredictionInfoScreen), findsOneWidget);
  });

  testWidgets('kendi geçmişi: ortalama ve en kısa/en uzun söyleniyor', (
    tester,
  ) async {
    await seedCycles(lastStartAgo: 10);
    final ctx = await bilgi(tester);
    final b = ctx.read<CalendarViewModel>().cycleInfo.basis!;

    expect(
      find.text(
        ctx.tr(
          'prediction_info_range',
          params: {'range': ctx.dayRange(b.earliest, b.latest)},
        ),
      ),
      findsOneWidget,
    );
    // Üç başlangıç = iki döngü: kendi aralığı için yetersiz.
    expect(
      find.text(ctx.tr('prediction_info_few', params: {'m': '2', 'p': '2'})),
      findsOneWidget,
    );
    expect(
      find.text(
        ctx.tr('prediction_info_history_avg', params: {'k': '2', 'n': '28'}),
      ),
      findsOneWidget,
    );
  });

  testWidgets('döngü süresi hiç girilmediyse varsayım açıkça söyleniyor', (
    tester,
  ) async {
    // Tek başlangıç, kayıtlı döngü süresi yok: 28 bir varsayım.
    await tester.runAsync(
      () => const PeriodRepository().savePeriodLogs([
        PeriodLog(id: 'a', startDate: daysAgo(10), endDate: daysAgo(6)),
      ]),
    );
    final ctx = await bilgi(tester);
    expect(ctx.read<CalendarViewModel>().cycleLengthKnown, isFalse);
    expect(
      find.text(
        ctx.tr('prediction_info_assumed', params: {'n': '28', 'p': '3'}),
      ),
      findsOneWidget,
    );
  });

  testWidgets('girilen döngü süresi "senin" diye söyleniyor', (tester) async {
    await tester.runAsync(() async {
      await const CycleSettingsRepository().saveInitialSettings(
        cycleLength: 31,
        periodLength: 5,
      );
      await const PeriodRepository().savePeriodLogs([
        PeriodLog(id: 'a', startDate: daysAgo(10), endDate: daysAgo(6)),
      ]);
    });
    final ctx = await bilgi(tester);
    expect(
      find.text(
        ctx.tr('prediction_info_settings', params: {'n': '31', 'p': '2'}),
      ),
      findsOneWidget,
    );
  });

  testWidgets('gecikmede aralık yerine dürüst cümle', (tester) async {
    await seedCycles(lastStartAgo: 33);
    final ctx = await bilgi(tester);
    expect(find.text(ctx.tr('prediction_info_late')), findsOneWidget);
    expect(
      find.textContaining(ctx.tr('prediction_info_likely').split('{')[0]),
      findsNothing,
    );
  });

  testWidgets('kayıt yokken tahmin yok', (tester) async {
    final ctx = await bilgi(tester);
    expect(find.text(ctx.tr('prediction_info_none')), findsOneWidget);
    expect(find.byKey(const Key('prediction_info_how')), findsNothing);
  });

  testWidgets('hormonal doğum kontrolünde doğurganlık açıklaması değişiyor', (
    tester,
  ) async {
    await tester.runAsync(
      () => const CycleSettingsRepository().setHormonalContraception(true),
    );
    await seedCycles(lastStartAgo: 10);
    final ctx = await bilgi(tester);
    expect(ctx.read<CalendarViewModel>().hormonalContraception, isTrue);
    expect(find.text(ctx.tr('prediction_info_fertile_off')), findsOneWidget);
    expect(find.text(ctx.tr('prediction_info_fertile')), findsNothing);
  });
}
