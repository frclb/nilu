import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/data/datasources/ads_datasource.dart';

import '../../tool/check_release.dart';

/// Yayın denetleyicisi hesaplara bağlı eksikleri buluyor mu?
///
/// Hesaplar henüz bağlanmadı; denetleyicinin şu an başarısız olması doğru
/// davranış. Asıl sınanan: doldurulmuş bir projede hiç eksik bulmaması,
/// tek bir değer eksikse onu bulması.
void main() {
  late Directory kok;

  const appId = 'ca-app-pub-1234567890123456~1234567890';
  const banner = 'ca-app-pub-1234567890123456/0987654321';
  const tersKimlik = 'com.googleusercontent.apps.123-abc';

  void yaz(String yol, String icerik) {
    final f = File('${kok.path}/$yol')..createSync(recursive: true);
    f.writeAsStringSync(icerik);
  }

  String config({
    String rc = "'appl_AbCdEfGhIjKlMnOpQrStUvWx'",
    String app = "'$appId'",
    String unit = "'$banner'",
    String email = "'destek@nilu.app'",
  }) =>
      '''
class ReleaseConfig {
  static const String revenueCatAppleApiKey = $rc;
  static const String admobAppIdIos = $app;
  static const String admobBannerUnitIos = $unit;
  static const String? supportEmail = $email;
  static const String placeholder = 'YER_TUTUCU';
}
''';

  void doluProje({String? configMetni}) {
    yaz('lib/core/release_config.dart', configMetni ?? config());
    yaz(
      'ios/Runner/Info.plist',
      '<dict><key>GADApplicationIdentifier</key><string>$appId</string>'
          '<key>CFBundleURLSchemes</key><array><string>$tersKimlik</string>'
          '</array></dict>',
    );
    yaz(
      'ios/Runner/GoogleService-Info.plist',
      '<dict><key>BUNDLE_ID</key><string>com.furkan.rcperiodtracker</string>'
          '<key>REVERSED_CLIENT_ID</key><string>$tersKimlik</string>'
          '<key>GOOGLE_APP_ID</key><string>1:123:ios:abc</string></dict>',
    );
    yaz(
      'ios/Runner/Runner.entitlements',
      '<dict><key>com.apple.developer.applesignin</key>'
          '<array><string>Default</string></array></dict>',
    );
    yaz(
      'ios/Runner.xcodeproj/project.pbxproj',
      '/* GoogleService-Info.plist in Resources */',
    );
    yaz('.firebaserc', '{"projects": {"default": "nilu-prod"}}');
    yaz('site/site.json', '{"baseUrl": "https://ornek.github.io/nilu"}');
  }

  setUp(() => kok = Directory.systemTemp.createTempSync('release_'));
  tearDown(() => kok.deleteSync(recursive: true));

  test('her şey doluysa eksik yok', () {
    doluProje();
    expect(checkRelease(kok), isEmpty);
  });

  test('bugünkü proje: hesaplar bağlanmadığı için eksikler listeleniyor', () {
    final eksikler = checkRelease(Directory.current).map((i) => i.what);
    expect(eksikler, contains(contains('RevenueCat')));
    expect(eksikler, contains(contains('AdMob iOS App ID')));
    expect(eksikler, contains(contains('Destek e-postası')));
    expect(eksikler, contains(contains('GoogleService-Info.plist')));
  });

  test('Google test kimlikleriyle yayına çıkılmıyor', () {
    doluProje(
      configMetni: config(
        app: "'ca-app-pub-3940256099942544~1458002511'",
        unit: "'ca-app-pub-3940256099942544/2934735716'",
      ),
    );
    final eksikler = checkRelease(kok).map((i) => i.what).join('\n');
    expect(eksikler, contains('AdMob iOS App ID'));
    expect(eksikler, contains('AdMob banner'));
  });

  test('Info.plist ile ReleaseConfig farklıysa yakalanıyor', () {
    doluProje();
    yaz(
      'ios/Runner/Info.plist',
      '<dict><key>GADApplicationIdentifier</key>'
          '<string>ca-app-pub-1234567890123456~1111111111</string>'
          '<string>$tersKimlik</string></dict>',
    );
    expect(
      checkRelease(kok).single.what,
      contains('ReleaseConfig ile aynı değil'),
    );
  });

  test('geçersiz e-posta ve yer tutucu anahtar yakalanıyor', () {
    doluProje(
      configMetni: config(rc: 'placeholder', email: "'destek-at-nilu'"),
    );
    final eksikler = checkRelease(kok).map((i) => i.what).join('\n');
    expect(eksikler, contains('RevenueCat'));
    expect(eksikler, contains('Destek e-postası'));
  });

  group('hesapla giriş', () {
    test('Google dönüş adresi hâlâ yer tutucuysa yakalanıyor', () {
      doluProje();
      yaz(
        'ios/Runner/Info.plist',
        '<dict><key>GADApplicationIdentifier</key><string>$appId</string>'
            '<string>com.googleusercontent.apps.YER-TUTUCU</string></dict>',
      );
      final eksik = checkRelease(kok).single;
      expect(eksik.what, contains('Google ile giriş'));
      expect(eksik.how, contains(tersKimlik));
    });

    test('kodlanmış uygulama kimliği de geçerli dönüş adresi', () {
      doluProje();
      yaz(
        'ios/Runner/Info.plist',
        '<dict><key>GADApplicationIdentifier</key><string>$appId</string>'
            '<string>app-1-123-ios-abc</string></dict>',
      );
      expect(checkRelease(kok), isEmpty);
    });

    test('Apple ile giriş yetkisi yoksa yakalanıyor', () {
      doluProje();
      yaz('ios/Runner/Runner.entitlements', '<dict></dict>');
      expect(checkRelease(kok).single.what, contains('Apple ile giriş'));
    });

    test('bugünkü proje: yetki var, dönüş adresi hesap bekliyor', () {
      final eksikler = checkRelease(Directory.current).map((i) => i.what);
      expect(eksikler, isNot(contains(contains('Apple ile giriş'))));
    });
  });

  group('Android', () {
    const androidApp = 'ca-app-pub-1234567890123456~5555555555';
    const androidBanner = 'ca-app-pub-1234567890123456/4444444444';

    String androidConfig({String app = androidApp}) => config().replaceFirst(
      "  static const String placeholder = 'YER_TUTUCU';",
      "  static const String revenueCatGoogleApiKey = "
          "'goog_AbCdEfGhIjKlMnOpQrStUvWx';\n"
          "  static const String admobAppIdAndroid = '$app';\n"
          "  static const String admobBannerUnitAndroid = '$androidBanner';\n"
          "  static const String placeholder = 'YER_TUTUCU';",
    );

    String googleServices({
      String paket = 'com.furkan.rcperiodtracker',
      bool sha = true,
    }) {
      final imzali = sha
          ? ', {"client_id": "y", "client_type": 1, "android_info": '
                '{"package_name": "$paket", "certificate_hash": "abc"}}'
          : '';
      return '{"client": [{"client_info": {"android_client_info": '
          '{"package_name": "$paket"}}, "oauth_client": '
          '[{"client_id": "x", "client_type": 3}$imzali]}]}';
    }

    String manifest(String appId) =>
        '<meta-data\n'
        '    android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
        '    android:value="$appId" />';

    void doluAndroid({String app = androidApp, String? manifestAppId}) {
      doluProje(configMetni: androidConfig(app: app));
      yaz(
        'android/app/src/main/AndroidManifest.xml',
        manifest(manifestAppId ?? app),
      );
      yaz('android/app/google-services.json', googleServices());
      yaz('android/key.properties', 'storePassword=x');
    }

    test('her şey doluysa eksik yok', () {
      doluAndroid();
      expect(checkRelease(kok), isEmpty);
    });

    test('android/ yoksa Android denetlenmiyor', () {
      doluProje();
      expect(checkRelease(kok), isEmpty);
    });

    test('manifestteki AdMob kimliği farklıysa yakalanıyor', () {
      doluAndroid(manifestAppId: 'ca-app-pub-1234567890123456~1111111111');
      expect(
        checkRelease(kok).single.what,
        contains('AndroidManifest AdMob APPLICATION_ID'),
      );
    });

    test('Google örnek kimliğiyle yayına çıkılmıyor', () {
      doluAndroid(app: 'ca-app-pub-3940256099942544~3347511713');
      final eksikler = checkRelease(kok).map((i) => i.what).join('\n');
      expect(eksikler, contains('AdMob Android App ID'));
      expect(eksikler, contains('örnek kimliği'));
    });

    test('imza parmak izi yoksa Google ile giriş uyarısı', () {
      doluAndroid();
      yaz('android/app/google-services.json', googleServices(sha: false));
      expect(checkRelease(kok).single.what, contains('parmak izi'));
    });

    test('başka paketin google-services.json dosyası yakalanıyor', () {
      doluAndroid();
      yaz(
        'android/app/google-services.json',
        googleServices(paket: 'com.example.app'),
      );
      expect(checkRelease(kok).single.what, contains('google-services.json'));
    });

    test('yayın imzası yoksa yakalanıyor', () {
      doluAndroid();
      File('${kok.path}/android/key.properties').deleteSync();
      expect(checkRelease(kok).single.what, contains('key.properties'));
    });

    test('bugünkü proje: Android hesapları da bekleniyor', () {
      final eksikler = checkRelease(Directory.current).map((i) => i.what);
      expect(eksikler, contains(contains('RevenueCat Google Play')));
      expect(eksikler, contains(contains('google-services.json')));
    });

    test('yayında Android birimi girildiyse o kullanılıyor', () {
      expect(
        AdsDatasource.unitFor(
          release: true,
          ios: false,
          configured: androidBanner,
        ),
        androidBanner,
      );
      expect(
        AdsDatasource.unitFor(
          release: true,
          ios: false,
          configured: 'YER_TUTUCU',
        ),
        isNull,
      );
    });
  });

  group('reklam birimi', () {
    test('geliştirmede her zaman Google test birimi', () {
      // Kendi reklamına tıklamak AdMob politikasına aykırı.
      expect(
        AdsDatasource.unitFor(release: false, ios: true, configured: banner),
        contains('3940256099942544'),
      );
    });

    test('yayında birim girilmemişse reklam yok (test reklamı değil)', () {
      expect(
        AdsDatasource.unitFor(
          release: true,
          ios: true,
          configured: 'YER_TUTUCU',
        ),
        isNull,
      );
      expect(
        AdsDatasource.unitFor(release: true, ios: true, configured: banner),
        banner,
      );
    });
  });
}
