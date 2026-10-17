import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/build_site.dart';

/// GitHub Pages sitesi.
///
/// App Store gizlilik politikasının herkese açık bir adreste olmasını ve
/// uygulamadaki metinle aynı olmasını istiyor. Site uygulamanın sözlüğünden
/// üretiliyor; bu testler üretilen sayfaların gerçekten o metni taşıdığını,
/// kırık bağlantı ve dış kaynak olmadığını sınıyor.
void main() {
  const diller = ['tr', 'en', 'de', 'es', 'fr', 'pt'];

  Map<String, dynamic> sozluk(String dil) =>
      jsonDecode(File('lib/localization/$dil.json').readAsStringSync())
          as Map<String, dynamic>;

  String esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  late Directory cikti;
  late SiteBuilder site;

  setUpAll(() {
    cikti = Directory.systemTemp.createTempSync('site_');
    site = SiteBuilder(Directory.current)..write(cikti);
  });
  tearDownAll(() => cikti.deleteSync(recursive: true));

  String oku(String yol) => File('${cikti.path}/$yol').readAsStringSync();

  test('her dilde dört sayfa var', () {
    for (final d in diller) {
      for (final s in ['', 'privacy/', 'terms/', 'support/']) {
        expect(
          File('${cikti.path}/$d/${s}index.html').existsSync(),
          isTrue,
          reason: '$d/$s',
        );
      }
    }
  });

  for (final d in diller) {
    test('$d: gizlilik ve şartlar uygulamadaki metnin aynısı', () {
      final s = sozluk(d);
      for (final (yol, onek, baslik) in [
        ('privacy', 'privacy_policy_section', 'privacy_policy_title'),
        ('terms', 'terms_section', 'terms_of_service_title'),
      ]) {
        final html = oku('$d/$yol/index.html');
        expect(html, contains('<html lang="$d">'));
        expect(html, contains(esc(s[baslik] as String)));
        var bolum = 0;
        for (var i = 1; s.containsKey('$onek${i}_title'); i++) {
          bolum++;
          expect(html, contains(esc(s['$onek${i}_title'] as String)));
          // İçerik paragraflara bölünüyor ve {email} dolduruluyor; her
          // paragrafın e-postasız parçaları sayfada olmalı.
          final icerik = s['$onek${i}_content'] as String;
          for (final parca in icerik.split(RegExp(r'\n|\{email\}'))) {
            if (parca.trim().isEmpty) continue;
            expect(html, contains(esc(parca.trim())), reason: '$d $onek$i');
          }
        }
        expect(bolum, greaterThan(5), reason: '$d $yol bölüm bulunamadı');
      }
    });
  }

  test('ham yer tutucu ve çeviri anahtarı kalmıyor', () {
    for (final f in cikti.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.html')) continue;
      final html = f.readAsStringSync();
      expect(html, isNot(contains('{email}')), reason: f.path);
      expect(html, isNot(contains('{{')), reason: f.path);
      expect(html, isNot(contains('}}')), reason: f.path);
    }
  });

  test('dış kaynak yok: yazı tipi, betik, analiz', () {
    final dis = RegExp(r'''(src|href)="(https?:)?//''');
    for (final f in cikti.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.html')) continue;
      final html = f.readAsStringSync();
      // hreflang bağlantıları baseUrl ile mutlak olabilir; site henüz
      // adressiz, o yüzden hiçbiri dışarıyı göstermemeli.
      expect(dis.hasMatch(html), isFalse, reason: f.path);
    }
    expect(oku('assets/style.css'), isNot(contains('@import')));
    expect(oku('assets/style.css'), isNot(contains('url(http')));
  });

  test('göreli bağlantıların hepsi var olan bir dosyaya gidiyor', () {
    final link = RegExp(r'''(?:src|href)="([^"#:]+)"''');
    for (final f in cikti.listSync(recursive: true).whereType<File>()) {
      // 404 her derinlikte gösteriliyor; bağlantıları sitenin yolundan
      // (aşağıda ayrıca sınanıyor).
      if (!f.path.endsWith('.html') || f.path.endsWith('404.html')) continue;
      final dir = f.parent.uri;
      for (final m in link.allMatches(f.readAsStringSync())) {
        final hedef = dir.resolve(m.group(1)!);
        final yol = hedef.toFilePath();
        final var_ =
            File(yol).existsSync() ||
            File('${yol}index.html').existsSync() ||
            File('$yol/index.html').existsSync();
        expect(var_, isTrue, reason: '${f.path} → ${m.group(1)}');
      }
    }
  });

  test('destek sayfasında menü yolları uygulamanın etiketleri', () {
    for (final d in diller) {
      final html = oku('$d/support/index.html');
      final s = sozluk(d);
      expect(html, contains(esc(s['privacy_delete_account'] as String)));
      expect(html, contains(esc(s['profile_privacy_security'] as String)));
      expect(html, contains(esc(s['premium_restore_purchases'] as String)));
    }
  });

  group('hesaplar bağlanınca', () {
    late Directory kok;

    setUp(() {
      kok = Directory.systemTemp.createTempSync('site_kok_');
      for (final yol in [
        'site/site.json',
        'site/strings.json',
        for (final d in diller) 'lib/localization/$d.json',
      ]) {
        File('${kok.path}/$yol')
          ..createSync(recursive: true)
          ..writeAsStringSync(File(yol).readAsStringSync());
      }
      for (final f in Directory('site/assets').listSync().whereType<File>()) {
        File('${kok.path}/site/assets/${f.uri.pathSegments.last}')
          ..createSync(recursive: true)
          ..writeAsBytesSync(f.readAsBytesSync());
      }
      File('${kok.path}/lib/core/release_config.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
class ReleaseConfig {
  static const String admobAppIdIos = 'ca-app-pub-1234567890123456~1234567890';
  static const String? supportEmail = 'destek@nilu.app';
}
''');
      final config =
          jsonDecode(File('site/site.json').readAsStringSync())
              as Map<String, dynamic>;
      config['baseUrl'] = 'https://ornek.github.io/nilu';
      File('${kok.path}/site/site.json').writeAsStringSync(jsonEncode(config));
    });
    tearDown(() => kok.deleteSync(recursive: true));

    test('e-posta bağlantı, app-ads.txt ve site haritası üretiliyor', () {
      final b = SiteBuilder(kok);
      final sayfalar = {for (final p in b.pages()) p.path: p.content};
      expect(
        sayfalar['tr/support/index.html'],
        contains('href="mailto:destek@nilu.app"'),
      );
      expect(
        sayfalar['en/privacy/index.html'],
        contains('mailto:destek@nilu.app'),
      );
      expect(
        sayfalar['app-ads.txt'],
        'google.com, pub-1234567890123456, DIRECT, f08c47fec0942fa0\n',
      );
      expect(
        sayfalar['sitemap.xml'],
        contains('<loc>https://ornek.github.io/nilu/pt/privacy/</loc>'),
      );
      // Proje sitesinde 404 bağlantıları depo yolunu içermeli.
      expect(sayfalar['404.html'], contains('href="/nilu/tr/"'));
      expect(
        sayfalar['robots.txt'],
        contains('Sitemap: https://ornek.github.io/nilu/sitemap.xml'),
      );
    });

    test('bugün: hesap yokken app-ads.txt ve site haritası yok', () {
      expect(site.publisherId, isNull);
      expect(File('${cikti.path}/app-ads.txt').existsSync(), isFalse);
      expect(File('${cikti.path}/sitemap.xml').existsSync(), isFalse);
    });
  });
}
