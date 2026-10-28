import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/design_system/app_contrast.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/design_system/app_tokens.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/calendar_grid.dart';

/// Önceki aydan taşan regl günleri bandın üstünde okunuyor mu?
///
/// TestFlight bulgusu: Kasım görünümünde 26–28 Ekim kırmızı bandın üstünde
/// soluk griyle yazılıyordu ("kırmızı kısım renkler ayrışmıyor"). Ay dışı
/// her gün dolgusuna bakılmadan soluk renk alıyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ay dışı regl günü bandın kontrast rengiyle yazılıyor', (
    tester,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final calendar = CalendarViewModel();

    // Ay pazartesi başlıyorsa ızgarada önceki aydan gün yok: önceki aydan
    // gün gösteren bir aya geç. Bugünden uzak durmak için geçmişe gidiliyor.
    calendar.previousMonth();
    while (DateTime(
          calendar.currentMonth.year,
          calendar.currentMonth.month,
        ).weekday ==
        DateTime.monday) {
      calendar.previousMonth();
    }
    final first = DateTime(
      calendar.currentMonth.year,
      calendar.currentMonth.month,
    );
    // Izgaranın ilk hücresi: önceki ayın günü, soluk çiziliyor.
    final faded = first.subtract(Duration(days: first.weekday - 1));

    await tester.runAsync(() async {
      await PeriodRepository().savePeriodLogs([
        PeriodLog(id: 'p', startDate: faded, endDate: faded),
      ]);
      await calendar.refreshData();
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
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => PregnancyViewModel()),
                ChangeNotifierProvider.value(value: calendar),
              ],
              child: const Center(
                child: SizedBox(width: 340, child: CalendarGrid()),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(calendar.isPeriodDay(faded), isTrue);

    // Aynı rakam ayın içinde de olabilir; ızgarada ilk sıradaki hücre
    // önceki ayınki.
    final cell = find.text('${faded.day}').first;
    final text = tester.widget<Text>(cell);
    final color =
        text.style?.color ??
        DefaultTextStyle.of(tester.element(cell)).style.color;
    final t =
        Theme.of(tester.element(cell)).extension<AppTokens>() ??
        AppTokens.light;

    expect(
      color,
      AppContrast.on(t.flow),
      reason: 'Bandın üstündeki rakam soluk griyle okunmuyordu',
    );
  });
}
