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

  test('hesap silme sorusunun sabit bir bağlantısı var', () {
    // Google Play, hesap açılabilen uygulamalardan uygulama dışında bir
    // silme sayfası istiyor; Play Console'a .../support/#delete-account
    // giriliyor.
    for (final d in diller) {
      final html = File(
        '${cikti.path}/$d/support/index.html',
      ).readAsStringSync();
      expect(html, contains('<details id="delete-account">'), reason: d);
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
    final dis = RegExp(r'''(src|href)="((?:https?:)?//[^"]*)"''');
    for (final f in cikti.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.html')) continue;
      final html = f.readAsStringSync();
      // hreflang ve canonical bağlantıları baseUrl ile mutlak; onlar sitenin
      // kendisi. Mağaza rozetleri bugün yok (bkz. "bugün" testi).
      final disarisi = dis
          .allMatches(html)
          .map((m) => m[2]!)
          .where((u) => !u.startsWith('${site.baseUrl}/'));
      expect(disarisi, isEmpty, reason: f.path);
    }
    expect(oku('assets/style.css'), isNot(contains('@import')));
    expect(oku('assets/style.css'), isNot(contains('url(http')));
  });

  test('bugün: mağaza bağlantısı yokken rozet yok, "Yakında" var', () {
    final yazilar =
        jsonDecode(File('site/strings.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final d in diller) {
      final html = oku('$d/index.html');
      final s = yazilar[d] as Map<String, dynamic>;
      expect(html, contains(esc(s['coming_soon'] as String)), reason: d);
      expect(html, isNot(contains('assets/badges/')), reason: d);
    }
  });

  test('her dilin resmî mağaza rozetleri sitede', () {
    // Rozetler dile göre: Apple ve Google kendi çevirisini veriyor,
    // rozet yazısı elle çevrilmiyor. Sağlık rozetinin yalnız İngilizcesi var.
    for (final d in diller) {
      for (final ad in ['app-store-$d.svg', 'google-play-$d.svg']) {
        final svg = oku('assets/badges/$ad');
        expect(svg, contains('<svg'), reason: ad);
        expect(svg, isNot(contains('<script')), reason: ad);
      }
    }
    expect(oku('assets/badges/apple-health.svg'), contains('<svg'));
  });

  test('tanıtım sayfası: ekranlar, açıklamaları, bağlantı önizlemesi', () {
    final yazilar =
        jsonDecode(File('site/strings.json').readAsStringSync())
            as Map<String, dynamic>;
    for (final d in diller) {
      final html = oku('$d/index.html');
      final s = yazilar[d] as Map<String, dynamic>;
      for (final r in (s['showcase'] as List).cast<Map<String, dynamic>>()) {
        expect(
          html,
          contains(
            'src="../assets/screens/$d/${r['id']}.webp" '
            'alt="${esc(r['alt'] as String)}"',
          ),
          reason: '$d ${r['id']}',
        );
      }
      // `*…*` vurguya dönüşüyor; işaret sayfaya ham düşmüyor.
      expect(html, contains('<h1>'), reason: d);
      expect(RegExp(r'<h1>[^<]*<em>').hasMatch(html), isTrue, reason: d);
      expect(html, isNot(contains('<title>Nilu — *')), reason: d);
      expect(
        html,
        contains(
          '<meta property="og:image" content="${site.baseUrl}/assets/og/$d.jpg">',
        ),
      );
      expect(File('${cikti.path}/assets/og/$d.jpg').existsSync(), isTrue);
    }
    // Apple Sağlık simgesinin lisansı uygulamanın içiyle sınırlı: o ekranın
    // görüntüsü sitede yok.
    final ekranlar = Directory(
      'site/assets/screens',
    ).listSync(recursive: true).map((f) => f.path);
    expect(ekranlar.where((p) => p.contains('health_sync')), isEmpty);
  });

  // Partner davet bağlantısı (…/p/#KOD) uygulama yüklü değilken bu
  // sayfayı açıyor. Kod `#`'ten sonra: sayfa onu yalnızca betikte okuyor.
  test('davet sayfası: altı dil, uygulamayı açan düğme, dizine girmiyor', () {
    final html = oku('p/index.html');
    expect(html, contains("'nilu://p#' + kod"));
    expect(html, contains('<meta name="robots" content="noindex">'));
    expect(html, contains('<meta name="referrer" content="no-referrer">'));
    for (final d in diller) {
      expect(html, contains('"$d": {'), reason: d);
    }
    // Menü yolu uygulamanın etiketlerinden; ham anahtar kalmıyor.
    expect(html, contains('Partner Olarak Giriş Yap'));
    expect(html, isNot(contains('{{')));
  });

  // E-posta doğrulama ve şifre yenileme bağlantıları (Firebase'in "action
  // URL"i) uygulama yüklü değilken ya da başka cihazda bu sayfayı açıyor.
  test(
    'doğrulama sayfası: altı dil, işlemi kendisi bitiriyor, dizine girmiyor',
    () {
      final html = oku('auth/index.html');
      expect(html, contains('<meta name="robots" content="noindex">'));
      expect(html, contains('<meta name="referrer" content="no-referrer">'));
      // Yalnızca Firebase'in kimlik arayüzüne istek; başka adres yok.
      expect(
        html,
        contains("'https://identitytoolkit.googleapis.com/v1/accounts:'"),
      );
      expect(html, contains("istek('update', { oobCode: kod })"));
      expect(html, contains("newPassword: sifre"));
      expect(html, contains("'nilu://auth?mode=verified'"));
      expect(html, contains("'nilu://auth?mode=resetPassword&oobCode='"));
      // Şifre en az 8 karakter: uygulamadaki sınırla aynı.
      expect(html, contains('sifre.length < 8'));
      for (final d in diller) {
        expect(html, contains('"$d": {'), reason: d);
      }
      expect(html, isNot(contains('{{')));
      // E-posta yalnızca metin olarak yazılıyor.
      expect(html, isNot(contains('innerHTML')));
    },
  );

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
      for (final f in Directory(
        'site/assets',
      ).listSync(recursive: true).whereType<File>()) {
        File('${kok.path}/${f.path}')
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

    /// site.json'a mağaza bağlantılarını yazıp ana sayfaları üretir.
    Map<String, String> magazayla({String? apple, String? play}) {
      final yol = File('${kok.path}/site/site.json');
      final config = jsonDecode(yol.readAsStringSync()) as Map<String, dynamic>;
      config['appStoreUrl'] = apple;
      config['playStoreUrl'] = play;
      yol.writeAsStringSync(jsonEncode(config));
      return {for (final p in SiteBuilder(kok).pages()) p.path: p.content};
    }

    const apple = 'https://apps.apple.com/app/id1234567890';
    const play =
        'https://play.google.com/store/apps/details?id=com.furkan.rcperiodtracker';

    test(
      'iki mağaza da varsa: resmî rozetler, Sağlık kartı, marka satırları',
      () {
        final sayfalar = magazayla(apple: apple, play: play);
        final yazilar =
            jsonDecode(File('site/strings.json').readAsStringSync())
                as Map<String, dynamic>;
        for (final d in diller) {
          final html = sayfalar['$d/index.html']!;
          final s = yazilar[d] as Map<String, dynamic>;
          final appStore = html.indexOf(
            '<a href="$apple"><img src="../assets/badges/app-store-$d.svg" '
            'alt="${esc(s['badge_app_store'] as String)}"',
          );
          final googlePlay = html.indexOf(
            '<a href="${esc(play)}"><img src="../assets/badges/google-play-$d.svg" '
            'alt="${esc(s['badge_google_play'] as String)}"',
          );
          // Apple'ın kuralı: App Store rozeti sırada ilk.
          expect(appStore, isNonNegative, reason: d);
          expect(googlePlay, greaterThan(appStore), reason: d);
          expect(html, isNot(contains(esc(s['coming_soon'] as String))));

          // Rozet çevrilmiyor; ana mesajdan (başlık) sonra geliyor.
          final rozet = html.indexOf('alt="Works with Apple Health"');
          expect(
            rozet,
            greaterThan(html.indexOf(esc(s['health_title'] as String))),
          );
          expect(html, contains(esc(s['health_privacy'] as String)));
          expect(html, contains(esc(s['trademarks_apple'] as String)));
          expect(html, contains(esc(s['trademarks_google'] as String)));
        }
      },
    );

    test('yalnız Google Play varsa Apple rozetleri ve satırı yok', () {
      // Apple Developer Program üyeliği gecikirse Android önce çıkabilir;
      // Apple'ın iki rozetinin lisansı App Store'daki uygulamaya bağlı.
      final html = magazayla(play: play)['tr/index.html']!;
      expect(html, contains('assets/badges/google-play-tr.svg'));
      expect(html, isNot(contains('app-store-')));
      expect(html, isNot(contains('apple-health.svg')));
      expect(html, isNot(contains('Apple Inc.')));
      expect(html, contains('Google LLC'));
    });

    test('bugün: AdMob bağlı, app-ads.txt ve site haritası var', () {
      expect(site.publisherId, 'pub-1004252412866238');
      expect(
        oku('app-ads.txt'),
        'google.com, pub-1004252412866238, DIRECT, f08c47fec0942fa0\n',
      );
      expect(site.baseUrl, 'https://frclb.github.io/nilu');
      expect(
        oku('sitemap.xml'),
        contains('<loc>https://frclb.github.io/nilu/tr/privacy/</loc>'),
      );
    });
  });
}
