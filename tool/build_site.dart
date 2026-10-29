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
// lib/core/release_config.dart'tan. Metinlerde `*…*` arası vurgulu
// (başlıklarda degrade), mağaza görsellerindeki gibi.
//
// Ana sayfa bir tanıtım sayfası: uygulamanın gerçek ekranları, mağaza
// görselleriyle aynı çerçeve ve şerit. Ekranlar, zemin, bağlantı önizlemesi
// ve yazı tipleri tool/site_assets.py ile site/assets'e üretiliyor.
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

/// "Döngün *sende* kalır" → vurgulu kısım `<em>`; kaçışlı.
String _marked(String s) => _esc(
  s,
).replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => '<em>${m.group(1)}</em>');

/// Vurgu işaretsiz metin: sayfa başlığı ve açıklamalar için.
String _plain(String s) => s.replaceAll('*', '');

/// Bağlantı önizlemesinin (Open Graph) yerel adı.
const _ogLocales = {
  'tr': 'tr_TR',
  'en': 'en_US',
  'de': 'de_DE',
  'es': 'es_ES',
  'fr': 'fr_FR',
  'pt': 'pt_BR',
};

/// Satır içi simgeler: 24×24, `currentColor` çizgi. Site dışarıdan simge
/// kitaplığı yüklemiyor.
const _icons = {
  'account':
      '<circle cx="12" cy="8" r="3.5"/>'
      '<path d="M5 20c.8-3.4 3.6-5.5 7-5.5s6.2 2.1 7 5.5M4 4l16 16"/>',
  'shield':
      '<path d="M12 3l7 3v5c0 4.6-3 8.3-7 10-4-1.7-7-5.4-7-10V6z"/>'
      '<path d="M9 12l2 2 4-4"/>',
  'lock':
      '<rect x="5" y="11" width="14" height="10" rx="2.5"/>'
      '<path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  'widget':
      '<rect x="4" y="4" width="7" height="7" rx="2"/>'
      '<rect x="13" y="4" width="7" height="7" rx="2"/>'
      '<rect x="4" y="13" width="16" height="7" rx="2"/>',
  'library':
      '<path d="M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3z"/>'
      '<path d="M5 17a3 3 0 0 1 3-3h11M9 8h6"/>',
  'partner':
      '<path d="M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"/>',
  'backup':
      '<path d="M7 18a4 4 0 0 1-.6-8A5.5 5.5 0 0 1 17 8.5a4.5 4.5 0 0 1 .5 9.5"/>'
      '<path d="M12 12v8M9 15l3-3 3 3"/>',
  'check': '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  'down': '<path d="M12 5v14M6 13l6 6 6-6"/>',
  'right': '<path d="M5 12h14M13 6l6 6-6 6"/>',
  'globe':
      '<circle cx="12" cy="12" r="9"/>'
      '<path d="M3 12h18M12 3c2.5 2.5 3.8 5.5 3.8 9s-1.3 6.5-3.8 9'
      'c-2.5-2.5-3.8-5.5-3.8-9S9.5 5.5 12 3z"/>',
};

