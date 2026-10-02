import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/view_models/pregnancy_view_model.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/calendar_grid.dart';

import '../dst_support.dart';

/// Takvim bandının komşu günleri yaz saatinde de doğru.
///
/// Hücre, bandın sola ya da sağa sürüp sürmediğini komşu güne bakarak
/// buluyor; komşu `date ± Duration(days: 1)` idi. Avrupa'da ve ABD'de saat
/// pazar gecesi değişiyor: ilkbaharda pazartesinin "dünü" cumartesiye,
/// sonbaharda pazarın "yarını" yine pazara düşüyordu. Tek günlük bir regl
/// satır sonunda "sonraki satırda sürüyor" diye sönen bir bantla çiziliyordu.
///
/// Türkiye saatinde kendiliğinden geçer; asıl sınama `dst_timezones_test`
/// ile yaz saatli saat dilimlerinde.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  expectDstZoneInChild();

  Future<void> ac(
    WidgetTester tester,
    List<PeriodLog> kayitlar,
    DateTime ay,
  ) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late CalendarViewModel vm;
    await tester.runAsync(() async {
      await const PeriodRepository().savePeriodLogs(kayitlar);
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
                ChangeNotifierProvider(create: (_) => vm = CalendarViewModel()),
              ],
              child: const Center(
                child: SizedBox(width: 360, child: CalendarGrid()),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();

    while (vm.currentMonth.year * 12 + vm.currentMonth.month <
        ay.year * 12 + ay.month) {
      vm.nextMonth();
    }
    while (vm.currentMonth.year * 12 + vm.currentMonth.month >
        ay.year * 12 + ay.month) {
      vm.previousMonth();
    }
    await tester.pumpAndSettle();
  }

  /// [gun] hücresindeki bant parçaları (bağlayıcılar).
  ///
  /// Ayın 1'i ızgarada iki kez görünebiliyor (sonraki ayın soluk günü);
  /// ayın kendi günü ızgarada önce geliyor.
  List<Positioned> bant(WidgetTester tester, int gun) {
    final metin = find.descendant(
      of: find.byType(CalendarGrid),
      matching: find.text('$gun'),
    );
    final hucre = find
        .ancestor(of: metin.first, matching: find.byType(Stack))
        .first;
    expect(
      tester.widget<Stack>(hucre).clipBehavior,
      Clip.none,
      reason: 'Bulunan yığın hücrenin bant yığını değil',
    );
    return tester
        .widgetList<Positioned>(
          find.descendant(of: hucre, matching: find.byType(Positioned)),
        )
        .toList();
  }

  for (final t in dstTransitions) {
    DateTime g(int n) => dstDay(t, n);
    final ad = '${t.day}.${t.month}';

    if (t.month == 3) {
      testWidgets('$ad: pazartesinin dünü pazar, cumartesi değil', (
        tester,
      ) async {
        // Cumartesi ve pazartesi tek günlük regl; pazar boş.
        await ac(tester, [
          PeriodLog(id: 'cmt', startDate: g(-1), endDate: g(-1)),
          PeriodLog(id: 'pzt', startDate: g(1), endDate: g(1)),
        ], t);
        expect(
          bant(tester, g(1).day),
          isEmpty,
          reason: 'Pazartesi "önceki satırdan sürüyor" diye çizildi',
        );
      });
    } else {
      testWidgets('$ad: pazarın yarını pazartesi, yine pazar değil', (
        tester,
      ) async {
        await ac(tester, [
          PeriodLog(id: 'pz', startDate: g(0), endDate: g(0)),
        ], t);
        expect(
          bant(tester, t.day),
          isEmpty,
          reason: 'Tek günlük regl "sonraki satırda sürüyor" diye çizildi',
        );
      });

      testWidgets('$ad: pazar biten tahmin bandının ucu kapalı', (
        tester,
      ) async {
        // 28 günlük iki döngü: tahmin edilen regl t-4..t (pazar biter).
        await ac(tester, [
          PeriodLog(id: 'a', startDate: g(-60), endDate: g(-56)),
          PeriodLog(id: 'b', startDate: g(-32), endDate: g(-28)),
        ], t);
        final parcalar = bant(tester, t.day);
        expect(parcalar, hasLength(1), reason: 'Tahmin bandı yok');
        final kap = (parcalar.single.child as Container).decoration;
        expect(
          ((kap as BoxDecoration).borderRadius as BorderRadius).topRight,
          const Radius.circular(20),
          reason: 'Bandın sağ ucu "sonraki satırda sürüyor" diye düz',
        );
      });
    }
  }
}
