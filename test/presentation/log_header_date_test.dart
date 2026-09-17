import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/log_entry/widgets/log_entry_header.dart';

/// Kayıt ekranının başlığındaki tarih.
///
/// Başlık `log_date_example` adında sabit bir metin çiziyordu: takvim hangi
/// güne bakarsa baksın, ekran herkese "Bugün, 24 Ekim" diyordu. Kullanıcının
/// o gün girdiği akış, ağrı ve ruh hâli kayıtları doğru tarihe yazılıyordu —
/// yalnızca yazı yanlıştı, ki bu da "acaba hangi güne kaydettim?" sorusunu
/// doğuruyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpHeader(
    WidgetTester tester, {
    DateTime? date,
    String locale = 'tr',
  }) async {
    // `runAsync`: sözlük varlıklardan asenkron okunuyor; yalnızca pump
    // edilen bir testte hiçbir etiket çizilmiyor.
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
          home: Scaffold(body: LogEntryHeader(date: date)),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
  }

  /// Başlıktaki ilk satırın metni.
  String headerText(WidgetTester tester) =>
      tester.widgetList<Text>(find.byType(Text)).first.data!;

  testWidgets('verilen günü yazar', (tester) async {
    await pumpHeader(tester, date: DateTime(2026, 3, 5));

    final text = headerText(tester);
    expect(text, contains('5'), reason: 'gün numarası eksik');
    expect(text, contains('Mart'), reason: 'ay adı eksik');
  });

  testWidgets('gün değişince başlık da değişir', (tester) async {
    // Tek bir tarihi sınamak yetmez: sabit metin de o tarihi içerebilir.
    // Asıl iddia başlığın **değiştiği**.
    await pumpHeader(tester, date: DateTime(2026, 3, 5));
    final march = headerText(tester);

    await pumpHeader(tester, date: DateTime(2026, 11, 21));
    final november = headerText(tester);

    expect(november, isNot(march), reason: 'başlık tarihe göre değişmiyor');
    expect(november, contains('21'));
    expect(november, contains('Kasım'));
  });

  testWidgets('tarih verilmezse bugünü yazar', (tester) async {
    // Ekran her zaman bugünü kaydediyor; varsayılan da bugün olmalı.
    await pumpHeader(tester);
    final today = DateTime.now();

    expect(headerText(tester), contains('${today.day}'));
  });

  group('her dil şablonu dolduruyor', () {
    for (final locale in ['tr', 'en', 'de', 'es', 'fr', 'pt']) {
      testWidgets(locale, (tester) async {
        await pumpHeader(tester, date: DateTime(2026, 7, 9), locale: locale);

        final text = headerText(tester);
        // Eksik çeviri `tr()` içinde anahtarın kendisini döndürüyor;
        // doldurulmayan parametre de metinde süslü parantez bırakıyor.
        expect(text, isNot(contains('{')), reason: '$locale: parametre boşta');
        expect(text, isNot('log_date_today'), reason: '$locale: çeviri yok');
        expect(text, contains('9'), reason: '$locale: gün yazılmamış');
      });
    }
  });
}
