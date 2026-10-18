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
  int sectionCount(String screen) => int.parse(
    RegExp(r'_sectionCount = (\d+)')
        .firstMatch(
          File('lib/presentation/legal/$screen.dart').readAsStringSync(),
        )!
        .group(1)!,
  );

  Map<String, dynamic> dictionary(String lang) =>
      jsonDecode(File('lib/localization/$lang.json').readAsStringSync())
          as Map<String, dynamic>;

  /// Hukuki ekranlar: dosya adı → anahtar öneki.
  const screens = {
    'privacy_policy_screen': 'privacy_policy_section',
    'terms_of_service_screen': 'terms_section',
  };

  group('ekran ile sözlük uyuşuyor', () {
    test('çizilen her bölümün metni var', () {
      // Ekran döngüyle çiziyor: eksik bir anahtar, kullanıcıya bölüm
      // başlığı yerine çıplak anahtar adı gösterirdi.
      for (final entry in screens.entries) {
        final count = sectionCount(entry.key);
        for (final lang in languages) {
          final keys = dictionary(lang).keys;
          for (var i = 1; i <= count; i++) {
            expect(
              keys,
              contains('${entry.value}${i}_title'),
              reason: '$lang · ${entry.key}: $i. bölümün başlığı yok',
            );
            expect(
              keys,
              contains('${entry.value}${i}_content'),
              reason: '$lang · ${entry.key}: $i. bölümün metni yok',
            );
          }
        }
      }
    });

    test('çizilmeyen bölüm sözlükte kalmıyor', () {
      // Ekrandan düşmüş ama sözlükte duran bir bölüm, kimsenin okumadığı
      // bir söz olurdu.
      for (final entry in screens.entries) {
        final beyond = sectionCount(entry.key) + 1;
        for (final lang in languages) {
          expect(
            dictionary(lang).keys,
            isNot(contains('${entry.value}${beyond}_title')),
            reason: '$lang · ${entry.key}: ekranda olmayan bölüm sözlükte',
          );
        }
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
    test(
      'Apple ve Google ile giriş anlatılıyorsa uygulamada gerçekten var',
      () {
        // Bir kez olmayan bir giriş yöntemi anlatılmıştı: paket, yetki ve
        // yöntem vardı ama hiçbir yerden çağrılmıyordu. Şimdi giriş Firebase'in
        // kendi akışıyla yapılıyor; politika onu anlatıyorsa kod da onu
        // yapıyor olmalı.
        final giris = File(
          'lib/data/datasources/remote/account_auth.dart',
        ).readAsStringSync();
        expect(giris, contains('AppleAuthProvider'));
        expect(giris, contains('GoogleAuthProvider'));
        expect(
          File('ios/Runner/Runner.entitlements').readAsStringSync(),
          contains('com.apple.developer.applesignin'),
        );
        expect(
          File('lib/core/navigation/app_router.dart').readAsStringSync(),
          contains('AccountScreen'),
          reason: 'Giriş ekranına bir yoldan ulaşılabilmeli',
        );
        // Ayrı bir giriş paketi yok; ölü kod olarak geri gelmesin.
        expect(
          File('pubspec.yaml').readAsStringSync(),
          isNot(contains('sign_in_with_apple')),
        );
        for (final lang in languages) {
          final hesap = dictionary(lang).entries
              .where((e) => e.key.startsWith('privacy_policy_section4'))
              .map((e) => e.value)
              .join(' ');
          expect(hesap, contains('Apple'), reason: lang);
          expect(hesap, contains('Google'), reason: lang);
          expect(hesap, contains('Firebase Authentication'), reason: lang);
        }
      },
    );

    test('üçüncü tarafla hiç paylaşılmadığı iddiası yok', () {
      const claims = {
        'tr': 'hiçbir üçüncü tarafla paylaşılmaz',
        'en': 'not shared with any third party',
        'de': 'mit keinem dritten geteilt',
        'es': 'no se comparten con terceros',
        'fr': 'ne sont partagées avec aucun tiers',
        'pt': 'não são compartilhados com terceiros',
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

  group('bulut eşitleme dürüstçe anlatılıyor', () {
    // Sağlık verisi sunucuya ancak açık rızayla gidiyor ve kopya uçtan uca
    // şifreli değil. Politika bunu yazmazsa "verilerim telefonumda" sanan
    // kullanıcı yanılır; rızanın dayanağı da bu bilgilendirme.
    const riza = {
      'tr': 'açık rıza',
      'en': 'explicit consent',
      'de': 'ausdrücklich',
      'es': 'consentimiento explícito',
      'fr': 'consentement explicite',
      'pt': 'consentimento explícito',
    };
    const uctanUca = {
      'tr': 'uçtan uca',
      'en': 'end-to-end',
      'de': 'Ende-zu-Ende',
      'es': 'extremo a extremo',
      'fr': 'bout en bout',
      'pt': 'ponta a ponta',
    };

    for (final lang in languages) {
      test('$lang: rıza, saklama yeri, şifreleme sınırı ve silme', () {
        final d = dictionary(lang);
        final hesap = d['privacy_policy_section4_content'] as String;
        expect(hesap, contains(riza[lang]));
        expect(hesap, contains('Cloud Firestore'));
        expect(hesap, contains(uctanUca[lang]));
        // Üçüncü taraflar bölümü Firestore'u da sayıyor.
        expect(
          d['privacy_policy_section6_content'],
          contains('Cloud Firestore'),
        );
        // Saklama bölümü bulut kopyasının ne zaman silindiğini söylüyor.
        expect(d['privacy_policy_section9_content'], contains('Apple'));
        // Uygulamadaki rıza metni de aynı sınırı söylüyor.
        expect(d['sync_consent_where'], contains(uctanUca[lang]));
      });
    }
  });

  group('saklanan veri türleri metinde anlatılıyor', () {
    // Uygulama gebelik kaydı (sonuç dahil — düşük, sonlandırma), randevu
    // notları ve tansiyon saklıyor. Politika yalnızca döngü verisini
    // sayarsa kullanıcı en hassas verisinin nerede durduğunu bilemez.
    const gebelik = {
      'tr': 'gebelik',
      'en': 'pregnancy',
      'de': 'schwangerschaft',
      'es': 'embarazo',
      'fr': 'grossesse',
      'pt': 'gravidez',
    };
    const tansiyon = {
      'tr': 'tansiyon',
      'en': 'blood pressure',
      'de': 'blutdruck',
      'es': 'tensión',
      'fr': 'tension',
      'pt': 'pressão',
    };

    String metin(String lang, String onek) => dictionary(lang).entries
        .where((e) => e.key.startsWith(onek))
        .map((e) => e.value.toString().toLowerCase())
        .join(' ');

    test('uygulama gebelik verisini şifreli depoda tutuyor', () {
      // Aşağıdaki iddiaların dayanağı: veri gerçekten saklanıyor.
      final depo = File('lib/data/local/secure_store.dart').readAsStringSync();
      expect(depo, contains("'pregnancies'"));
      expect(depo, contains("'care_events'"));
    });

    for (final lang in languages) {
      test('$lang: politika gebelik verisini ve tansiyonu anlatıyor', () {
        final p = metin(lang, 'privacy_policy_section1');
        expect(p, contains(gebelik[lang]));
        expect(p, contains(tansiyon[lang]));
        // Partnere ve üçüncü taraflara gitmediği de yazılı.
        expect(metin(lang, 'privacy_policy_section3'), contains(gebelik[lang]));
        expect(metin(lang, 'privacy_policy_section6'), contains(gebelik[lang]));
      });

      test('$lang: şartlar gebelik takibinin hekim izleminin yerine '
          'geçmediğini söylüyor', () {
        expect(metin(lang, 'terms_section2'), contains(gebelik[lang]));
      });
    }
  });
}
