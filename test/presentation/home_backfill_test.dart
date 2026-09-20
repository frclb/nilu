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
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_masthead.dart';

/// Takvimden geçmişe dönük regl girişi → ana ekran.
///
/// Kullanıcının bildirdiği hata: "17'sinde başladı" diye girdiğinde takvimdeki
/// bant bugünden önce kesiliyor, ana ekran da dönemi bitmiş sayıyordu. Sebebi
/// `toggleDay`'in eklediği günü kapalı kaydetmesiydi.
///
/// Alan testleri ([test/domain/backfill_period_test.dart]) kaydın doğru
/// kurulduğunu gösteriyor; burada asıl kullanıcı yolu baştan sona koşuyor:
/// takvimde bir güne dokun, ana ekranın ne yazdığına bak. Modelin doğru olması
/// ekranın doğru olduğunu kanıtlamıyor — o iddiayı ancak çizim kurar.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;
  String s(String key) => dictionary[key] as String;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  late CalendarViewModel viewModel;

  Future<void> pumpHome(WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      // Hiç kayıt yok: kullanıcı uygulamayı yeni kurmuş ve geçmişe dönük
      // giriş yapacak.
      await PeriodRepository().savePeriodLogs([]);

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
              body: SingleChildScrollView(child: CycleMasthead()),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String headline(WidgetTester tester) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(CycleMasthead),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data)
      .whereType<String>()
      .join(' | ');

  testWidgets('4 gün önceyi işaretlemek ana ekranı 5. güne getiriyor', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.runAsync(() async {
      await viewModel.togglePeriodDay(today.subtract(const Duration(days: 4)));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final text = headline(tester);

    expect(
      text,
      contains(s('home_headline_period_day').replaceAll('{n}', '5')),
      reason: 'Regl 4 gün önce başladıysa bugün 5. gündür.',
    );
    expect(
      text,
      isNot(contains(s('home_period_ended_today'))),
      reason: 'Geçmişe dönük giriş dönemi bitirmiş sayılıyordu.',
    );
  });

  testWidgets('takvimdeki bant bugünü kapsıyor', (tester) async {
    await pumpHome(tester);

    await tester.runAsync(() async {
      await viewModel.togglePeriodDay(today.subtract(const Duration(days: 4)));
    });
    await tester.pump();

    // Takvimin boyadığı günler: aradaki hiçbir gün atlanmamalı.
    for (var d = 4; d >= 0; d--) {
      expect(
        viewModel.isPeriodDay(today.subtract(Duration(days: d))),
        isTrue,
        reason: '$d gün önceki gün takvimde boş kalıyor.',
      );
    }
  });
}