String _icon(String name) =>
    '<svg class="icon" viewBox="0 0 24 24" aria-hidden="true">'
    '${_icons[name]}</svg>';

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
    final b = baseUrl;
    String alt(String l) => b == null ? '$up$l/$rel' : '$b/$l/$rel';
    final description = _esc(s['hero_body'] as String);

    // Üst menüde "Özellikler" dar ekranda gizleniyor (sayfanın kendisi);
    // gizlilik ve destek her ekranda erişilebilir.
    String links(List<(String, String)> items) => items
        .map(
          (n) =>
              '<a class="nav-${n.$1}" href="$up$lang/'
              '${n.$1 == 'features' ? '#features' : '${n.$1}/'}"'
              '${n.$1 == section ? ' aria-current="page"' : ''}>'
              '${_esc(s[n.$2] as String)}</a>',
        )
        .join();
    final top = links([
      ('features', 'nav_features'),
      ('privacy', 'nav_privacy'),
      ('support', 'nav_support'),
    ]);
    final bottom = links([
      ('features', 'nav_features'),
      ('privacy', 'nav_privacy'),
      ('terms', 'nav_terms'),
      ('support', 'nav_support'),
    ]);
    final langs = languages
        .map(
          (l) =>
              '<a href="$up$l/$rel" hreflang="$l" lang="$l"'
              '${l == lang ? ' aria-current="true"' : ''}>'
              '${_esc(site(l)['lang_name'] as String)}</a>',
        )
        .join();
    final hreflang = [
      for (final l in languages)
        '<link rel="alternate" hreflang="$l" href="${alt(l)}">',
      if (b != null) '<link rel="alternate" hreflang="x-default" href="$b/">',
    ].join('\n');
    // Bağlantı önizlemesi mutlak adres istiyor: site adresi girilince.
    final social = b == null
        ? ''
        : '''
<link rel="canonical" href="${alt(lang)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Nilu">
<meta property="og:locale" content="${_ogLocales[lang]}">
<meta property="og:title" content="${_esc(title)}">
<meta property="og:description" content="$description">
<meta property="og:url" content="${alt(lang)}">
<meta property="og:image" content="$b/assets/og/$lang.jpg">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt" content="${_esc(_plain(s['hero_title'] as String))}">
<meta name="twitter:card" content="summary_large_image">''';
    final brand =
        '<a class="brand" href="$up$lang/"><img src="${up}assets/icon-256.png" '
        'alt="" width="32" height="32"><span>Nilu</span></a>';

    return '''<!doctype html>
<html lang="$lang">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_esc(title)}</title>
<meta name="description" content="$description">
<meta name="theme-color" content="#22001a">
<link rel="preload" href="${up}assets/fonts/Newsreader-Medium.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="${up}assets/fonts/PlusJakartaSans-Regular.woff2" as="font" type="font/woff2" crossorigin>
<link rel="stylesheet" href="${up}assets/style.css">
<link rel="icon" type="image/png" href="${up}assets/favicon.png">
<link rel="apple-touch-icon" href="${up}assets/apple-touch-icon.png">
$hreflang$social
</head>
<body class="page-${section == 'home' ? 'home' : 'doc'}">
<a class="skip" href="#icerik">${_esc(title)}</a>
<header class="site"><div class="wrap">
$brand
<nav class="main">$top</nav>
<details class="lang-menu"><summary aria-label="${_esc(s['language'] as String)}">${_icon('globe')}<span>${lang.toUpperCase()}</span></summary>
<div class="lang-list">$langs</div></details>
</div></header>
<main id="icerik">
$body
</main>
<footer class="site"><div class="wrap">
<div class="foot-top">$brand<p class="tagline">${_esc(_plain(s['hero_title'] as String))}</p></div>
<div class="links">$bottom</div>
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

  /// Çerçeveli ekran (tool/site_assets.py). Boyut, yüklenirken yerleşim
  /// kaymasın diye: 600 piksellik ekran + çerçeve.
  String _phone(
    String lang,
    String shot,
    String alt, {
    String cls = 'phone',
    bool lazy = true,
  }) =>
      '<img class="$cls" src="../assets/screens/$lang/$shot.webp" '
      'alt="${_esc(alt)}" width="656" height="1360"'
      '${lazy ? ' loading="lazy"' : ''} decoding="async">';

  String _home(String lang) {
    final s = site(lang);
    String t(String key) => _esc(s[key] as String);
    List<Map<String, dynamic>> items(String key) =>
        (s[key] as List).cast<Map<String, dynamic>>();
    final apple = appStoreUrl;
    final play = playStoreUrl;
    // Apple: App Store rozeti sırada ilk ve diğer rozet varken siyah olanı.
    // Google: Google Play rozeti ötekilerle aynı boyda ya da büyük. Rozetler
    // sayfada bir kez: Apple'ın kuralı sayfa başına bir rozet.
    final badges = [
      if (apple != null)
        _badge(apple, 'app-store-$lang.svg', s['badge_app_store'] as String),
      if (play != null)
        _badge(play, 'google-play-$lang.svg', s['badge_google_play'] as String),
    ];
    final cta = badges.isEmpty
        ? '<p class="soon">${t('coming_soon')}</p>'
        : '<div class="badges">${badges.join()}</div>';

    const trustIcons = ['account', 'shield', 'lock'];
    final trust = [
      for (final (i, label) in (s['trust'] as List).cast<String>().indexed)
        '<li>${_icon(trustIcons[i])}${_esc(label)}</li>',
    ].join();

    final rows = items('showcase')
        .map(
          (r) =>
              '''
