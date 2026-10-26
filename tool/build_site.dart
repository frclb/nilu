// GitHub Pages sitesini üretir.
//
//     dart run tool/build_site.dart            # → build/site/
//     dart run tool/build_site.dart <çıktı>
//
// Gizlilik politikası ve Kullanım Şartları **uygulamanın kendi
// sözlüğünden** (lib/localization/*.json) üretiliyor: App Store yayındaki
// metnin uygulama içindekiyle aynı olmasını istiyor ve ikisi ayrı yazılsaydı
// ilk güncellemede ayrışırdı. Destek sayfasındaki menü yolları da
// uygulamanın etiketlerinden ({{anahtar}}).
//
// Sitenin kendine ait metni site/strings.json'da, adresi site/site.json'da.
// Destek e-postası ve app-ads.txt'nin yayıncı kimliği
// lib/core/release_config.dart'tan.
//
// Site çerez, analiz, harici yazı tipi ya da betik kullanmıyor; tek betik
// kök sayfadaki dil yönlendirmesi.
//
// site/assets/badges'teki rozetler Apple'ın ve Google'ın resmî dosyaları,
// değiştirilmeden kullanılıyor. Apple'ın iki rozetinin lisansı (App Store
// Marketing Artwork, Works with Apple Health) App Store'da yayındaki
// uygulamayla sınırlı: ikisi de ancak site.json'a `appStoreUrl` girilince
// görünüyor. Kurallar ve kaynaklar: SETUP_KEYS.md §8.
import 'dart:convert';
import 'dart:io';

import 'release_values.dart';

/// Üretilen bir sayfanın göreli yolu ve içeriği.
typedef SitePage = ({String path, String content});

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

/// Düz metni paragraflara böler (boş satırlar ayraç).
String _paras(String text) => text
    .split(RegExp(r'\n\s*\n|\n'))
    .where((p) => p.trim().isNotEmpty)
    .map((p) => '<p>$p</p>')
    .join('\n');

class SiteBuilder {
  SiteBuilder(this.root);

  final Directory root;

  late final Map<String, dynamic> config = _json('site/site.json');
  late final Map<String, dynamic> strings = _json('site/strings.json');
  late final String _release = File(
    '${root.path}/lib/core/release_config.dart',
  ).readAsStringSync();

  late final List<String> languages = List<String>.from(
    config['languages'] as List,
  );
  late final String defaultLanguage = config['defaultLanguage'] as String;

  String? get supportEmail => releaseValue(_release, 'supportEmail');

  /// app-ads.txt yayıncı kimliği (`pub-…`); App ID girilmemişse `null`.
  String? get publisherId {
    final appId = releaseValue(_release, 'admobAppIdIos');
    final m = RegExp(r'^ca-app-pub-(\d{16})~').firstMatch(appId ?? '');
    if (m == null || m.group(1) == '3940256099942544') return null;
    return 'pub-${m.group(1)}';
  }

  /// Mağaza sayfaları; uygulama o mağazada henüz yoksa `null`.
  String? get appStoreUrl => config['appStoreUrl'] as String?;
  String? get playStoreUrl => config['playStoreUrl'] as String?;

  String? get baseUrl {
    final b = config['baseUrl'] as String?;
    if (b == null || b.contains('YER_TUTUCU')) return null;
    return b.endsWith('/') ? b.substring(0, b.length - 1) : b;
  }

  final Map<String, Map<String, dynamic>> _dictCache = {};

  Map<String, dynamic> _json(String path) =>
      jsonDecode(File('${root.path}/$path').readAsStringSync())
          as Map<String, dynamic>;

  Map<String, dynamic> dict(String lang) =>
      _dictCache[lang] ??= _json('lib/localization/$lang.json');

  Map<String, dynamic> site(String lang) =>
      strings[lang] as Map<String, dynamic>;

  /// Uygulamanın çevirisi; `{email}` destek adresiyle (ya da dilin yer
  /// tutucusuyla) dolduruluyor.
  String _app(String lang, String key) {
    final value = dict(lang)[key] as String?;
    if (value == null) throw StateError('$lang: "$key" sözlükte yok');
    return value;
  }

  String _emailText(String lang) =>
      supportEmail ?? _app(lang, 'legal_email_placeholder');

