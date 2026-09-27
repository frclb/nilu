import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/core/app_info.dart';
import 'package:period_tracker/localization/supported_locales.dart';

/// Cihazın diline göre hangi dilin seçildiği.
///
/// Flutter, cihazın tercih ettiği diller listesinde eşleşme bulamazsa
/// `supportedLocales`'in **ilk** öğesine düşüyor. Türkçe baştayken
/// İtalyanca bir telefon uygulamayı Türkçe açıyordu.
void main() {
  Locale resolve(List<Locale> device) =>
      basicLocaleListResolution(device, appSupportedLocales);

  test('cihaz dili destekleniyorsa o dil seçilir', () {
    for (final locale in appSupportedLocales) {
      expect(
        resolve([locale]).languageCode,
        locale.languageCode,
        reason: '${locale.languageCode} eşleşmedi',
      );
    }
  });

  test('bölge farkı dili değiştirmiyor', () {
    // Avusturya'daki Almanca telefon, Brezilya'daki Portekizce telefon.
    expect(resolve([const Locale('de', 'AT')]).languageCode, 'de');
    expect(resolve([const Locale('pt', 'BR')]).languageCode, 'pt');
    expect(resolve([const Locale('en', 'GB')]).languageCode, 'en');
  });

  test('desteklenmeyen dil İngilizceye düşer, Türkçeye değil', () {
    for (final kod in ['it', 'ja', 'pl', 'ar', 'zh']) {
      expect(
        resolve([Locale(kod)]).languageCode,
        'en',
        reason: '$kod anlamadığı bir dile düşüyor',
      );
    }
  });

  test('ikinci tercih dili de değerlendirilir', () {
    // Telefonun dili Japonca ama ikinci tercihi Almanca.
    expect(
      resolve([const Locale('ja'), const Locale('de')]).languageCode,
      'de',
    );
  });

  test('her desteklenen dilin sözlük dosyası var', () {
    for (final locale in appSupportedLocales) {
      final file = File('lib/localization/${locale.languageCode}.json');
      expect(file.existsSync(), isTrue, reason: '${file.path} yok');
      expect(
        (jsonDecode(file.readAsStringSync()) as Map).isNotEmpty,
        isTrue,
      );
    }
  });

  test('iOS tarafı aynı dilleri tanıyor', () {
    // Info.plist'teki CFBundleLocalizations eksikse iOS cihazın dil
    // tercihlerini uygulamaya eksik bildiriyor ve seçim yanlış çıkıyor.
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    for (final locale in appSupportedLocales) {
      expect(
        plist.contains('<string>${locale.languageCode}</string>'),
        isTrue,
        reason: '${locale.languageCode} CFBundleLocalizations içinde yok',
      );
      expect(
        Directory('ios/Runner/${locale.languageCode}.lproj').existsSync(),
        isTrue,
        reason: '${locale.languageCode}.lproj klasörü yok',
      );
    }
  });

  test('hukuki metinler uygulamanın adını doğru yazıyor', () {
    // Ad değiştiğinde Şartlar ve Gizlilik Politikası eski adı söylemeye
    // devam ediyordu: "Period Tracker uygulamasını indirerek…". Metinde
    // yanlış ürün adı hem incelemede hem kullanıcıda soru işareti.
    for (final locale in appSupportedLocales) {
      final sozluk =
          jsonDecode(
                File('lib/localization/${locale.languageCode}.json')
                    .readAsStringSync(),
              )
              as Map<String, dynamic>;

      for (final anahtar in [
        'terms_section1_content',
        'terms_section2_content',
        'privacy_policy_section1_content',
      ]) {
        expect(
          sozluk[anahtar],
          contains(AppInfo.displayName),
          reason: '${locale.languageCode}/$anahtar uygulamanın adını anmıyor',
        );
      }
    }
  });
}