<article class="row row-${r['id']}">
<div class="row-copy">
<p class="label">${_esc(r['label'] as String)}</p>
<h3>${_marked(r['title'] as String)}</h3>
<p>${_esc(r['body'] as String)}</p>
</div>
<div class="stage">${_phone(lang, r['id'] as String, r['alt'] as String)}</div>
</article>''',
        )
        .join();

    final tiles = items('more')
        .map(
          (x) =>
              '<li><span class="tile-icon">${_icon(x['icon'] as String)}</span>'
              '<h3>${_esc(x['title'] as String)}</h3>'
              '<p>${_esc(x['body'] as String)}</p></li>',
        )
        .join('\n');

    final points = (s['privacy_points'] as List)
        .map(
          (p) => '<li>${_icon('check')}<span>${_esc(p as String)}</span></li>',
        )
        .join('\n');

    // Sık sorulanlardan e-posta geçmeyen ilk üçü; hepsi destek sayfasında.
    final faq = items('faq')
        .where((f) => !(f['a'] as String).contains('{email}'))
        .take(3)
        .map(
          (f) =>
              '<details><summary>${_esc(f['q'] as String)}</summary>'
              '<p>${_render(lang, f['a'] as String)}</p></details>',
        )
        .join('\n');

    // Apple'ın kuralı: rozet ana mesajdan sonra ve ondan küçük, yanında
    // Sağlık'ın faydası ve gizlilik cümlesi. Rozet çevrilmiyor.
    final health = apple == null
        ? ''
        : '''
<section class="health"><div class="wrap narrow"><div class="card">
<h2>${t('health_title')}</h2>
<p>${t('health_body')}</p>
<p class="note">${t('health_privacy')}</p>
<img class="health-badge" src="../assets/badges/apple-health.svg" alt="Works with Apple Health" height="40">
</div></div></section>''';
    // Rozetlerdeki markaların sahip satırları (ikisinin de kuralı istiyor).
    final credits = [
      if (apple != null) 'trademarks_apple',
      if (play != null) 'trademarks_google',
    ].map((k) => '\n<p class="legal">${t(k)}</p>').join();

    return _layout(
      lang: lang,
      section: 'home',
      title: 'Nilu — ${_plain(s['hero_title'] as String)}',
      depth: 1,
      body:
          '''
