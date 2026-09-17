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
import 'package:period_tracker/presentation/home/widgets/period_toggle_button.dart';

/// Ana ekrandaki geri alma.
///
/// Geri alma yalnızca eylemin ardından çıkan geçici bildirimdeydi. Bildirim
/// geçince dönüş yolu kalmıyordu: yanlışlıkla "Reglim başladı"ya basan
/// kullanıcıyı karşılayan "Reglim bitti" bir çıkış değil — bir günlük
/// sahte dönem yaratıyor ve `lastPeriodStart` kaydığı için bütün
/// tahminleri de bozuyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  late CalendarViewModel viewModel;

  Map<String, dynamic> dictionaryFor(String locale) =>
      jsonDecode(File('lib/localization/$locale.json').readAsStringSync())
          as Map<String, dynamic>;

  final tr = dictionaryFor('tr');

  Future<void> pump(
    WidgetTester tester, {
    List<PeriodLog> logs = const [],
    double width = 390,
    String locale = 'tr',
  }) async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = Size(width * 3, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      await PeriodRepository().savePeriodLogs(logs);
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
          locale: Locale(locale),
          supportedLocales: [Locale(locale)],
          home: ChangeNotifierProvider.value(
            value: viewModel,
            child: const Scaffold(body: PeriodToggleButton()),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder undoButton(String locale) =>
      find.text(dictionaryFor(locale)['home_period_undo'] as String);

  /// "Reglim başladı"ya basar, gerekiyorsa erken başlatma onayını geçer.
  ///
  /// Tahmin edilen tarihten bir haftadan fazla önce basıldığında uygulama
  /// onay soruyor; testin o diyaloğu geçmesi gerekiyor yoksa işlem hiç
  /// gerçekleşmiyor ve iddia sessizce yanlış sebepten düşüyor.
  Future<void> tapStart(WidgetTester tester) async {
    await tester.tap(find.text(tr['home_period_start'] as String));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final confirm = find.text(tr['home_period_early_confirm'] as String);
    if (confirm.evaluate().isNotEmpty) {
      await tester.tap(confirm);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('yalnızca geri alınacak bir şey varken görünüyor', () {
    testWidgets('kayıt yokken yok', (tester) async {
      await pump(tester);

      expect(find.text(tr['home_period_start'] as String), findsOneWidget);
      expect(
        undoButton('tr'),
        findsNothing,
        reason: 'geri alınacak bir şey yokken düğme durmamalı',
      );
    });

    testWidgets('dün başlamış süren dönemde yok', (tester) async {
      // Geri alma bugünü kayıttan çıkarırdı; bu geri alma değil, veri
      // bozmak olurdu. Dönem dün başladı, bugüne ait bir işlem yok.
      await pump(
        tester,
        logs: [
          PeriodLog(
            id: 'p',
            startDate: today.subtract(const Duration(days: 3)),
          ),
        ],
      );

      expect(find.text(tr['home_period_end'] as String), findsOneWidget);
      expect(undoButton('tr'), findsNothing);
    });

    testWidgets('bugün başlatılan dönemde var', (tester) async {
      await pump(tester, logs: [PeriodLog(id: 'p', startDate: today)]);

      expect(
        undoButton('tr'),
        findsOneWidget,
        reason: 'yanlışlıkla başlatan kullanıcının çıkışı olmalı',
      );
    });

    testWidgets('bugün bitirilen dönemde var', (tester) async {
      await pump(
        tester,
        logs: [
          PeriodLog(
            id: 'p',
            startDate: today.subtract(const Duration(days: 2)),
            endDate: today,
          ),
        ],
      );

      expect(find.text(tr['home_period_ended_today'] as String), findsOneWidget);
      expect(undoButton('tr'), findsOneWidget);
    });
  });

  group('geri alma gerçekten çalışıyor', () {
    testWidgets('bugün başlatılan kayıt tamamen siliniyor', (tester) async {
      await pump(tester, logs: [PeriodLog(id: 'p', startDate: today)]);

      await tester.tap(undoButton('tr'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        viewModel.periodLogs,
        isEmpty,
        reason: 'kayıt silinmeli; bir günlük sahte dönem kalmamalı',
      );
      expect(find.text(tr['home_period_start'] as String), findsOneWidget);
    });

    testWidgets('bitirilen dönem yeniden açılıyor', (tester) async {
      await pump(
        tester,
        logs: [
          PeriodLog(
            id: 'p',
            startDate: today.subtract(const Duration(days: 2)),
            endDate: today,
          ),
        ],
      );

      await tester.tap(undoButton('tr'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Dönem eski olduğu için kayıt silinmiyor, yeniden açılıyor:
      // oradaki günler gerçek veri.
      expect(viewModel.periodLogs, hasLength(1));
      expect(viewModel.periodLogs.first.isOngoing, isTrue);
      expect(find.text(tr['home_period_end'] as String), findsOneWidget);
    });

    testWidgets('geri alma sonrası düğme yeniden kullanılabilir', (
      tester,
    ) async {
      await pump(tester, logs: [PeriodLog(id: 'p', startDate: today)]);

      await tester.tap(undoButton('tr'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Geri almanın kendisi yeni bir geri alma sunmuyor: geri almanın
      // geri alması kullanıcıyı nerede olduğunu bilemediği bir döngüye
      // sokardı.
      expect(undoButton('tr'), findsNothing);
    });
  });

  group('oturumda yapılan işlem de geri alınabiliyor', () {
    testWidgets('dün biten dönemi bugün işaretleyince çıkış var', (
      tester,
    ) async {
      // Bu durum kayıtta iz bırakmıyor: dün biten dönem yeniden açılıyor,
      // yeni kayıt oluşmuyor. Kaydın ilk günü günler öncesi olduğu için
      // "bugün bir şey yapıldı" ancak oturumdan bilinebiliyor.
      await pump(
        tester,
        logs: [
          PeriodLog(
            id: 'p',
            startDate: today.subtract(const Duration(days: 3)),
            endDate: today.subtract(const Duration(days: 1)),
          ),
        ],
      );

      expect(
        undoButton('tr'),
        findsNothing,
        reason: 'işlem yapılmadan önce çıkış olmamalı',
      );

      await tapStart(tester);

      expect(
        viewModel.periodLogs.first.isOngoing,
        isTrue,
        reason: 'kayıt yeniden açılmalı, yeni dönem açılmamalı',
      );
      expect(
        undoButton('tr'),
        findsOneWidget,
        reason: 'kazayla basan kullanıcının çıkışı olmalı',
      );
    });

    testWidgets('geri alınca bitiş tarihi geri geliyor', (tester) async {
      await pump(
        tester,
        logs: [
          PeriodLog(
            id: 'p',
            startDate: today.subtract(const Duration(days: 3)),
            endDate: today.subtract(const Duration(days: 1)),
          ),
        ],
      );

      await tapStart(tester);

      await tester.tap(undoButton('tr'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(viewModel.periodLogs, hasLength(1));
      expect(
        viewModel.periodLogs.first.endDate,
        isNotNull,
        reason: 'dönem yeniden kapanmalı',
      );
      expect(
        viewModel.isPeriodDay(today),
        isFalse,
        reason: 'bugün kayıttan çıkmalı',
      );
    });
  });

  group('dar telefonda sığıyor', () {
    for (final locale in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      testWidgets(locale, (tester) async {
        await pump(
          tester,
          logs: [PeriodLog(id: 'p', startDate: today)],
          locale: locale,
        );

        expect(undoButton(locale), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: '$locale: düzen hatası',
        );
      });
    }
  });
}
