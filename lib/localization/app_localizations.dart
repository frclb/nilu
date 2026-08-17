import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  /// Desteklenen diller. `supportedLocales` (main.dart) ile eşleşmelidir.
  static const List<String> supportedLanguageCodes = [
    'tr',
    'en',
    'de',
    'fr',
    'es',
    'pt',
  ];

  /// Bir anahtar aktif dilde bulunamazsa bu dilden doldurulur.
  static const String fallbackLanguageCode = 'en';

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  /// Aktif dilin sözlüğünü yükler, eksik anahtarları [fallbackLanguageCode]
  /// sözlüğünden tamamlar.
  ///
  /// Dosya eksik, boş veya bozuksa **exception fırlatmaz**: o dil boş kabul
  /// edilir ve tamamen fallback'e düşer. (Eskiden boş bir dil dosyası
  /// `json.decode` aşamasında uygulamayı açılışta çökertiyordu.)
  Future<bool> load() async {
    _localizedStrings = await _loadLanguageMap(locale.languageCode);

    if (locale.languageCode != fallbackLanguageCode) {
      final fallback = await _loadLanguageMap(fallbackLanguageCode);
      for (final entry in fallback.entries) {
        _localizedStrings.putIfAbsent(entry.key, () => entry.value);
      }
    }

    return true;
  }

  static Future<Map<String, String>> _loadLanguageMap(
    String languageCode,
  ) async {
    try {
      final jsonString = await rootBundle.loadString(
        'lib/localization/$languageCode.json',
      );

      if (jsonString.trim().isEmpty) {
        debugPrint('Localization: $languageCode.json is empty.');
        return {};
      }

      final decoded = json.decode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('Localization: $languageCode.json is not a JSON object.');
        return {};
      }

      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      debugPrint('Localization: failed to load $languageCode.json — $e');
      return {};
    }
  }

  String translate(String key, {Map<String, String>? params}) {
    final template = _localizedStrings[key];

    if (template == null) {
      assert(() {
        debugPrint(
          'Localization: missing key "$key" for '
          '${locale.languageCode} (and fallback).',
        );
        return true;
      }());
      return key;
    }

    String text = template;
    if (params != null) {
      params.forEach((k, v) {
        text = text.replaceAll('{$k}', v);
      });
    }
    return text;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLanguageCodes.contains(
      locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsExtension on BuildContext {
  String tr(String key, {Map<String, String>? params}) {
    return AppLocalizations.of(this)?.translate(key, params: params) ?? key;
  }
}