<section class="hero">
<div class="wrap hero-grid">
<div class="hero-copy">
<p class="eyebrow">${t('hero_eyebrow')}</p>
<h1>${_marked(s['hero_title'] as String)}</h1>
<p class="lead">${t('hero_body')}</p>
<div class="cta-row">$cta<a class="more-link" href="#features">${t('hero_more')}${_icon('down')}</a></div>
<ul class="trust">$trust</ul>
</div>
<div class="hero-art">
${_phone(lang, 'calendar', '', cls: 'back', lazy: false)}
${_phone(lang, 'home', s['hero_alt'] as String, cls: 'front', lazy: false)}
<img class="ring" src="../assets/screens/$lang/ring.webp" alt="" width="560" height="448" decoding="async">
</div>
</div>
</section>
<section class="features" id="features">
<div class="wrap">
<header class="section-head"><p class="eyebrow">${t('features_title')}</p><h2>${t('features_lead')}</h2></header>
$rows
</div>
</section>
<section class="more"><div class="wrap">
<h2>${t('more_title')}</h2>
<ul class="tiles">
$tiles
</ul>
</div></section>$health
<section class="privacy-band"><div class="band">
<div class="band-copy">
<p class="eyebrow">${t('nav_privacy')}</p>
<h2>${t('privacy_title')}</h2>
<ul class="checks">
$points
</ul>
<a class="button" href="privacy/">${t('privacy_more')}${_icon('right')}</a>
</div>
<div class="band-art">${_phone(lang, 'privacy_security', s['privacy_alt'] as String)}</div>
</div></section>
<section class="faq-preview"><div class="wrap narrow qa">
<h2>${t('faq_title')}</h2>
$faq
<a class="text-link" href="support/">${t('faq_more')}${_icon('right')}</a>
</div></section>
<section class="final"><div class="wrap">
<img src="../assets/icon-256.png" alt="" width="96" height="96" loading="lazy">
<h2>${_marked(s['final_title'] as String)}</h2>
<p>${t('final_body')}</p>
</div></section>
<section class="fine"><div class="wrap narrow">
<p>${t('medical')}</p>$credits
</div></section>''',
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
      ..writeln('<div class="doc"><div class="wrap narrow">')
      ..writeln('<article>')
      ..writeln('<h1>${_esc(title)}</h1>')
      ..writeln('<p class="updated">${_esc(_app(lang, updatedKey))}</p>');
    for (final (t, c) in _sections(lang, prefix)) {
      body
        ..writeln('<h2>${_esc(t)}</h2>')
        ..writeln(_paras(_render(lang, c)));
    }
    body.writeln('</article>\n</div></div>');
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
<div class="doc"><div class="wrap narrow qa">
<article>
<h1>${_esc(s['support_title'] as String)}</h1>
<p class="intro">${_esc(s['support_intro'] as String)}</p>
<p class="contact">${_render(lang, s['support_contact'] as String)}</p>
<h2>${_esc(s['faq_title'] as String)}</h2>
$faq
<p class="note">${_esc(s['medical'] as String)}</p>
</article>
</div></div>''',
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
<meta name="theme-color" content="#22001a">
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
<body class="page-root">
<main class="root-box">
<img src="assets/icon-256.png" alt="" width="96" height="96">
<h1>Nilu</h1>
<ul class="langs-list">
$list
</ul>
</main>
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
<meta name="theme-color" content="#22001a">
<link rel="stylesheet" href="${yol}assets/style.css">
<title>Nilu — 404</title></head>
<body class="page-root">
<main class="root-box">
<img src="${yol}assets/icon-256.png" alt="" width="96" height="96">
<h1>404</h1>
<ul class="langs-list">
$list
</ul>
</main>
</body>
</html>
''';
  }

  /// Partner davet bağlantısının sayfası: `…/p/#KOD`.
  ///
  /// Uygulama yüklüyse bağlantı bu sayfayı hiç açmıyor (Universal Link;
  /// kök alan adındaki doğrulama dosyası, SETUP_KEYS.md §8.7). Burası
  /// uygulama yüklü değilken ya da bağlantı tarayıcıda açıldığında
  /// görünüyor: "Nilu'da aç" (`nilu://p#KOD`; aynı alan adındaki sayfadan
  /// Universal Link açılmıyor), indirme yolu ve elle yazmak için kodun
  /// kendisi. Kod `#`'ten sonra: sunucuya gitmiyor, betik okuyor.
  String _invite() {
    String duz(String lang, String key) =>
        (site(lang)[key] as String).replaceAllMapped(
          RegExp(r'\{\{([a-z0-9_]+)\}\}'),
          (m) => _app(lang, m.group(1)!),
        );
    const anahtarlar = [
      'invite_title',
      'invite_body',
      'invite_open',
      'invite_install',
      'invite_code',
      'invite_note',
      'invite_missing',
    ];
    // Girintili: tek satırda `}}` çevrilmemiş bir anahtara benziyordu.
    final metinler = const JsonEncoder.withIndent(' ').convert({
      for (final l in languages) l: {for (final k in anahtarlar) k: duz(l, k)},
    });
    // `nilu://` uygulamanın şeması: AppInfo.linkScheme ve Info.plist.
    final store = appStoreUrl;
    final storeHtml = store == null
        ? ''
        : '<p><a class="button" href="${_esc(store)}">App Store</a></p>';
    return '''<!doctype html>
