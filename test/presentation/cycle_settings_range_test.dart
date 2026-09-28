import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/view_models/user_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/profile/cycle_settings_screen.dart';

/// Döngü Ayarları ekranı, depodaki her değerle açılabilmeli.
///
/// Onboarding çarkı 21–45 arası döngü seçtiriyordu, ayarlardaki kaydırıcı
/// 21–35 kabul ediyordu. 36 gün ya da üstünü seçen kullanıcı Döngü
/// Ayarları'nı açtığında ekran `Slider`'ın
/// `'value >= min && value <= max'` iddiasıyla çöküyordu — kırmızı hata
/// ekranı. Uzun döngü tıbben olağandışı değil; kullanıcı hiçbir kural
/// çiğnemeden uygulamanın bir ekranını kalıcı olarak kırabiliyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> ekraniAc(WidgetTester tester, {required int dongu}) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await const CycleSettingsRepository().saveInitialSettings(
        cycleLength: dongu,
        periodLength: 7,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('tr')],
          locale: const Locale('tr'),
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => CalendarViewModel()),
              ChangeNotifierProvider(create: (_) => UserViewModel()),
            ],
            child: const CycleSettingsScreen(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('ayar ekranı her değerle açılır', () {
    for (final dongu in [21, 28, 35, 36, 40, 45]) {
      testWidgets('$dongu günlük döngü', (tester) async {
        await ekraniAc(tester, dongu: dongu);
        expect(tester.takeException(), isNull);
        expect(find.byType(Slider), findsWidgets);
      });
    }

    testWidgets('aralık dışı bir değer kırpılır, çökmez', (tester) async {
      // Yedekten gelmiş ya da eski bir sürümün yazdığı değer.
      await ekraniAc(tester, dongu: 90);
      expect(tester.takeException(), isNull);

      final dongu = tester.widgetList<Slider>(find.byType(Slider)).first;
      expect(dongu.value, CycleSettingsRepository.maxCycleLength.toDouble());
    });
  });

  test('onboarding çarkı ile kaydırıcı aynı aralığı kullanır', () {
    // Aynı kural iki yerde yazıldığında ayrışıyor; ikisi de aynı
    // sabitlerden okumalı.
    expect(CycleSettingsRepository.minCycleLength, 21);
    expect(CycleSettingsRepository.maxCycleLength, 45);
    expect(CycleSettingsRepository.minPeriodLength, 2);
    expect(CycleSettingsRepository.maxPeriodLength, 10);
    expect(
      CycleSettingsRepository.defaultCycleLength,
      inInclusiveRange(
        CycleSettingsRepository.minCycleLength,
        CycleSettingsRepository.maxCycleLength,
      ),
    );
    expect(
      CycleSettingsRepository.defaultPeriodLength,
      inInclusiveRange(
        CycleSettingsRepository.minPeriodLength,
        CycleSettingsRepository.maxPeriodLength,
      ),
    );
  });
}
