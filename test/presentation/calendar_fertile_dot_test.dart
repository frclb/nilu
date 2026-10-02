import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/calendar_grid.dart';

/// Regl gününde doğurganlık noktası çizilmemeli.
///
/// Kısa döngüde doğurganlık penceresi regl günlerine taşıyor: 21 günlük
/// döngüde yumurtlama 7. güne düşer, pencere 2–8 arasıdır. Model bunu doğru
/// söylüyor. Hücre ise iki işareti üst üste koymuyor:
/// `isFertile && !isPeriod`.
///
/// Bu dosya ekranı **gerçekten çiziyor** ve noktaları widget ağacından
/// buluyor. Model düzeyindeki tarama (`calendar_day_consistency_test`) bu
/// kuralı yansıtıyor ama okumuyor: widget'taki `!isPeriod` silinse o test
/// yakalamaz, bu yakalar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final marka = AppTheme.light(AppFlavor.plum).colorScheme.primary;

  /// Hücrenin altındaki doğurganlık noktası.
  ///
  /// Renk marka rengi; lejant da artık aynısını gösteriyor. Boyut ayırt
  /// edici: lejant örnekleri 8, hücre noktaları 5 — ilk denemede yalnızca
  /// lejant örneği bulunmuş ve test boş yere geçmişti.
  Finder dogurganlikNoktasi() => find.byWidgetPredicate((w) {
    if (w is! Container) return false;
    final d = w.decoration;
    return d is BoxDecoration &&
        d.shape == BoxShape.circle &&
        d.color == marka &&
        w.constraints?.maxWidth == 5;
  });

  testWidgets('regl günü olan hücrede doğurganlık noktası yok', (tester) async {
    final simdi = DateTime.now();
    final bugun = DateTime(simdi.year, simdi.month, simdi.day);
    // Regl üç gün önce başladı: bugün döngünün 4. günü.
    final baslangic = bugun.subtract(const Duration(days: 3));

    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late CalendarViewModel vm;

    await tester.runAsync(() async {
      // Kısa döngü: doğurganlık penceresi regl günlerine taşısın.
      await const CycleSettingsRepository().saveInitialSettings(
        cycleLength: 21,
        periodLength: 7,
      );
      await PeriodRepository().savePeriodLogs([
        PeriodLog(id: 'p', startDate: baslangic),
      ]);

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
            body: Builder(
              builder: (context) => MultiProvider(
                // Uygulamadaki gibi: ızgara gebelik izini de okuyor.
                providers: [
                  ChangeNotifierProvider(create: (_) => PregnancyViewModel()),
                  ChangeNotifierProvider(
                    create: (_) => vm = CalendarViewModel(),
                  ),
                ],
                child: const Center(
                  child: SizedBox(width: 340, child: CalendarGrid()),
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Senaryo gerçekten kurulmuş mu? Kurulmadıysa test boş yere geçer.
    expect(
      vm.isPeriodDay(bugun),
      isTrue,
      reason: 'senaryo kurulmadı: bugün regl günü değil',
    );
    expect(
      vm.cycleInfo.isFertile(bugun),
      isTrue,
      reason: 'senaryo kurulmadı: bugün doğurganlık penceresinde değil',
    );

    // Kontrol noktası: görünen ayda doğurgan **ama regl olmayan** bir gün
    // varsa orada nokta çizilmeli. Böyle bir gün her zaman olmuyor — ay
    // sonunda pencerenin tamamı sonraki aya kayıyor ve ızgarada hiç nokta
    // kalmıyor. Testi takvime bağlamamak için koşullu sınanıyor; asıl
    // iddia (bugünün hücresinde nokta yok) her hâlükârda geçerli.
    final ayinIlki = DateTime(bugun.year, bugun.month, 1);
    final ayinSonu = DateTime(bugun.year, bugun.month + 1, 0);
    var kontrolGunuVar = false;
    for (
      var g = ayinIlki;
      !g.isAfter(ayinSonu);
      g = g.add(const Duration(days: 1))
    ) {
      if (vm.cycleInfo.isFertile(g) &&
          !vm.isPeriodDay(g) &&
          !vm.cycleInfo.isOvulationDay(g)) {
        kontrolGunuVar = true;
        break;
      }
    }

    final dogurgan = dogurganlikNoktasi();
    if (kontrolGunuVar) {
      expect(
        dogurgan,
        findsWidgets,
        reason: 'doğurgan gün var ama hiç nokta çizilmemiş',
      );
    }

    // Bugünün hücresi: sayının bulunduğu sütun, sayının hemen altı.
    final sayi = find.text('${bugun.day}');
    expect(sayi, findsWidgets);

    final hucreler = sayi
        .evaluate()
        .map((e) => tester.getRect(find.byWidget(e.widget)))
        .toList();

    for (final nokta in dogurgan.evaluate()) {
      final nr = tester.getRect(find.byWidget(nokta.widget));
      for (final h in hucreler) {
        final ayniSutun = (nr.center.dx - h.center.dx).abs() < 16;
        final altinda = nr.top >= h.top && nr.top - h.bottom < 30;
        expect(
          ayniSutun && altinda,
          isFalse,
          reason:
              'bugün hem regl hem doğurganlık günü; hücresinde doğurganlık '
              'noktası çizilmiş',
        );
      }
    }
  });
}
