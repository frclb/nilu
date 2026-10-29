import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/platform/app_platform.dart';

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

  /// Sözlükte bu anahtar var mı?
  bool has(String key) => _localizedStrings.containsKey(key);

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

  /// Platforma göre metin: iOS'ta `<anahtar>_ios` varsa o.
  ///
  /// Yasal metinler sitede iki uygulama için tek politika olarak
  /// yayımlanıyor ve iki mağazayı birlikte anıyor. iOS uygulamasının içinde
  /// başka bir platformun adı (Google Play, Health Connect) geçmemeli: App
  /// Store Kural 2.3.10 bu yüzden reddediyor. iOS sürümü aynı metnin o
  /// adlar çıkarılmış hâli.
  String trPlatform(String key, {Map<String, String>? params}) {
    final ios = '${key}_ios';
    final l = AppLocalizations.of(this);
    final secilen = !AppPlatform.isAndroid && (l?.has(ios) ?? false)
        ? ios
        : key;
    return tr(secilen, params: params);
  }

  /// Etkin dile göre büyük harf. Ekranda görünen her büyük harfli metin
  /// buradan geçmeli; `String.toUpperCase()` değil.
  String upper(String text) =>
      upperFor(AppLocalizations.of(this)?.locale.languageCode, text);
}

/// [languageCode] diline göre büyük harf.
///
/// `String.toUpperCase()` dilden habersiz ve Türkçede yanlış: "i"nin büyüğü
/// "İ", Dart ise "I" yazıyor. "Gizlilik" başlığı "GIZLILIK", "Diğer"
/// "DIĞER", "3 gün gecikti" "3 GÜN GECIKTI" çıkıyordu — Türkçe okuyan için
/// üçü de başka (ya da anlamsız) kelime. "ı"nın büyüğü zaten "I", ona
/// dokunmak gerekmiyor.
String upperFor(String? languageCode, String text) => languageCode == 'tr'
    ? text.replaceAll('i', 'İ').toUpperCase()
    : text.toUpperCase();