  /// Metindeki `{email}`'i bağlantıya, `{{anahtar}}`'ı uygulamanın
  /// etiketine çevirir; geri kalanını kaçışlar.
  String _render(String lang, String text) {
    final escaped = _esc(text);
    final email = supportEmail;
    final emailHtml = email == null
        ? _esc(_emailText(lang))
        : '<a href="mailto:${_esc(email)}">${_esc(email)}</a>';
    return escaped
        .replaceAllMapped(
          RegExp(r'\{\{([a-z0-9_]+)\}\}'),
          (m) => '<strong>${_esc(_app(lang, m.group(1)!))}</strong>',
        )
        .replaceAll('{email}', emailHtml);
  }

  /// Sözlükte `<önek>N_title` / `<önek>N_content` olarak duran bölümler.
  List<(String, String)> _sections(String lang, String prefix) {
    final d = dict(lang);
    final out = <(String, String)>[];
    for (var i = 1; d.containsKey('$prefix${i}_title'); i++) {
      out.add((
        d['$prefix${i}_title'] as String,
        d['$prefix${i}_content'] as String,
      ));
    }
    return out;
  }

  String _layout({
    required String lang,
    required String section,
    required String title,
    required String body,
    required int depth,
  }) {
    final s = site(lang);
    final up = '../' * depth;
    final rel = section == 'home' ? '' : '$section/';
    String alt(String l) {
      final b = baseUrl;
      return b == null ? '$up$l/$rel' : '$b/$l/$rel';
    }

    final nav = [
      ('home', s['nav_home'], ''),
      ('privacy', s['nav_privacy'], 'privacy/'),
      ('terms', s['nav_terms'], 'terms/'),
      ('support', s['nav_support'], 'support/'),
    ];
    String navLinks() => nav
        .map(
          (n) =>
              '<a href="$up$lang/${n.$3}"'
              '${n.$1 == section ? ' aria-current="page"' : ''}>'
              '${_esc(n.$2 as String)}</a>',
        )
        .join();
    final langs = languages
        .map(
          (l) =>
              '<a href="$up$l/$rel" hreflang="$l" lang="$l"'
              '${l == lang ? ' aria-current="true"' : ''}>'
              '${_esc(site(l)['lang_name'] as String)}</a>',
        )
        .join();
    final hreflang = languages
        .map((l) => '<link rel="alternate" hreflang="$l" href="${alt(l)}">')
        .join('\n');

    return '''<!doctype html>
<html lang="$lang">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_esc(title)}</title>
<meta name="description" content="${_esc(s['hero_body'] as String)}">
<link rel="stylesheet" href="${up}assets/style.css">
<link rel="icon" type="image/png" href="${up}assets/favicon.png">
<link rel="apple-touch-icon" href="${up}assets/apple-touch-icon.png">
$hreflang
</head>
<body>
<a class="skip" href="#icerik">${_esc(title)}</a>
<header class="site"><div class="wrap">
<a class="brand" href="$up$lang/"><img src="${up}assets/icon-256.png" alt="" width="36" height="36"><span>Nilu</span></a>
<nav class="main" aria-label="${_esc(s['nav_home'] as String)}">${navLinks()}</nav>
</div></header>
<main id="icerik"><div class="wrap">
$body
</div></main>
<footer class="site"><div class="wrap">
<div class="links">${navLinks()}</div>
<div class="langs" aria-label="${_esc(s['language'] as String)}">$langs</div>
<p>${_esc(s['footer_tracking'] as String)}</p>
<p>© ${DateTime.now().year} Nilu</p>
</div></footer>
</body>
</html>
''';
  }

  /// Resmî mağaza rozeti; [file] site/assets/badges altında.
  String _badge(String url, String file, String alt) =>
      '<a href="${_esc(url)}"><img src="../assets/badges/$file" '
      'alt="${_esc(alt)}" height="48"></a>';