<html lang="$defaultLanguage">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<meta name="referrer" content="no-referrer">
<meta name="theme-color" content="#22001a">
<link rel="stylesheet" href="../assets/style.css">
<link rel="icon" type="image/png" href="../assets/favicon.png">
<title>Nilu</title>
</head>
<body class="page-root page-invite">
<main class="root-box invite-box">
<img src="../assets/icon-256.png" alt="" width="96" height="96">
<h1 id="t">Nilu</h1>
<p id="b"></p>
<div id="kodlu">
<p><a id="ac" class="button" href="#"></a></p>
<p id="i" class="muted"></p>
$storeHtml
<p id="c" class="muted"></p>
<p><span id="k" class="invite-code"></span></p>
<p id="n" class="muted"></p>
</div>
</main>
<script>
(function () {
  var t = $metinler;
  var prefs = navigator.languages || [navigator.language || ''];
  var lang = '$defaultLanguage';
  for (var i = 0; i < prefs.length; i++) {
    var c = (prefs[i] || '').slice(0, 2).toLowerCase();
    if (t[c]) { lang = c; break; }
  }
  var s = t[lang];
  document.documentElement.lang = lang;
  document.title = s.invite_title;
  function yaz(id, metin) { document.getElementById(id).textContent = metin; }
  yaz('t', s.invite_title);
  var kod = (location.hash || '').slice(1).replace(/[^A-Za-z0-9]/g, '').toUpperCase();
  if (!/^[A-HJKMNP-Z2-9]{20}\$/.test(kod)) {
    yaz('b', s.invite_missing);
    document.getElementById('kodlu').hidden = true;
    return;
  }
  yaz('b', s.invite_body);
  var ac = document.getElementById('ac');
  ac.textContent = s.invite_open;
  ac.href = 'nilu://p#' + kod;
  yaz('i', s.invite_install);
  yaz('c', s.invite_code);
  yaz('k', kod.replace(/(.{4})(?!\$)/g, '\$1 '));
  yaz('n', s.invite_note);
})();
</script>
</body>
</html>
''';
  }

  /// E-posta doğrulama ve şifre yenileme bağlantılarının sayfası:
  /// `…/auth/?mode=…&oobCode=…&apiKey=…&lang=…` (Firebase'deki "action
  /// URL", `AppInfo.authLinkBase`).
  ///
  /// Firebase bu projede action URL'nin değiştirilmesine izin vermediği
  /// için bugün e-postadaki bağlantı Firebase'in sayfasını açıyor; burası
  /// oradaki "Devam"ın götürdüğü yer (`?mode=verified` / `?mode=resetDone`).
  /// Aşağıdaki kodlu akış action URL değiştirilebilirse hazır.
  ///
  /// Uygulama yüklü telefonda bağlantı bu sayfayı açmıyor: Universal Link
  /// uygulamayı açıyor ve işlem orada bitiyor. Burası bağlantı başka bir
  /// cihazda ya da e-posta uygulamasının kendi tarayıcısında açıldığında
  /// görünüyor ve işlemi Firebase'in REST arayüzüyle kendisi bitiriyor:
  /// doğrulamada `accounts:update`, şifrede `accounts:resetPassword`.
  /// Önceden bu iş Firebase'in kendi sayfasındaydı (`…firebaseapp.com`).
  ///
  /// Kod tek kullanımlık ve adreste duruyor: sayfa dışarıdan hiçbir şey
  /// yüklemiyor, yönlendiren bilgisi gönderilmiyor, dizine girmiyor.
  String _authAction() {
    const anahtarlar = [
      'auth_verify_title',
      'auth_verify_working',
      'auth_verify_done',
      'auth_verify_failed',
      'auth_back_to_app',
      'auth_reset_title',
      'auth_reset_for',
      'auth_reset_label',
      'auth_reset_hint',
      'auth_reset_button',
      'auth_reset_in_app',
      'auth_reset_short',
      'auth_reset_done',
      'auth_reset_failed',
      'auth_error',
      'auth_unknown',
    ];
    final metinler = const JsonEncoder.withIndent(' ').convert({
      for (final l in languages)
        l: {for (final k in anahtarlar) k: site(l)[k] as String},
    });
    return '''<!doctype html>
