// Yayın öncesi denetim: hesaplara bağlı her şey doldurulmuş mu?
//
//     dart run tool/check_release.dart
//
// Eksik varsa her birini nereden alınacağıyla birlikte yazar ve 1 ile çıkar.
// Kod tarafındaki işler (analiz, testler) burada değil; bu yalnızca
// hesaplardan gelen değerlere ve onlara bağlı dosyalara bakıyor.
//
// Değerler `lib/core/release_config.dart`'tan **metin olarak** okunuyor (içe
// aktarılmıyor): böylece test, doldurulmuş ve boş örnek projelerle
// denetleyicinin kendisini sınayabiliyor.
import 'dart:convert';
import 'dart:io';

import 'release_values.dart';

/// Bulunan bir eksik.
class ReleaseIssue {
  const ReleaseIssue(this.what, this.how);

  /// Ne eksik.
  final String what;

  /// Nasıl tamamlanır.
  final String how;

  @override
  String toString() => '$what\n      → $how';
}

/// Google'ın test yayıncı kimliği: bununla yayına çıkılmaz.
const String googleTestPublisher = '3940256099942544';

final RegExp _appId = RegExp(r'^ca-app-pub-(\d{16})~(\d{10})$');
final RegExp _unitId = RegExp(r'^ca-app-pub-(\d{16})/(\d{10})$');
final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? _plistAnahtar(String plist, String anahtar) => RegExp(
  '<key>$anahtar</key>\\s*<string>([^<]*)</string>',
).firstMatch(plist)?.group(1);

