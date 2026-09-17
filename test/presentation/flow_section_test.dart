import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/domain/models/log_vocabulary.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/log_entry/widgets/flow_intensity_section.dart';

/// Akış yoğunluğu seçenekleri.
///
/// Sözlüğe "lekelenme" eklenince seçenek sayısı dörtten beşe çıktı. Eşit
/// bölünen bir `Row` içinde dar bir telefonda etiket başına ~35 pt kalıyordu
/// ve "Lekelenme" üç satıra bölünüyordu.
///
/// Taşma iddiası bunu yakalamaz: metin taşmıyor, **sarıyor**. O yüzden
/// etiketin tek satırda kaldığı yükseklikten ölçülüyor.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 12 punto bir etiketin tek satır yüksekliği ~15 pt; iki satır ~30.
  /// Eşik ikisinin arasında.
  const singleLineLimit = 24.0;

  Map<String, dynamic> dictionaryFor(String locale) =>
      jsonDecode(File('lib/localization/$locale.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<void> pumpSection(
    WidgetTester tester, {
    required double width,
    required String locale,
  }) async {
    tester.view.physicalSize = Size(width * 3, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // `runAsync`: `Localizations` sözlüğü varlıklardan asenkron okuyor ve o
    // çözülene kadar altına `SizedBox` koyuyor — yalnızca pump edilen bir
    // testte hiçbir etiket çizilmiyor.
    await tester.runAsync(() async {
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: FlowIntensitySection(onChanged: (_) {}),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  group('etiketler tek satırda kalır', () {
    // En dar telefon ve en uzun etiket birlikte sınanıyor: Almanca
    // "Schmierblutung" listedeki en uzun kelime.
    for (final locale in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      testWidgets('iPhone 16e — $locale', (tester) async {
        await pumpSection(tester, width: 390, locale: locale);

        final dictionary = dictionaryFor(locale);

        for (final code in LogVocabulary.flowIntensities) {
          final label = dictionary[LogVocabulary.flowKey(code)] as String;
          final finder = find.text(label);

          expect(
            finder,
            findsOneWidget,
            reason: '$locale: "$label" seçeneği çizilmemiş',
          );
          expect(
            tester.getRect(finder).height,
            lessThan(singleLineLimit),
            reason: '$locale: "$label" birden fazla satıra bölünüyor',
          );
        }

        expect(tester.takeException(), isNull, reason: '$locale: düzen hatası');
      });
    }
  });

  group('sözlükteki her kademe gösteriliyor', () {
    testWidgets('beş seçenek de ekranda', (tester) async {
      await pumpSection(tester, width: 390, locale: 'tr');

      final dictionary = dictionaryFor('tr');

      // Lekelenme gösterilmezse kullanıcı ara kanamayı kaydedemez ve onu
      // regl olarak işaretlemek zorunda kalır — kaydetmek istediğimiz
      // klinik bulgunun tam tersi.
      for (final code in LogVocabulary.flowIntensities) {
        expect(
          find.text(dictionary[LogVocabulary.flowKey(code)] as String),
          findsOneWidget,
          reason: '$code seçeneği eksik',
        );
      }
    });
  });
}
