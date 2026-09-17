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
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
import 'package:period_tracker/presentation/log_entry/widgets/flow_intensity_section.dart';

/// Lekelenme kaydetmek regl başlatmamalı.
///
/// Kuralın kendisi `flow_intensity_test.dart` içinde birim olarak sınanıyor;
/// burada **ekranın o kuralı gerçekten uyguladığı** doğrulanıyor. Kayıt
/// ekranı "akış girildiyse kanama var demektir" deyip herhangi bir değerde
/// dönemi başlatıyordu: lekelenen bir gün regl günü sayılsaydı döngü
/// uzunluğu bozulur, hatta haksız "kısa döngü" uyarısı çıkabilirdi.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dictionary =
      jsonDecode(File('lib/localization/tr.json').readAsStringSync())
          as Map<String, dynamic>;

  late CalendarViewModel viewModel;

  Future<void> openLogEntry(WidgetTester tester) async {
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
            child: const LogEntryScreen(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Akış kademesini seçip kaydeder.
  ///
  /// Arama akış bölümüne daraltılıyor: "Hafif" ve "Orta" hem akış
  /// yoğunluğunun hem ağrı şiddetinin kademesi. Ekranın tamamında aramak
  /// iki sonuç bulur ve yanlış çipe dokunma riski taşır.
  Future<void> pickFlowAndSave(WidgetTester tester, String code) async {
    final option = find.descendant(
      of: find.byType(FlowIntensitySection),
      matching: find.text(dictionary[LogVocabulary.flowKey(code)] as String),
    );
    expect(option, findsOneWidget, reason: '$code seçeneği ekranda yok');

    await tester.ensureVisible(option);
    await tester.pump();
    await tester.tap(option);
    await tester.pump();

    final save = find.byWidgetPredicate((w) => w is ElevatedButton);
    await tester.ensureVisible(save.first);
    await tester.pump();
    await tester.tap(save.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('lekelenme regl kaydı oluşturmaz', (tester) async {
    await openLogEntry(tester);
    expect(viewModel.periodLogs, isEmpty, reason: 'başlangıçta kayıt olmamalı');

    await pickFlowAndSave(tester, LogVocabulary.spotting);

    expect(
      viewModel.periodLogs,
      isEmpty,
      reason: 'ara kanama bir regl dönemi başlatmamalı',
    );
    expect(
      viewModel.isPeriodDay(DateTime.now()),
      isFalse,
      reason: 'lekelenilen gün regl günü sayılmamalı',
    );
  });

  testWidgets('gerçek kanama regl kaydı oluşturur', (tester) async {
    // Karşı taraf da sınanmalı: kural fazla geniş olsaydı lekelenme testi
    // geçerdi ama uygulama hiçbir zaman regl başlatmazdı.
    await openLogEntry(tester);

    await pickFlowAndSave(tester, 'medium');

    expect(
      viewModel.periodLogs,
      isNotEmpty,
      reason: 'orta yoğunlukta akış dönemi başlatmalı',
    );
    expect(viewModel.isPeriodDay(DateTime.now()), isTrue);
  });

  testWidgets('"yok" regl kaydı oluşturmaz', (tester) async {
    await openLogEntry(tester);

    await pickFlowAndSave(tester, 'none');

    expect(viewModel.periodLogs, isEmpty);
  });
}
