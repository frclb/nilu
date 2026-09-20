import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/core/navigation/route_names.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_cycle_length_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_last_period_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_period_length_screen.dart';

/// Onboarding adımlarının geri düğmesi.
///
/// Adımlar arası geçiş `context.goNamed` ile yapılıyordu. `go` yığına
/// eklemek yerine konumu **değiştiriyor**: geri alınacak bir şey kalmıyor ve
/// `context.pop()` hiçbir şey yapmıyordu. Üç ekranın geri düğmesi de sessizce
/// ölüydü — hata yok, çökme yok, sadece dokunuşa cevap yok.
///
/// Bu dosya düğmeye gerçekten basıyor. Widget ağacına bakan bir test bunu
/// göremezdi: düğme oradaydı, `onPressed` doluydu; kusur yönlendirmenin
/// **geçmişinde**ydi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;
  String s(String key) => dictionary[key] as String;

  Future<void> open(WidgetTester tester, {required String start}) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: start,
      routes: [
        GoRoute(
          path: '/onboarding',
          name: RouteNames.onboarding,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('akışın başı'))),
        ),
        GoRoute(
          path: '/onboarding_last_period',
          name: RouteNames.onboardingLastPeriod,
          builder: (context, state) => const OnboardingLastPeriodScreen(),
        ),
        GoRoute(
          path: '/onboarding_period_length',
          name: RouteNames.onboardingPeriodLength,
          builder: (context, state) => const OnboardingPeriodLengthScreen(),
        ),
        GoRoute(
          path: '/onboarding_cycle_length',
          name: RouteNames.onboardingCycleLength,
          builder: (context, state) => const OnboardingCycleLengthScreen(),
        ),
      ],
    );

    await tester.runAsync(() async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CalendarViewModel(),
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light(AppFlavor.plum),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            locale: const Locale('tr'),
            supportedLocales: const [Locale('tr')],
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();
  }

  Future<void> tapAsync(WidgetTester tester, Finder target) async {
    await tester.runAsync(() async {
      await tester.tap(target);
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('bir adım ilerleyip geri dönülebiliyor', (tester) async {
    await open(tester, start: '/onboarding_last_period');
    expect(find.text(s('onb_last_period_title')), findsOneWidget);

    await tapAsync(tester, find.text(s('onb_continue')));
    expect(
      find.text(s('onb_period_length_title')),
      findsOneWidget,
      reason: 'sonraki adıma geçilmedi',
    );

    await tapAsync(tester, find.byIcon(Icons.arrow_back));
    expect(
      find.text(s('onb_last_period_title')),
      findsOneWidget,
      reason:
          'Geri düğmesi hiçbir şey yapmadı: adımlar `go` ile geçildiğinde '
          'yığın boş kalıyor ve `pop()` boşa düşüyor.',
    );
  });

  testWidgets('iki adım ilerleyip iki kez geri dönülebiliyor', (tester) async {
    await open(tester, start: '/onboarding_last_period');

    await tapAsync(tester, find.text(s('onb_continue')));
    await tapAsync(tester, find.text(s('onb_continue')));
    expect(find.text(s('onb_cycle_length_title')), findsOneWidget);

    await tapAsync(tester, find.byIcon(Icons.arrow_back));
    expect(find.text(s('onb_period_length_title')), findsOneWidget);

    await tapAsync(tester, find.byIcon(Icons.arrow_back));
    expect(find.text(s('onb_last_period_title')), findsOneWidget);
  });

  testWidgets('yığın boşken geri düğmesi akışın başına götürüyor', (
    tester,
  ) async {
    // Derin bağlantı doğrudan bir adıma düşürürse geri alınacak bir şey yok;
    // korumasız `pop()` orada hata fırlatıyor.
    await open(tester, start: '/onboarding_period_length');

    await tapAsync(tester, find.byIcon(Icons.arrow_back));
    expect(tester.takeException(), isNull);
    expect(find.text('akışın başı'), findsOneWidget);
  });
}
