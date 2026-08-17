import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/localization/app_localizations.dart';

/// Gerçek JSON dosyalarını asset paketi üzerinden okur.
Future<AppLocalizations> load(String languageCode) async {
  final localizations = AppLocalizations(Locale(languageCode));
  await localizations.load();
  return localizations;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('desteklenen dillerin tamamı yüklenir', () {
    for (final code in AppLocalizations.supportedLanguageCodes) {
      test('$code.json yüklenir ve anahtarları çözer', () async {
        final l = await load(code);

        // Farklı ekranlardan örnek anahtarlar — hiçbiri ham anahtar dönmemeli.
        for (final key in [
          'onboarding_welcome_title',
          'log_flow_intensity',
          'calendar_legend_period',
          'privacy_delete_account',
          'log_symptom_cramp',
        ]) {
          final value = l.translate(key);
          expect(value, isNot(key), reason: '$code dilinde "$key" çözülemedi');
          expect(value.trim(), isNotEmpty);
        }
      });
    }
  });

  group('parametre yerleştirme', () {
    test('tek parametre değiştirilir', () async {
      final l = await load('tr');
      final text = l.translate('calendar_cycle_day', params: {'day': '7'});
      expect(text, contains('7'));
      expect(text, isNot(contains('{day}')));
    });

    test('her dilde placeholder gerçekten değiştirilir', () async {
      for (final code in AppLocalizations.supportedLanguageCodes) {
        final l = await load(code);
        final text = l.translate('duration_minutes', params: {'n': '20'});
        expect(text, contains('20'), reason: '$code dilinde sayı yerleşmedi');
        expect(
          text,
          isNot(contains('{n}')),
          reason: '$code dilinde {n} yer tutucusu kaldı',
        );
      }
    });
  });

  group('dayanıklılık', () {
    test('tanımsız anahtar için anahtarın kendisi döner', () async {
      final l = await load('tr');
      expect(l.translate('boyle_bir_anahtar_yok'), 'boyle_bir_anahtar_yok');
    });

    test('bilinmeyen dil fallback ile boş kalmaz', () async {
      // Delegate bunu desteklemez ama load() çökmemeli ve İngilizceye düşmeli.
      final l = AppLocalizations(const Locale('xx'));
      await l.load();
      expect(
        l.translate('onboarding_welcome_title'),
        isNot('onboarding_welcome_title'),
      );
    });
  });

  test('her dil dosyası aynı anahtar setine sahiptir', () async {
    final reference =
        json.decode(await rootBundle.loadString('lib/localization/en.json'))
            as Map<String, dynamic>;

    for (final code in AppLocalizations.supportedLanguageCodes) {
      final map =
          json.decode(
                await rootBundle.loadString('lib/localization/$code.json'),
              )
              as Map<String, dynamic>;

      expect(
        map.keys.toSet(),
        reference.keys.toSet(),
        reason: '$code.json anahtar seti en.json ile aynı değil',
      );
    }
  });
}