/// [root] projesini denetler; eksik yoksa boş liste.
List<ReleaseIssue> checkRelease(Directory root) {
  final issues = <ReleaseIssue>[];
  File f(String yol) => File('${root.path}/$yol');

  // ── ReleaseConfig ──
  final config = f('lib/core/release_config.dart').readAsStringSync();
  final rc = releaseValue(config, 'revenueCatAppleApiKey');
  if (rc == null || !rc.startsWith('appl_') || rc.length < 20) {
    issues.add(
      const ReleaseIssue(
        'RevenueCat App Store anahtarı (ReleaseConfig.revenueCatAppleApiKey)',
        'RevenueCat → Project settings → API keys → App Store public key '
            '(appl_ ile başlar). SETUP_KEYS.md §5',
      ),
    );
  }

  final appId = releaseValue(config, 'admobAppIdIos');
  final appMatch = appId == null ? null : _appId.firstMatch(appId);
  if (appMatch == null || appMatch.group(1) == googleTestPublisher) {
    issues.add(
      const ReleaseIssue(
        'AdMob iOS App ID (ReleaseConfig.admobAppIdIos)',
        'AdMob → Apps → iOS uygulaması → App ID (ca-app-pub-…~…). '
            'SETUP_KEYS.md §6',
      ),
    );
  }

  final unit = releaseValue(config, 'admobBannerUnitIos');
  final unitMatch = unit == null ? null : _unitId.firstMatch(unit);
  if (unitMatch == null || unitMatch.group(1) == googleTestPublisher) {
    issues.add(
      const ReleaseIssue(
        'AdMob banner birimi (ReleaseConfig.admobBannerUnitIos)',
        'AdMob → Ad units → Banner (ca-app-pub-…/…). SETUP_KEYS.md §6',
      ),
    );
  } else if (appMatch != null && unitMatch.group(1) != appMatch.group(1)) {
    issues.add(
      const ReleaseIssue(
        'AdMob banner birimi başka bir yayıncı hesabına ait',
        'App ID ile banner birimi aynı AdMob hesabından olmalı',
      ),
    );
  }

  final email = releaseValue(config, 'supportEmail');
  if (email == null || !_email.hasMatch(email)) {
    issues.add(
      const ReleaseIssue(
        'Destek e-postası (ReleaseConfig.supportEmail)',
        'Politika §10 ve Şartlar §12 bu adresi gösteriyor; kullanıcı haklarını '
            'buradan kullanacak',
      ),
    );
  }

  // ── Info.plist ──
  final plist = f('ios/Runner/Info.plist').readAsStringSync();
  final plistAppId = _plistAnahtar(plist, 'GADApplicationIdentifier');
  if (appMatch != null && plistAppId != appId) {
    issues.add(
      ReleaseIssue(
        'Info.plist GADApplicationIdentifier ($plistAppId) '
            'ReleaseConfig ile aynı değil',
        'ios/Runner/Info.plist içinde $appId yaz',
      ),
    );
  } else if (plistAppId == null || plistAppId.contains(googleTestPublisher)) {
    issues.add(
      const ReleaseIssue(
        'Info.plist GADApplicationIdentifier hâlâ Google test kimliği',
        'ios/Runner/Info.plist içinde gerçek AdMob App ID',
      ),
    );
  }

  // ── Firebase ──
  final gsi = f('ios/Runner/GoogleService-Info.plist');
  if (!gsi.existsSync()) {
    issues.add(
      const ReleaseIssue(
        'Firebase iOS yapılandırması (ios/Runner/GoogleService-Info.plist)',
        'flutterfire configure (Runner hedefine ekler). SETUP_KEYS.md §7',
      ),
    );
  } else {
    final pbx = f('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    if (!pbx.contains('GoogleService-Info.plist in Resources')) {
      issues.add(
        const ReleaseIssue(
          'GoogleService-Info.plist Runner hedefinin kaynaklarında değil',
          'Xcode → Runner → Build Phases → Copy Bundle Resources',
        ),
      );
    }
    final gsiMetni = gsi.readAsStringSync();
    final bundle = _plistAnahtar(gsiMetni, 'BUNDLE_ID');
    if (bundle != null && bundle != 'com.furkan.rcperiodtracker') {
      issues.add(
        ReleaseIssue(
          'GoogleService-Info.plist başka bir uygulamaya ait ($bundle)',
          'Firebase projesine com.furkan.rcperiodtracker iOS uygulamasını ekle',
        ),
      );
    }

    // Google ile giriş sayfası uygulamaya bu adresle dönüyor. Firebase
    // REVERSED_CLIENT_ID'yi, o yoksa kodlanmış uygulama kimliğini kullanır.
    final tersKimlik = _plistAnahtar(gsiMetni, 'REVERSED_CLIENT_ID');
    final uygulama = _plistAnahtar(gsiMetni, 'GOOGLE_APP_ID');
    final beklenen = [
      ?tersKimlik,
      if (uygulama != null) 'app-${uygulama.replaceAll(':', '-')}',
    ];
    if (!beklenen.any((s) => plist.contains('<string>$s</string>'))) {
      issues.add(
        ReleaseIssue(
          'Google ile giriş dönüş adresi (Info.plist → CFBundleURLSchemes)',
          tersKimlik == null
              ? 'Firebase → Authentication → Google sağlayıcısını aç, '
                    'GoogleService-Info.plist\'i yeniden indir; içindeki '
                    'REVERSED_CLIENT_ID\'yi Info.plist\'e yaz. SETUP_KEYS.md §7'
              : 'ios/Runner/Info.plist içinde YER-TUTUCU yerine $tersKimlik',
        ),
      );
    }
  }

  // ── Apple ile giriş ──
  final yetkiler = f('ios/Runner/Runner.entitlements');
  if (!yetkiler.existsSync() ||
      !yetkiler.readAsStringSync().contains(
        'com.apple.developer.applesignin',
      )) {
    issues.add(
      const ReleaseIssue(
        'Apple ile giriş yetkisi (Runner.entitlements)',
        'com.apple.developer.applesignin = [Default]; App ID\'de "Sign in '
            'with Apple" capability. SETUP_KEYS.md §7',
      ),
    );
  }
  final firebaserc = f('.firebaserc');
  String? proje;
  if (firebaserc.existsSync()) {
    final projeler =
        (jsonDecode(firebaserc.readAsStringSync()) as Map)['projects'] as Map?;
    proje = projeler?['default'] as String?;
  }
  if (proje == null || proje.isEmpty || proje == 'YER_TUTUCU') {
    issues.add(
      const ReleaseIssue(
        'Firebase proje kimliği (.firebaserc)',
        'firebase use --add (ya da .firebaserc.example\'ı kopyala) — '
            'kurallar `firebase deploy --only firestore` ile yüklenir',
      ),
    );
  }

  // ── Site ──
  final site = f('site/site.json');
  final siteConfig = site.existsSync()
      ? jsonDecode(site.readAsStringSync()) as Map<String, dynamic>
      : const <String, dynamic>{};
  final base = siteConfig['baseUrl'] as String?;
  if (base == null ||
      !base.startsWith('https://') ||
      base.contains('YER_TUTUCU')) {
    issues.add(
      const ReleaseIssue(
        'Sitenin adresi (site/site.json → baseUrl)',
        'GitHub Pages adresi, ör. https://kullanici.github.io/nilu. '
            'App Store Connect\'e gizlilik ve destek adresi olarak girilecek',
      ),
    );
  }

  if (Directory('${root.path}/android').existsSync()) {
    issues.addAll(_checkAndroid(root, config, appMatch));
  }

  return issues;
}

