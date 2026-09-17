import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/calendar/widgets/day_detail_bottom_sheet.dart';

/// Gün detayında lekelenme.
///
/// Ara kanama neredeyse hep **geçmişe dönük** giriliyor: kişi çamaşırında
/// fark ediyor, o an uygulamayı açmıyor. Akış seçimi yalnızca regl
/// günlerinde göründüğü için lekelenme sadece "bugün" kaydedilebiliyordu —
/// yani klinik olarak en çok önemsediğimiz bulgu, tam da yakalanması
/// gereken durumda kaydedilemiyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;

  late CalendarViewModel viewModel;

  /// Geçmiş bir gün: ara kanamanın gerçekte girildiği zaman.
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  Future<void> openSheet(WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
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
            child: Scaffold(body: DayDetailBottomSheet(date: yesterday)),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder spottingSwitch() => find.ancestor(
    of: find.text(dictionary['log_flow_spotting'] as String),
    matching: find.byType(SwitchListTile),
  );

  Future<void> toggleSpotting(WidgetTester tester) async {
    await tester.ensureVisible(spottingSwitch().first);
    await tester.pump();
    await tester.tap(spottingSwitch().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  String? storedFlow() => viewModel.getDailyLogForDate(yesterday).flowIntensity;

  testWidgets('regl olmayan günde lekelenme anahtarı var', (tester) async {
    await openSheet(tester);

    expect(
      spottingSwitch(),
      findsOneWidget,
      reason: 'geçmiş bir güne lekelenme girilemiyor',
    );
    expect(
      tester.widget<SwitchListTile>(spottingSwitch().first).value,
      isFalse,
      reason: 'kayıt yokken kapalı başlamalı',
    );
  });

  testWidgets('anahtar lekelenmeyi kaydeder', (tester) async {
    await openSheet(tester);
    await toggleSpotting(tester);

    expect(storedFlow(), LogVocabulary.spotting);
  });

  testWidgets('lekelenme o günü regl yapmaz', (tester) async {
    await openSheet(tester);
    await toggleSpotting(tester);

    // Asıl kural bu: ara kanama döngü uzunluğunu ve tahminleri bozmamalı.
    expect(
      viewModel.isPeriodDay(yesterday),
      isFalse,
      reason: 'lekelenme regl günü sayılmamalı',
    );
    expect(viewModel.periodLogs, isEmpty);
  });

  testWidgets('anahtar kapatılınca kayıt temizlenir', (tester) async {
    // `flowIntensity: null` "değiştirme" anlamına geliyordu; `clearFlow`
    // olmadan yanlışlıkla açılan anahtar geri alınamazdı.
    await openSheet(tester);

    await toggleSpotting(tester);
    expect(storedFlow(), LogVocabulary.spotting);

    await toggleSpotting(tester);
    expect(storedFlow(), isNull, reason: 'lekelenme geri alınamıyor');
  });
}