<html lang="$defaultLanguage">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<meta name="referrer" content="no-referrer">
<meta name="theme-color" content="#22001a">
<link rel="stylesheet" href="../assets/style.css">
<link rel="icon" type="image/png" href="../assets/favicon.png">
<title>Nilu</title>
</head>
<body class="page-root page-invite">
<main class="root-box invite-box">
<img src="../assets/icon-256.png" alt="" width="96" height="96">
<h1 id="t">Nilu</h1>
<p id="b" role="status"></p>
<form id="f" class="auth-form" hidden>
<p><label id="sl" for="s"></label>
<input id="s" type="password" autocomplete="new-password" minlength="8" required></p>
<p id="sh" class="muted"></p>
<p id="se" class="auth-error" role="alert" hidden></p>
<p><button id="sb" class="button" type="submit"></button></p>
</form>
<p><a id="ac" class="button" href="#" hidden></a></p>
<p><a id="ap" class="auth-link" href="#" hidden></a></p>
</main>
<script>
(function () {
  var t = $metinler;
  var q = new URLSearchParams(location.search);
  var mode = q.get('mode'), kod = q.get('oobCode'), key = q.get('apiKey');
  var lang = (q.get('lang') || '').slice(0, 2).toLowerCase();
  if (!t[lang]) {
    lang = '$defaultLanguage';
    var prefs = navigator.languages || [navigator.language || ''];
    for (var i = 0; i < prefs.length; i++) {
      var c = (prefs[i] || '').slice(0, 2).toLowerCase();
      if (t[c]) { lang = c; break; }
    }
  }
  var s = t[lang];
  document.documentElement.lang = lang;
  function el(id) { return document.getElementById(id); }
  function yaz(id, metin) { el(id).textContent = metin; }
  function dugme(id, metin, adres) { var a = el(id); a.textContent = metin; a.href = adres; a.hidden = false; }
  function istek(yol, govde) {
    return fetch('https://identitytoolkit.googleapis.com/v1/accounts:' + yol + '?key=' + encodeURIComponent(key), {
      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(govde)
    }).then(function (r) {
      return r.json().then(function (j) { if (!r.ok) throw j; return j; });
    });
  }
  function kodHatasi(e) {
    var m = (e && e.error && e.error.message) || '';
    return /OOB_CODE|EXPIRED|USER_NOT_FOUND|USER_DISABLED/.test(m);
  }
  var uygulama = 'nilu://auth?mode=verified';

  // Firebase'in sayfasında iş bitti, "Devam" buraya getirdi (uygulama
  // yüklüyse bu adres sayfayı değil uygulamayı açıyor).
  if (mode === 'verified' || mode === 'resetDone') {
    var bitti = mode === 'verified' ? s.auth_verify_title : s.auth_reset_title;
    document.title = bitti;
    yaz('t', bitti);
    yaz('b', mode === 'verified' ? s.auth_verify_done : s.auth_reset_done);
    dugme('ac', s.auth_back_to_app, uygulama);
    return;
  }

  if (!kod || !key) { yaz('b', s.auth_unknown); return; }

  if (mode === 'verifyEmail') {
    document.title = s.auth_verify_title;
    yaz('t', s.auth_verify_title);
    yaz('b', s.auth_verify_working);
    istek('update', { oobCode: kod }).then(function () {
      yaz('b', s.auth_verify_done);
      dugme('ac', s.auth_back_to_app, uygulama);
    }, function (e) {
      yaz('b', kodHatasi(e) ? s.auth_verify_failed : s.auth_error);
      dugme('ac', s.auth_back_to_app, uygulama);
    });
    return;
  }

  if (mode === 'resetPassword') {
    document.title = s.auth_reset_title;
    yaz('t', s.auth_reset_title);
    istek('resetPassword', { oobCode: kod }).then(function (j) {
      yaz('b', s.auth_reset_for.replace('%EMAIL%', j.email || ''));
      yaz('sl', s.auth_reset_label);
      yaz('sh', s.auth_reset_hint);
      yaz('sb', s.auth_reset_button);
      el('f').hidden = false;
      dugme('ap', s.auth_reset_in_app, 'nilu://auth?mode=resetPassword&oobCode=' + encodeURIComponent(kod));
    }, function (e) {
      yaz('b', kodHatasi(e) ? s.auth_reset_failed : s.auth_error);
    });
    el('f').addEventListener('submit', function (olay) {
      olay.preventDefault();
      var sifre = el('s').value;
      var hata = el('se');
      if (sifre.length < 8) { hata.textContent = s.auth_reset_short; hata.hidden = false; return; }
      hata.hidden = true;
      el('sb').disabled = true;
      istek('resetPassword', { oobCode: kod, newPassword: sifre }).then(function () {
        el('f').hidden = true;
        el('ap').hidden = true;
        yaz('b', s.auth_reset_done);
        dugme('ac', s.auth_back_to_app, uygulama);
      }, function (e) {
        el('sb').disabled = false;
        hata.textContent = kodHatasi(e) ? s.auth_reset_failed : s.auth_error;
        hata.hidden = false;
      });
    });
    return;
  }

  yaz('b', s.auth_unknown);
})();
</script>
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
      (path: 'p/index.html', content: _invite()),
      (path: 'auth/index.html', content: _authAction()),
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