/// Google Play'e çıkmadan önce: Android tarafının hesaplara bağlı değerleri.
///
/// Yalnızca `android/` varsa denetleniyor.
List<ReleaseIssue> _checkAndroid(
  Directory root,
  String config,
  RegExpMatch? iosAppMatch,
) {
  final issues = <ReleaseIssue>[];
  File f(String yol) => File('${root.path}/$yol');

  final rc = releaseValue(config, 'revenueCatGoogleApiKey');
  if (rc == null || !rc.startsWith('goog_') || rc.length < 20) {
    issues.add(
      const ReleaseIssue(
        'RevenueCat Google Play anahtarı '
            '(ReleaseConfig.revenueCatGoogleApiKey)',
        'RevenueCat → Project settings → API keys → Google Play public key '
            '(goog_ ile başlar). SETUP_KEYS.md §5',
      ),
    );
  }

  final appId = releaseValue(config, 'admobAppIdAndroid');
  final appMatch = appId == null ? null : _appId.firstMatch(appId);
  if (appMatch == null || appMatch.group(1) == googleTestPublisher) {
    issues.add(
      const ReleaseIssue(
        'AdMob Android App ID (ReleaseConfig.admobAppIdAndroid)',
        'AdMob → Apps → Android uygulaması → App ID (ca-app-pub-…~…). '
            'SETUP_KEYS.md §6',
      ),
    );
  } else if (iosAppMatch != null && appMatch.group(1) != iosAppMatch.group(1)) {
    issues.add(
      const ReleaseIssue(
        'AdMob Android App ID başka bir yayıncı hesabına ait',
        'iOS ve Android uygulamaları aynı AdMob hesabında olmalı',
      ),
    );
  }

  final unit = releaseValue(config, 'admobBannerUnitAndroid');
  final unitMatch = unit == null ? null : _unitId.firstMatch(unit);
  if (unitMatch == null || unitMatch.group(1) == googleTestPublisher) {
    issues.add(
      const ReleaseIssue(
        'AdMob Android banner birimi (ReleaseConfig.admobBannerUnitAndroid)',
        'AdMob → Android uygulaması → Ad units → Banner. SETUP_KEYS.md §6',
      ),
    );
  }

  final manifest = f('android/app/src/main/AndroidManifest.xml');
  final manifestAppId = manifest.existsSync()
      ? RegExp(
          r'android:name="com\.google\.android\.gms\.ads\.APPLICATION_ID"'
          r'\s*android:value="([^"]*)"',
        ).firstMatch(manifest.readAsStringSync())?.group(1)
      : null;
  if (appMatch != null && manifestAppId != appId) {
    issues.add(
      ReleaseIssue(
        'AndroidManifest AdMob APPLICATION_ID ($manifestAppId) '
            'ReleaseConfig ile aynı değil',
        'android/app/src/main/AndroidManifest.xml içinde $appId yaz',
      ),
    );
  } else if (manifestAppId == null ||
      manifestAppId.contains(googleTestPublisher)) {
    issues.add(
      const ReleaseIssue(
        'AndroidManifest AdMob APPLICATION_ID hâlâ Google örnek kimliği',
        'android/app/src/main/AndroidManifest.xml içinde gerçek App ID',
      ),
    );
  }

  final gs = f('android/app/google-services.json');
  if (!gs.existsSync()) {
    issues.add(
      const ReleaseIssue(
        'Firebase Android yapılandırması (android/app/google-services.json)',
        'flutterfire configure ya da Firebase konsolu → Android uygulaması '
            '(com.furkan.rcperiodtracker). SETUP_KEYS.md §7',
      ),
    );
  } else {
    final json = jsonDecode(gs.readAsStringSync()) as Map<String, dynamic>;
    final clients = (json['client'] as List?) ?? const [];
    Map<String, dynamic>? bizim;
    for (final c in clients.cast<Map<String, dynamic>>()) {
      final info = c['client_info'] as Map<String, dynamic>?;
      final android = info?['android_client_info'] as Map<String, dynamic>?;
      if (android?['package_name'] == 'com.furkan.rcperiodtracker') bizim = c;
    }
    if (bizim == null) {
      issues.add(
        const ReleaseIssue(
          'google-services.json com.furkan.rcperiodtracker için değil',
          'Firebase projesine bu paket adıyla Android uygulaması ekle',
        ),
      );
    } else {
      // Google ile giriş Android'de uygulamanın imza parmak izini istiyor;
      // eklenmişse dosyada sertifikalı bir OAuth istemcisi oluyor.
      final oauth = (bizim['oauth_client'] as List?) ?? const [];
      final imzali = oauth.cast<Map<String, dynamic>>().any(
        (o) => (o['android_info'] as Map?)?['certificate_hash'] != null,
      );
      if (!imzali) {
        issues.add(
          const ReleaseIssue(
            'Google ile giriş için imza parmak izi (SHA-1/SHA-256) yok',
            'Firebase → Proje ayarları → Android uygulaması → SHA ekle '
                '(yükleme anahtarı ve Play App Signing anahtarı), sonra '
                'google-services.json\'u yeniden indir. SETUP_KEYS.md §7',
          ),
        );
      }
    }
  }

  if (!f('android/key.properties').existsSync()) {
    issues.add(
      const ReleaseIssue(
        'Yayın imzası (android/key.properties)',
        'android/key.properties.example\'ı kopyala; anahtar deposunu '
            'keytool ile oluştur. Yoksa derleme debug anahtarıyla imzalanır',
      ),
    );
  }

  return issues;
}

void main(List<String> args) {
  final root = Directory(args.isNotEmpty ? args.first : '.');
  final issues = checkRelease(root);
  if (issues.isEmpty) {
    stdout.writeln('Yayına hazır: hesaplara bağlı her değer dolu.');
    return;
  }
  stderr.writeln('Yayından önce tamamlanacak ${issues.length} şey var:\n');
  for (final i in issues) {
    stderr.writeln('  ✗ $i\n');
  }
  exitCode = 1;
}
