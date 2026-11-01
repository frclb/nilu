import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/cycle_settings_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/home/widgets/period_toggle_button.dart';

/// "Reglim bitti" ayarlanan süreden belirgin biçimde erken basılınca onay
/// istiyor.
///
/// Birinci günde bitirmek çoğu zaman yanlış dokunuş ya da kanamanın bir
/// günlüğüne azalması; bir günlük kayıt ortalama regl süresini ve
/// tahminleri kısaltıyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;
  String s(String key) => dictionary[key] as String;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  late CalendarViewModel viewModel;

  /// [day]. gününde süren bir dönem; regl süresi ayarı [planned].
  Future<void> pump(
    WidgetTester tester, {
    required int day,
    int planned = 5,
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await CycleSettingsRepository().saveCycleSettings(
        cycleLength: 28,
        periodLength: planned,
      );
      await PeriodRepository().savePeriodLogs([
        PeriodLog(
          id: 'p',
          startDate: today.subtract(Duration(days: day - 1)),
        ),
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
            child: const Scaffold(body: Center(child: PeriodToggleButton())),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tapEnd(WidgetTester tester) async {
    await tester.tap(find.text(s('home_period_end')));
    await tester.pumpAndSettle();
  }

  testWidgets('birinci günde soruyor; "devam ediyor" dönemi açık bırakıyor', (
    tester,
  ) async {
    await pump(tester, day: 1);
    expect(viewModel.currentPeriodDay, 1);

    await tapEnd(tester);
    expect(find.text(s('home_period_end_early_title')), findsOneWidget);
    expect(
      find.text(
        s(
          'home_period_end_early_body',
        ).replaceAll('{n}', '1').replaceAll('{planned}', '5'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text(s('home_period_end_early_keep')));
    await tester.pumpAndSettle();
    expect(viewModel.periodActionToday, PeriodAction.end);
  });

  testWidgets('"evet, bitti" dönemi bugün kapatıyor', (tester) async {
    await pump(tester, day: 2);

    await tapEnd(tester);
    await tester.runAsync(() async {
      await tester.tap(find.text(s('home_period_end_early_confirm')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(viewModel.periodActionToday, PeriodAction.endedToday);
  });

  testWidgets('ayara yakın günde sormuyor', (tester) async {
    await pump(tester, day: 4);

    await tester.runAsync(() async {
      await tester.tap(find.text(s('home_period_end')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text(s('home_period_end_early_title')), findsNothing);
    expect(viewModel.periodActionToday, PeriodAction.endedToday);
  });

  testWidgets('üç günlük ayarda yalnızca ilk gün soruyor', (tester) async {
    await pump(tester, day: 2, planned: 3);

    await tester.runAsync(() async {
      await tester.tap(find.text(s('home_period_end')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text(s('home_period_end_early_title')), findsNothing);
  });
}