  String _home(String lang) {
    final s = site(lang);
    String t(String key) => _esc(s[key] as String);
    final apple = appStoreUrl;
    final play = playStoreUrl;
    // Apple: App Store rozeti sırada ilk ve diğer rozet varken siyah olanı.
    // Google: Google Play rozeti ötekilerle aynı boyda ya da büyük.
    final badges = [
      if (apple != null)
        _badge(apple, 'app-store-$lang.svg', s['badge_app_store'] as String),
      if (play != null)
        _badge(play, 'google-play-$lang.svg', s['badge_google_play'] as String),
    ];
    final cta = badges.isEmpty
        ? '<div class="cta"><span>${t('coming_soon')}</span></div>'
        : '<div class="badges">${badges.join()}</div>';
    // Apple'ın kuralı: rozet ana mesajdan sonra ve ondan küçük, yanında
    // Sağlık'ın faydası ve gizlilik cümlesi. Rozet çevrilmiyor.
    final health = apple == null
        ? ''
        : '''
<section class="card"><h2>${t('health_title')}</h2>
<p>${t('health_body')}</p>
<p class="note">${t('health_privacy')}</p>
<img class="health-badge" src="../assets/badges/apple-health.svg" alt="Works with Apple Health" height="40">
</section>''';
    // Rozetlerdeki markaların sahip satırları (ikisinin de kuralı istiyor).
    final credits = [
      if (apple != null) 'trademarks_apple',
      if (play != null) 'trademarks_google',
    ].map((k) => '\n<p class="note legal">${t(k)}</p>').join();
    String list(String key) =>
        (s[key] as List).map((e) => '<li>${_esc(e as String)}</li>').join('\n');
    return _layout(
      lang: lang,
      section: 'home',
      title: 'Nilu — ${s['hero_title']}',
      depth: 1,
      body:
          '''
<section class="hero">
<img src="../assets/icon-256.png" alt="Nilu" width="112" height="112">
<h1>${t('hero_title')}</h1>
<p>${t('hero_body')}</p>
$cta
</section>
<section class="card"><h2>${t('features_title')}</h2><ul>
${list('features')}
</ul></section>$health
<section class="card"><h2>${t('privacy_title')}</h2><ul>
${list('privacy_points')}
</ul></section>
<p class="note">${t('medical')}</p>$credits''',
    );
  }

  String _legal(
    String lang, {
    required String section,
    required String titleKey,
    required String updatedKey,
    required String prefix,
  }) {
    final title = _app(lang, titleKey);
    final body = StringBuffer()
      ..writeln('<article>')
      ..writeln('<h1>${_esc(title)}</h1>')
      ..writeln('<p class="updated">${_esc(_app(lang, updatedKey))}</p>');
    for (final (t, c) in _sections(lang, prefix)) {
      body
        ..writeln('<h2>${_esc(t)}</h2>')
        ..writeln(_paras(_render(lang, c)));
    }
    body.writeln('</article>');
    return _layout(
      lang: lang,
      section: section,
      title: '$title — Nilu',
      depth: 2,
      body: body.toString(),
    );
  }

  String _support(String lang) {
    final s = site(lang);
    final faq = (s['faq'] as List)
        .cast<Map<String, dynamic>>()
        .map(
          // `id`: dışarıdan bağlantı verilen sorular (Google Play hesap
          // silme sayfası olarak #delete-account'u istiyor).
          (f) =>
              '<details${f['id'] == null ? '' : ' id="${_esc(f['id'] as String)}"'}>'
              '<summary>${_esc(f['q'] as String)}</summary>'
              '<p>${_render(lang, f['a'] as String)}</p></details>',
        )
        .join('\n');
    return _layout(
      lang: lang,
      section: 'support',
      title: '${s['support_title']} — Nilu',
      depth: 2,
      body:
          '''
<article>
<h1>${_esc(s['support_title'] as String)}</h1>
<p>${_esc(s['support_intro'] as String)}</p>
<p>${_render(lang, s['support_contact'] as String)}</p>
<h2>${_esc(s['faq_title'] as String)}</h2>
$faq
<p class="note">${_esc(s['medical'] as String)}</p>
</article>''',
    );
  }

  /// Kök sayfa: tarayıcının diline yönlendirir; betik yoksa liste.
  String _root() {
    final list = languages
        .map(
          (l) =>
              '<li><a href="$l/" hreflang="$l" lang="$l">'
              '${_esc(site(l)['lang_name'] as String)}</a></li>',
        )
        .join('\n');
    final codes = jsonEncode(languages);
    return '''<!doctype html>
<html lang="$defaultLanguage">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Nilu</title>
<link rel="stylesheet" href="assets/style.css">
<link rel="icon" type="image/png" href="assets/favicon.png">
<script>
(function () {
  var codes = $codes;
  var prefs = navigator.languages || [navigator.language || ''];
  for (var i = 0; i < prefs.length; i++) {
    var c = (prefs[i] || '').slice(0, 2).toLowerCase();
    if (codes.indexOf(c) >= 0) { location.replace(c + '/'); return; }
  }
  location.replace('$defaultLanguage/');
})();
</script>
</head>
<body>
<main><div class="wrap" style="text-align:center">
<img src="assets/icon-256.png" alt="Nilu" width="112" height="112" style="border-radius:26px;margin-top:32px">
<ul class="langs-list">
$list
</ul>
</div></main>
</body>
</html>
''';
  }

