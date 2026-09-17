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
import 'package:period_tracker/presentation/log_entry/widgets/pain_section.dart';

/// Kayıt ekranındaki ağrı bölümü.
///
/// Ağrı daha önce yalnızca takvimin gün detayında soruluyordu — uygulamanın
/// birincil kayıt yolu klinik olarak en önemli belirtiyi hiç sormuyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, dynamic> dictionaryFor(String locale) =>
      jsonDecode(File('lib/localization/$locale.json').readAsStringSync())
          as Map<String, dynamic>;

  final tr = dictionaryFor('tr');
  late CalendarViewModel viewModel;

  Future<void> open(
    WidgetTester tester, {
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
            child: const LogEntryScreen(),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Ağrı bölümü içindeki bir etiketi bulur.
  ///
  /// "Hafif" ve "Orta" hem akış yoğunluğunun hem ağrı şiddetinin kademesi;
  /// ekranın tamamında aramak yanlış çipe dokundurur.
  Finder inPain(String label) => find.descendant(
    of: find.byType(PainSection),
    matching: find.text(label),
  );

  Future<void> tapInPain(WidgetTester tester, String label) async {
    await tester.ensureVisible(inPain(label).first);
    await tester.pump();
    await tester.tap(inPain(label).first);
    await tester.pump();
  }

  testWidgets('kayıt ekranında ağrı bölümü var', (tester) async {
    await open(tester);
    expect(find.byType(PainSection), findsOneWidget);
  });

  group('kademeli açılma', () {
    testWidgets('şiddet seçilmeden yer ve bağlam sorulmaz', (tester) async {
      await open(tester);

      // Ağrısı olmayan kullanıcıya dört soru daha sormak ekranı
      // ağırlaştırmaktan başka bir işe yaramaz.
      expect(find.text(tr['log_pain_location'] as String), findsNothing);
      expect(find.text(tr['log_pain_when'] as String), findsNothing);
    });

    testWidgets('şiddet seçilince açılır', (tester) async {
      await open(tester);
      await tapInPain(tester, tr['log_pain_moderate'] as String);

      expect(find.text(tr['log_pain_location'] as String), findsOneWidget);
      expect(find.text(tr['log_pain_when'] as String), findsOneWidget);
      expect(
        find.text(tr['log_pain_when_intercourse'] as String),
        findsOneWidget,
      );
    });

    testWidgets('şiddet kaldırılınca kapanır', (tester) async {
      await open(tester);
      final moderate = tr['log_pain_moderate'] as String;

      await tapInPain(tester, moderate);
      await tapInPain(tester, moderate);

      expect(find.text(tr['log_pain_location'] as String), findsNothing);
    });
  });

  group('kaydetme', () {
    Future<void> save(WidgetTester tester) async {
      final button = find.byWidgetPredicate((w) => w is ElevatedButton);
      await tester.ensureVisible(button.first);
      await tester.pump();
      await tester.tap(button.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('yer ve bağlam kayda geçiyor', (tester) async {
      await open(tester);

      await tapInPain(tester, tr['log_pain_severe'] as String);
      await tapInPain(tester, tr['log_pain_loc_pelvis'] as String);
      await tapInPain(tester, tr['log_pain_when_bowel'] as String);
      await save(tester);

      final saved = viewModel.getDailyLogForDate(DateTime.now());
      expect(saved.painLevel, 'severe');
      expect(saved.painLocations, contains('pelvis'));
      expect(saved.painContexts, contains('bowel'));
    });

    testWidgets('şiddet kaldırılınca yer ve bağlam da düşer', (tester) async {
      // "Ağrım yok ama ilişkide ağrıyor" diye bir kayıt kalmamalı.
      await open(tester);
      final severe = tr['log_pain_severe'] as String;

      await tapInPain(tester, severe);
      await tapInPain(tester, tr['log_pain_loc_pelvis'] as String);
      await tapInPain(tester, severe);
      await save(tester);

      final saved = viewModel.getDailyLogForDate(DateTime.now());
      expect(saved.painLevel, isNull);
      expect(saved.painLocations, isEmpty);
    });
  });

  group('etiketler dar telefonda sığıyor', () {
    for (final locale in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      testWidgets(locale, (tester) async {
        await open(tester, locale: locale);
        final dictionary = dictionaryFor(locale);

        await tapInPain(
          tester,
          dictionary[LogVocabulary.painLevelKey('moderate')] as String,
        );

        for (final code in [
          ...LogVocabulary.painLocations.map(LogVocabulary.painLocationKey),
          ...LogVocabulary.painContexts.map(LogVocabulary.painContextKey),
        ]) {
          final label = dictionary[code] as String;
          expect(
            find.text(label),
            findsOneWidget,
            reason: '$locale: "$label" çizilmemiş',
          );
        }

        expect(
          tester.takeException(),
          isNull,
          reason: '$locale: düzen hatası',
        );
      });
    }
  });
}
