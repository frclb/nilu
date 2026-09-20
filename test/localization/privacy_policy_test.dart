import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Gizlilik politikasının bütünlüğü.
///
/// Politika bir söz listesi. Bu oturumda üç ayrı yanlış beyan çıktı:
/// olmayan uçtan uca şifreleme, "hiçbir üçüncü tarafla paylaşılmaz"
/// (oysa AdMob, Firebase, RevenueCat ve Apple var) ve tutulmayan bir
/// silme sözü. Bu dosya metnin uygulamayla uyumunu kaynaktan kontrol
/// ediyor.
void main() {
  const languages = ['tr', 'en', 'de', 'es', 'fr', 'pt'];

  /// Ekranda çizilen bölüm sayısı.
  final sectionCount = int.parse(
    RegExp(r'_sectionCount = (\d+)')
        .firstMatch(
          File(
            'lib/presentation/legal/privacy_policy_screen.dart',
          ).readAsStringSync(),
        )!
        .group(1)!,
  );

  Map<String, dynamic> dictionary(String lang) =>
      jsonDecode(File('lib/localization/$lang.json').readAsStringSync())
          as Map<String, dynamic>;

  group('ekran ile sözlük uyuşuyor', () {
    test('çizilen her bölümün metni var', () {
      // Ekran döngüyle çiziyor: eksik bir anahtar, kullanıcıya bölüm
      // başlığı yerine çıplak anahtar adı gösterirdi.
      for (final lang in languages) {
        final keys = dictionary(lang).keys;
        for (var i = 1; i <= sectionCount; i++) {
          expect(
            keys,
            contains('privacy_policy_section${i}_title'),
            reason: '$lang: $i. bölümün başlığı yok',
          );
          expect(
            keys,
            contains('privacy_policy_section${i}_content'),
            reason: '$lang: $i. bölümün metni yok',
          );
        }
      }
    });

    test('çizilmeyen bölüm sözlükte kalmıyor', () {
      // Ekrandan düşmüş ama sözlükte duran bir bölüm, kimsenin okumadığı
      // bir söz olurdu.
      for (final lang in languages) {
        expect(
          dictionary(lang).keys,
          isNot(contains('privacy_policy_section${sectionCount + 1}_title')),
          reason: '$lang: ekranda olmayan bölüm sözlükte duruyor',
        );
      }
    });
  });

  group('uygulamanın gerçekte kullandığı hizmetler anlatılıyor', () {
    // Politika bu hizmetlerden söz etmiyorsa App Store gizlilik
    // etiketleriyle de çelişir.
    const services = {
      'AdMob': 'google_mobile_ads',
      'Firebase': 'firebase_core',
      'RevenueCat': 'purchases_flutter',
      'Apple': 'sign_in_with_apple',
    };

    final pubspec = File('pubspec.yaml').readAsStringSync();

    for (final entry in services.entries) {
      test('${entry.key} politikada geçiyor', () {
        expect(
          pubspec.contains(entry.value),
          isTrue,
          reason: 'kurulum: ${entry.value} artık kullanılmıyor mu?',
        );

        for (final lang in languages) {
          final policy = dictionary(lang).entries
              .where((e) => e.key.startsWith('privacy_policy'))
              .map((e) => e.value)
              .join(' ');

          expect(
            policy,
            contains(entry.key),
            reason: '$lang: ${entry.key} politikada anılmıyor',
          );
        }
      });
    }
  });

  group('bilinen yanlış beyanlar geri gelmedi', () {
    test('üçüncü tarafla hiç paylaşılmadığı iddiası yok', () {
      const claims = {
        'tr': 'hiçbir üçüncü tarafla paylaşılmaz',
        'en': 'not shared with any third party',
        'de': 'mit keinem dritten geteilt',
        'es': 'no se comparten con terceros',
        'fr': 'ne sont partagées avec aucun tiers',
        'pt': 'não são partilhados com terceiros',
      };

      for (final lang in languages) {
        final policy = dictionary(lang).entries
            .where((e) => e.key.startsWith('privacy_policy'))
            .map((e) => e.value.toString().toLowerCase())
            .join(' ');

        expect(
          policy,
          isNot(contains(claims[lang])),
          reason: '$lang: uygulama AdMob, Firebase ve RevenueCat taşıyor',
        );
      }
    });
  });
}