  /// 404 sayfası her derinlikte gösteriliyor; göreli bağlantı işe
  /// yaramıyor. Bağlantılar sitenin adresinin yolundan (proje sitesinde
  /// `/nilu/`) kuruluyor. Adres girilmemişse kök varsayılıyor.
  String _notFound() {
    final yol = baseUrl == null ? '/' : '${Uri.parse(baseUrl!).path}/';
    final list = languages
        .map(
          (l) =>
              '<li><a href="$yol$l/" hreflang="$l" lang="$l">'
              '${_esc(site(l)['lang_name'] as String)}</a></li>',
        )
        .join('\n');
    return '''<!doctype html>
<html lang="$defaultLanguage">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Nilu — 404</title></head>
<body style="font-family:-apple-system,sans-serif;text-align:center;padding:48px 16px">
<h1>404</h1>
<ul style="list-style:none;padding:0">
$list
</ul>
</body>
</html>
''';
  }

  /// Bütün sayfalar.
  List<SitePage> pages() {
    final out = <SitePage>[
      (path: 'index.html', content: _root()),
      (path: '404.html', content: _notFound()),
      (path: '.nojekyll', content: ''),
    ];
    for (final lang in languages) {
      out
        ..add((path: '$lang/index.html', content: _home(lang)))
        ..add((
          path: '$lang/privacy/index.html',
          content: _legal(
            lang,
            section: 'privacy',
            titleKey: 'privacy_policy_title',
            updatedKey: 'privacy_policy_last_updated',
            prefix: 'privacy_policy_section',
          ),
        ))
        ..add((
          path: '$lang/terms/index.html',
          content: _legal(
            lang,
            section: 'terms',
            titleKey: 'terms_of_service_title',
            updatedKey: 'terms_last_updated',
            prefix: 'terms_section',
          ),
        ))
        ..add((path: '$lang/support/index.html', content: _support(lang)));
    }

    final pub = publisherId;
    if (pub != null) {
      // Google'ın doğrulama kimliği sabit (f08c47fec0942fa0).
      out.add((
        path: 'app-ads.txt',
        content: 'google.com, $pub, DIRECT, f08c47fec0942fa0\n',
      ));
    }

    final b = baseUrl;
    out.add((
      path: 'robots.txt',
      content:
          'User-agent: *\nAllow: /\n'
          '${b == null ? '' : 'Sitemap: $b/sitemap.xml\n'}',
    ));
    if (b != null) {
      final urls = [
        for (final lang in languages)
          for (final p in ['', 'privacy/', 'terms/', 'support/'])
            '<url><loc>$b/$lang/$p</loc></url>',
      ].join('\n');
      out.add((
        path: 'sitemap.xml',
        content:
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
            '$urls\n</urlset>\n',
      ));
    }
    return out;
  }

  /// Sayfaları ve site/assets'i [out]'a yazar.
  void write(Directory out) {
    if (out.existsSync()) out.deleteSync(recursive: true);
    for (final p in pages()) {
      File('${out.path}/${p.path}')
        ..createSync(recursive: true)
        ..writeAsStringSync(p.content);
    }
    final assets = Directory('${root.path}/site/assets');
    for (final f in assets.listSync(recursive: true).whereType<File>()) {
      final rel = f.path.substring(assets.path.length + 1);
      final hedef = File('${out.path}/assets/$rel')
        ..parent.createSync(recursive: true);
      f.copySync(hedef.path);
    }
  }
}

void main(List<String> args) {
  final out = Directory(args.isNotEmpty ? args.first : 'build/site');
  final builder = SiteBuilder(Directory.current);
  builder.write(out);
  stdout.writeln(
    'Site üretildi: ${out.path} '
    '(${builder.pages().length} dosya, ${builder.languages.length} dil)',
  );
  if (builder.supportEmail == null) {
    stdout.writeln(
      '  ! Destek e-postası yok: sayfalarda yer tutucu görünüyor.',
    );
  }
  if (builder.publisherId == null) {
    stdout.writeln('  ! AdMob App ID yok: app-ads.txt üretilmedi.');
  }
  if (builder.baseUrl == null) {
    stdout.writeln('  ! site/site.json → baseUrl yok: sitemap üretilmedi.');
  }
}
