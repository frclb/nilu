import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_cycle_length_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_period_length_screen.dart';
import 'package:period_tracker/presentation/onboarding_welcome/onboarding_progress.dart';

/// Onboarding artık regl süresini soruyor.
///
/// Önceden sormuyordu: kurulum sabit 5 yazıyordu. O sayı iki yere birden
/// gidiyordu — girilen son regl tarihinden kaydın açık mı kapalı mı
/// kurulacağına karar veriyor, bir de `completedLength` üzerinden **ortalama
/// regl süresi** hesabına giriyordu. Yani kullanıcının hiç söylemediği bir
/// değer, sonradan kendi verisiymiş gibi geri okunuyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;
  String s(String key) => dictionary[key] as String;
  String days(int n) => s('onb_days_count').replaceAll('{n}', '$n');

  GoRouter router() => GoRouter(
    initialLocation: '/onboarding_period_length',
    routes: [
      GoRoute(
        path: '/onboarding_period_length',
        builder: (context, state) => const OnboardingPeriodLengthScreen(),
      ),
      GoRoute(
        path: '/onboarding_cycle_length',
        name: 'onboarding_cycle_length',
        builder: (context, state) => const OnboardingCycleLengthScreen(),
      ),
      GoRoute(
        path: '/onboarding_success',
        name: 'onboarding_success',
        builder: (context, state) => const Scaffold(body: Text('bitti')),
      ),
    ],
  );

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Sözlük varlıktan **asenkron** okunuyor; `runAsync` olmadan ekran
    // tamamen boş kalıyor ve test gerçekte olmayan bir şeyi ölçüyor.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CalendarViewModel()),
          ],
          child: MaterialApp.router(
            routerConfig: router(),
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

  /// Ekranı değiştiren dokunuşlar da asenkron iş yapıyor (depo yazımı,
  /// yönlendirme), o yüzden aynı sarmalayıcıdan geçiyorlar.
  Future<void> tapAsync(WidgetTester tester, Finder target) async {
    await tester.runAsync(() async {
      await tester.tap(target);
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();
  }

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('soru soruluyor ve varsayılan 5 gün', (tester) async {
    await open(tester);

    expect(find.text(s('onb_period_length_title')), findsOneWidget);
    expect(find.text(days(5)), findsOneWidget,
        reason: 'Çark varsayılan olarak 5 günde durmalı.');
  });

  testWidgets('gün sayısı sabit yazılmamış, çeviriden geliyor', (tester) async {
    await open(tester);
    // Ekranda "5 Gün" gibi bir metin var ama kaynağı sözlük olmalı:
    // İngilizce sözlükteki karşılığı Türkçede görünmemeli.
    final en = jsonDecode(File('lib/localization/en.json').readAsStringSync())
        as Map<String, dynamic>;
    expect(find.text((en['onb_days_count'] as String).replaceAll('{n}', '5')),
        findsNothing);
  });

  testWidgets('seçilen süre kurulumun sonuna taşınıyor', (tester) async {
    await open(tester);

    // Çarkı 7 güne getir.
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    expect(find.text(days(7)), findsOneWidget);

    await tapAsync(tester, find.text(s('onb_continue')));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(OnboardingPeriodLengthScreen.prefsKey), 7);
    // Bir sonraki adıma geçmiş olmalı.
    expect(find.text(s('onb_cycle_length_title')), findsOneWidget);
  });

  testWidgets('kurulum seçilen süreyi ayarlara yazıyor', (tester) async {
    await open(tester);

    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tapAsync(tester, find.text(s('onb_continue')));

    await tapAsync(tester, find.text(s('onb_finish_setup')));

    final saved = await CycleSettingsRepository().getPeriodLength();
    expect(saved, 7,
        reason: 'Kurulum kullanıcının cevabını değil sabit 5 yazıyordu.');
  });

  testWidgets('girilen son regl tarihi seçilen süreye göre kaydediliyor', (
    tester,
  ) async {
    // Regli 7 gün süren biri, 6 gün önce başlamış: dönem hâlâ sürüyor.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    SharedPreferences.setMockInitialValues({
      'onboarding_last_period_date': start.toIso8601String(),
    });

    await open(tester);
    await tester.drag(find.byType(ListWheelScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();
    await tapAsync(tester, find.text(s('onb_continue')));
    await tapAsync(tester, find.text(s('onb_finish_setup')));

    final logs = await PeriodRepository().getPeriodLogs();
    expect(logs, hasLength(1));
    expect(logs.single.firstDay, start);
    expect(
      logs.single.isOngoing,
      isTrue,
      reason: '7 günlük regl 6 gün önce başladıysa bugün hâlâ sürüyor. '
          'Sabit 5 ile bu dönem kapanmış sayılıyordu.',
    );
  });

  group('ilerleme göstergesi', () {
    test('koyu temada geçilmemiş noktalar görünüyor', () {
      // `(isDark ? 0.4 : 0.2 * 255).toInt()` koyu temada 0 veriyordu:
      // noktalar tamamen saydamdı, kullanıcı kaç adım kaldığını göremiyordu.
      expect(onboardingIdleDotAlpha(true), greaterThan(0));
      expect(onboardingHighlightAlpha(true), greaterThan(0));
      // Koyu tema açıktan daha belirgin olmalı; niyet buydu.
      expect(onboardingIdleDotAlpha(true),
          greaterThan(onboardingIdleDotAlpha(false)));
    });

    test('adım sayısı hiçbir ekranda sabit yazılmamış', () {
      final dir = Directory('lib/presentation/onboarding_welcome');
      final offenders = <String>[];
      for (final file in dir.listSync().whereType<File>()) {
        if (!file.path.endsWith('_screen.dart')) continue;
        final src = file.readAsStringSync();
        // Karşılama ekranı kendi sayfalarını sayıyor; soru ekranları
        // toplam adımı `onboardingStepCount`'tan almalı.
        if (file.path.endsWith('onboarding_welcome_screen.dart')) continue;
        for (final m in RegExp(r'List\.generate\((\d+),').allMatches(src)) {
          offenders.add('${file.path.split('/').last}: ${m.group(0)}');
        }
      }
      expect(offenders, isEmpty,
          reason: 'Adım sayısı kopyalandığında araya ekran eklemek '
              'göstergeleri birbirinden ayırır.');
    });

    test('soru adımları art arda ve son nokta son adım', () {
      // Karşılama sayfaları 0–3; hedef adımı onlardan hemen sonra.
      const adimlar = [
        OnboardingStep.goal,
        OnboardingStep.lastPeriod,
        OnboardingStep.periodLength,
        OnboardingStep.cycleLength,
      ];
      expect(adimlar.first, 4);
      for (var i = 1; i < adimlar.length; i++) {
        expect(adimlar[i], adimlar[i - 1] + 1);
      }
      expect(adimlar.last, onboardingStepCount - 1,
          reason: 'Araya adım eklenip sayı artırılmazsa son ekranın '
              'noktası dizinin dışına düşer: hiçbir nokta etkin görünmez.');
    });
  });
}
