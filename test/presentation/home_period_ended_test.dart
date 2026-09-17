import 'dart:convert';
import 'dart:io';

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
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_masthead.dart';
import 'package:period_tracker/presentation/home/widgets/period_toggle_button.dart';

/// "Reglim bitti"ye bastıktan sonra ana ekran.
///
/// Ekran aynı anda iki şey söylüyordu: altta "Reglin bugün bitti", ortada
/// sayfanın en büyük yazısıyla "REGL · 3. gün". İkisi de modele göre
/// doğruydu (bugün reglin son günü) ama çark dönemin bittiğine dair hiçbir
/// iz taşımıyordu — kullanıcı hâlâ regl gününde olduğunu okuyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final defaultStart = today.subtract(const Duration(days: 2));

  late CalendarViewModel viewModel;

  /// Ana ekranın iki bileşenini birlikte çizer: çelişki ancak ikisi aynı
  /// anda ekrandayken görülüyor.
  Future<void> pumpHome(
    WidgetTester tester, {
    DateTime? endDate,
    DateTime? start,
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await PeriodRepository().savePeriodLogs([
        PeriodLog(id: 'p', startDate: start ?? defaultStart, endDate: endDate),
      ]);

      viewModel = CalendarViewModel();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(AppFlavor.plum),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: const Locale('tr'),
          supportedLocales: const [Locale('tr')],
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: const Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [CycleMasthead(), PeriodToggleButton()],
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String s(String key) => dictionary[key] as String;

  /// Çarkın ortasındaki cümle.
  String headline(WidgetTester tester) {
    final ring = find.byType(CycleMasthead);
    final texts = tester
        .widgetList<Text>(find.descendant(of: ring, matching: find.byType(Text)))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    return texts.join(' | ');
  }

  testWidgets('kurulum doğru: dönem devam ederken gün sayısı yazıyor', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(
      headline(tester),
      contains(s('home_headline_period_day').replaceAll('{n}', '3')),
      reason: 'devam eden dönemde "3. gün" beklenir',
    );
  });

  testWidgets('dönem bugün bitince çark bunu söylüyor', (tester) async {
    await pumpHome(tester, endDate: today);

    // Asıl iddia: çark devam eden dönemle aynı şeyi söylememeli.
    expect(
      headline(tester),
      isNot(contains(s('home_headline_period_day').replaceAll('{n}', '3'))),
      reason: 'dönem bittiği hâlde "3. gün" yazıyor — devam ediyor gibi okunuyor',
    );
  });

  testWidgets('düğme ile çark aynı şeyi söylüyor', (tester) async {
    await pumpHome(tester, endDate: today);

    expect(
      find.text(s('home_period_ended_today')),
      findsOneWidget,
      reason: 'düğme yerine onay metni beklenir',
    );
    expect(
      headline(tester),
      contains(s('home_headline_period_finished').replaceAll('{n}', '3')),
      reason: 'çark da dönemin bittiğini söylemeli',
    );
  });

  testWidgets('dün bitirilen dönemde normal akışa dönülüyor', (tester) async {
    await pumpHome(tester, endDate: today.subtract(const Duration(days: 1)));

    // Bitiş cümlesi yalnızca o güne ait; ertesi gün döngü sayacı devam eder.
    expect(
      headline(tester),
      isNot(contains(s('home_headline_period_finished').replaceAll('{n}', '2'))),
    );
  });

  /// Çark ile düğme aynı veriden besleniyor; hiçbir durumda farklı şey
  /// söylememeliler.
  ///
  /// Bildirilen hata tek bir durumda ortaya çıktı ama sebebi geneldi:
  /// [CycleInfo] "dönem kapandı" bilgisini taşımıyordu. Aynı sınıftan bir
  /// hatanın tekrar sızmaması için durumlar matris hâlinde sınanıyor.
  group('çark ile düğme çelişmiyor', () {
    final cases = <String, DateTime?>{
      'devam eden dönem': null,
      'bugün bitirilen dönem': today,
      'dün bitirilen dönem': today.subtract(const Duration(days: 1)),
      'üç gün önce bitirilen dönem': today.subtract(const Duration(days: 3)),
    };

    for (final entry in cases.entries) {
      testWidgets(entry.key, (tester) async {
        await pumpHome(tester, endDate: entry.value);

        final ongoing = find.text(s('home_period_end'));
        final claimsPeriodDay = headline(
          tester,
        ).contains(s('home_headline_period_day').replaceAll('{n}', '3'));

        // Değişmez: "bugün regl gününün N.'sindesin" cümlesi yalnızca
        // dönem gerçekten devam ederken çıkabilir. Bittiği hâlde çıkarsa
        // kullanıcı hâlâ kanadığını okur.
        if (claimsPeriodDay) {
          expect(
            ongoing,
            findsOneWidget,
            reason:
                '${entry.key}: çark "3. gün" diyor ama dönem devam etmiyor',
          );
        }
      });
    }

    testWidgets('aynı gün başlayıp biten dönem', (tester) async {
      // Uç durum: başlangıç ile bitiş aynı gün. Uzunluk 1 olmalı, "0 gün
      // sürdü" ya da eksi bir sayı çıkmamalı.
      await pumpHome(tester, start: today, endDate: today);

      expect(
        headline(tester),
        contains(s('home_headline_period_finished').replaceAll('{n}', '1')),
      );
    });
  });
}
