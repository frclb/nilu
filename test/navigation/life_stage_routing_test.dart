import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/core/navigation/app_router.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/home/home_screen.dart';
import 'package:period_tracker/presentation/insights/insights_screen.dart';
import 'package:period_tracker/presentation/pregnancy/care_list_screen.dart';
import 'package:period_tracker/presentation/pregnancy/postpartum_home_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_home_screen.dart';

import '../presentation/pregnancy_fixtures.dart';
import '../presentation/screen_harness.dart';

/// Uygulamanın **gerçek** yönlendiricisi evreye göre doğru ekranı açıyor mu?
///
/// Ekran testleri ekranları tek tek çiziyor; burada `createAppRouter`
/// splash'ten başlıyor, ana sekmeye yönleniyor ve sekmeler evreye göre
/// seçiliyor. Bağlantı kopsaydı her ekran testi geçer, gebe kullanıcı ise
/// regl tahminli ana ekranı görürdü.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  Future<BuildContext> ac(WidgetTester tester) async {
    late UserViewModel kullanici;
    await tester.runAsync(() async {
      kullanici = UserViewModel();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await pumpRouter(
      tester,
      routes: const [],
      router: createAppRouter(kullanici),
      userViewModel: kullanici,
    );
    await settleAsync(tester, rounds: 6);
    // `MaterialApp`'in kendi bağlamı çeviri katmanının üstünde: oradan
    // `tr` anahtarın kendisini döndürür. İçerideki bir iskeletten alınıyor.
    return tester.element(find.byType(Scaffold).first);
  }

  Future<void> ucuncuSekme(
    WidgetTester tester,
    BuildContext ctx,
    String etiket,
  ) async {
    await tester.tap(find.text(ctx.tr(etiket)).last);
    await settleAsync(tester);
  }

  testWidgets('döngü: normal ana ekran, içgörüler sekmesi', (tester) async {
    await seedCycles();
    final ctx = await ac(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text(ctx.tr('nav_care')), findsNothing);

    await ucuncuSekme(tester, ctx, 'nav_insights');
    expect(find.byType(InsightsScreen), findsOneWidget);
  });

  testWidgets('gebelik: gebelik panosu, randevular sekmesi', (tester) async {
    await seedPregnancy();
    final ctx = await ac(tester);

    expect(find.byType(PregnancyHomeScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(find.text(ctx.tr('nav_insights')), findsNothing);

    await ucuncuSekme(tester, ctx, 'nav_care');
    expect(find.byType(CareListScreen), findsOneWidget);
    expect(find.byType(InsightsScreen), findsNothing);
  });

  testWidgets('lohusalık: lohusa panosu', (tester) async {
    await seedPostpartum();
    await ac(tester);
    expect(find.byType(PostpartumHomeScreen), findsOneWidget);
  });

  testWidgets('gebelik bitince ana sekme kendiliğinden döngüye dönüyor', (
    tester,
  ) async {
    await seedPregnancy();
    final ctx = await ac(tester);
    expect(find.byType(PregnancyHomeScreen), findsOneWidget);

    final vm = ctx.read<PregnancyViewModel>();
    await tester.runAsync(
      () => vm.end(PregnancyOutcome.miscarriage, at: today),
    );
    await settleAsync(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(PregnancyHomeScreen), findsNothing);
  });
}
