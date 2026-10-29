import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/core/platform/app_platform.dart';
import 'package:period_tracker/presentation/legal/privacy_policy_screen.dart';
import 'package:period_tracker/presentation/legal/terms_of_service_screen.dart';

import '../presentation/screen_harness.dart';

/// iOS uygulamasında başka bir platformun adı geçiyor mu?
///
/// App Store Kural 2.3.10: uygulamada ve mağaza metinlerinde başka mobil
/// platformların adı (Google Play, Android…) olmamalı. Başka bir projede iOS
/// sürümü yalnızca uygulama içinde "Google Play" kaldığı için reddedildi.
/// Bu uygulamada aynı sözlük iki platforma da hizmet ediyor; Android'e özel
/// metinler ya `_android` sonekiyle ya `health_connect_` önekiyle ayrılıyor
/// ya da iOS'ta `_ios` sürümüyle değiştiriliyor (`trPlatform`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(mockMissingPlatformChannels);

  final yasak = RegExp(
    r'Google Play|Play Store|Android|Health Connect|Google Fit',
  );
  const diller = ['tr', 'en', 'de', 'es', 'fr', 'pt'];

  Map<String, String> sozluk(String dil) =>
      (jsonDecode(File('lib/localization/$dil.json').readAsStringSync())
              as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, '$v'));

  test('başka platform adı geçen her metnin iOS karşılığı var', () {
    for (final dil in diller) {
      final d = sozluk(dil);
      final kacak = <String>[
        for (final MapEntry(:key, :value) in d.entries)
          if (yasak.hasMatch(value) &&
              !key.endsWith('_android') &&
              !key.startsWith('health_connect_') &&
              !d.containsKey('${key}_ios'))
            key,
      ];
      expect(
        kacak,
        isEmpty,
        reason:
            '$dil: bu metinler iOS uygulamasında da görünür. Android\'e özelse '
            '`_android` soneki ve AppPlatform.isAndroid ile seç; ortak bir '
            'metinse iOS için `<anahtar>_ios` sürümü ekleyip trPlatform ile '
            'oku.',
      );
      for (final MapEntry(:key, :value) in d.entries) {
        if (key.endsWith('_ios')) {
          expect(yasak.hasMatch(value), isFalse, reason: '$dil: $key');
        }
      }
    }
  });

  // Ekranın kendisi: iOS'ta (testler masaüstünde, AppPlatform Android değil)
  // politika ve şartlarda o adlar görünmüyor.
  for (final dil in diller) {
    for (final (ad, ekran) in [
      ('gizlilik', const PrivacyPolicyScreen()),
      ('şartlar', const TermsOfServiceScreen()),
    ]) {
      testWidgets('$dil: iOS\'ta $ad metninde başka platform yok', (
        tester,
      ) async {
        expect(AppPlatform.isAndroid, isFalse);
        await pumpScreen(
          tester,
          ekran,
          size: const Size(390, 844),
          locale: Locale(dil),
        );
        final metinler = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
            .join('\n');
        expect(metinler.length, greaterThan(2000), reason: 'ekran çizilmedi');
        expect(yasak.hasMatch(metinler), isFalse);
      });
    }
  }
}
