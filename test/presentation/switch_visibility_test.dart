import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/profile/cycle_settings_screen.dart';

/// Anahtarların açık hâlinde topuz görünüyor mu?
///
/// Döngü Ayarları ekranı `activeThumbColor`'ı rayla **aynı** renge
/// eziyordu: açıkken topuz kayboluyor, anahtar tek parça bir dikdörtgene
/// dönüşüyordu. Açık mı kapalı mı olduğu yalnızca renk tonundan
/// anlaşılıyordu — konumdan değil. Renk körlüğü olan ya da ekranı güneşte
/// okuyan biri için ayrım tamamen kayboluyor.
///
/// Tema bu renkleri zaten tek yerde tanımlıyor; ekranların ezmesi gereken
/// bir şey yok.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('anahtar renkleri tek kaynaktan', () {
    // Beş ekran temanın anahtar renklerini eziyordu. Biri topuzu rayla
    // aynı renge boyayıp görünmez kılmıştı; app lock kehribar renkteydi
    // (koruma açmak uyarı değil); ikisi de temanın aynısını tekrar
    // yazıyordu. Ezmeye izin verildiği sürece bir sonraki ekran da kendi
    // tonunu seçer.
    final sources = Directory('lib/presentation')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    /// Yorum satırları atılmış kaynak.
    ///
    /// Kuralı anlatan yorumun kuralı ihlal ediyormuş gibi görünmesi,
    /// testin kendi belgesini yakalaması demek olurdu.
    String code(File file) => file
        .readAsLinesSync()
        .where((line) => !line.trimLeft().startsWith('//'))
        .join('\n');

    test('ekranlar anahtar rengini ezmiyor', () {
      const overrides = [
        'activeThumbColor:',
        'activeTrackColor:',
        'inactiveThumbColor:',
        'inactiveTrackColor:',
      ];

      final offenders = <String>[];
      for (final file in sources) {
        final text = code(file);
        for (final override in overrides) {
          if (text.contains(override)) {
            offenders.add('${file.path} · $override');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason: 'tema eziliyor:\n${offenders.join('\n')}',
      );
    });

    test('tek anahtar biçimi kullanılıyor', () {
      // `CupertinoSwitch` Material temasını hiç görmüyor: aynı uygulamada
      // iki ayrı anahtar biçimi ve iki ayrı renk kaynağı demekti.
      final offenders = sources
          .where((f) => code(f).contains('CupertinoSwitch('))
          .map((f) => f.path)
          .toList();

      expect(offenders, isEmpty, reason: 'Cupertino anahtar: $offenders');
    });
  });

  for (final flavor in AppFlavor.values) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      testWidgets('${flavor.name} · ${brightness.name}', (tester) async {
        FlutterSecureStorage.setMockInitialValues({});
        SharedPreferences.setMockInitialValues({});

        final theme = brightness == Brightness.light
            ? AppTheme.light(flavor)
            : AppTheme.dark(flavor);

        await tester.runAsync(() async {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              locale: const Locale('tr'),
              supportedLocales: const [Locale('tr')],
              // Ekran evreyi takvimden okuyor (geçmiş regl girişi yalnızca
              // döngü evresinde).
              home: ChangeNotifierProvider(
                create: (_) => CalendarViewModel(),
                child: const CycleSettingsScreen(),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final tiles = tester.widgetList<SwitchListTile>(
          find.byType(SwitchListTile),
        );
        expect(tiles, isNotEmpty, reason: 'ekranda anahtar yok');

        const selected = <WidgetState>{WidgetState.selected};

        for (final tile in tiles) {
          // Ekran ezmediyse temadaki değer geçerli.
          final thumb =
              tile.activeThumbColor ??
              theme.switchTheme.thumbColor?.resolve(selected);
          final track =
              tile.activeTrackColor ??
              theme.switchTheme.trackColor?.resolve(selected);

          expect(thumb, isNotNull, reason: 'topuz rengi tanımsız');
          expect(track, isNotNull, reason: 'ray rengi tanımsız');
          expect(
            thumb,
            isNot(track),
            reason: 'açık anahtarda topuz raya karışıyor',
          );
        }
      });
    }
  }
}
