/// Yayından önce doldurulacak hesap bilgileri — hepsi burada.
///
/// Önceden RevenueCat anahtarı abonelik servisinde, reklam kimlikleri reklam
/// kaynağında, destek adresi `AppInfo`'da duruyordu; hangisinin eksik
/// kaldığını görmek için dosya dosya aramak gerekiyordu.
///
/// `dart run tool/check_release.dart` bunları (ve Info.plist, Firebase
/// yapılandırması, site adresi gibi koddan dışarıdaki parçaları) denetler;
/// yer tutucu kalırsa başarısız olur. Nereden alınacakları: SETUP_KEYS.md.
///
/// Yer tutucu kaldıkça uygulama yine çalışıyor ama ilgili özellik kapalı:
/// abonelik "şu an kullanılamıyor" diyor, release derlemede reklam alanı
/// hiç çizilmiyor (Google'ın test reklamları yayına çıkmamalı), politika ve
/// Şartlar e-posta yerine köşeli parantezli bir yer tutucu gösteriyor.
class ReleaseConfig {
  const ReleaseConfig._();

  /// RevenueCat → Project settings → API keys → App Store için **public**
  /// SDK anahtarı (`appl_` ile başlar). Gizli değil; uygulamaya gömülür.
  static const String revenueCatAppleApiKey = placeholder;

  /// AdMob → Apps → (iOS uygulaması) → App ID: `ca-app-pub-…~…`.
  ///
  /// `ios/Runner/Info.plist` içindeki `GADApplicationIdentifier` ile aynı
  /// olmalı (denetleyici karşılaştırıyor). app-ads.txt'deki yayıncı
  /// kimliği de bundan türetiliyor.
  static const String admobAppIdIos = placeholder;

  /// AdMob → Ad units → Banner: `ca-app-pub-…/…`.
  static const String admobBannerUnitIos = placeholder;

  /// RevenueCat → Project settings → API keys → Google Play için **public**
  /// SDK anahtarı (`goog_` ile başlar).
  static const String revenueCatGoogleApiKey = placeholder;

  /// AdMob → Apps → (Android uygulaması) → App ID. AdMob'da iOS ve Android
  /// ayrı uygulamalar; kimlikler farklı.
  ///
  /// `android/app/src/main/AndroidManifest.xml` içindeki
  /// `com.google.android.gms.ads.APPLICATION_ID` ile aynı olmalı
  /// (denetleyici karşılaştırıyor).
  static const String admobAppIdAndroid = placeholder;

  /// AdMob → Ad units → (Android uygulaması) → Banner.
  static const String admobBannerUnitAndroid = placeholder;

  /// Kullanıcının haklarını kullanacağı ve soru soracağı adres.
  ///
  /// Tür bilerek boş olabilir: `null`'ken uygulama ve site yer tutucu
  /// gösteriyor, denetleyici eksik sayıyor.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const String? supportEmail = 'niluapp@proton.me';

  /// Doldurulmamış alanın değeri.
  static const String placeholder = 'YER_TUTUCU';

  /// [value] gerçek bir değerle doldurulmuş mu?
  static bool isSet(String? value) =>
      value != null && value.trim().isNotEmpty && value != placeholder;
}
