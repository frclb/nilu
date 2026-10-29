import 'release_config.dart';

/// Uygulamanın görünen adı.
///
/// Tek kaynak: `MaterialApp.title`, onboarding başlığı ve mağaza adı aynı
/// yerden okunur. Onboarding'in son ekranında "FLOWELL" yazıyordu — eski bir
/// isimden kalmış tek bir sabit. Kullanıcı kurulumu bitirirken ikonunda
/// yazandan başka bir marka görüyordu.
///
/// Değiştirirken birlikte güncellenmesi gerekenler:
/// * `ios/Runner/Info.plist` → `CFBundleDisplayName`, `CFBundleName`
/// * App Store listeleme adı — [STORE_LISTING.md] içinde, dil başına ayrı
class AppInfo {
  const AppInfo._();

  static const String displayName = 'Nilu';

  /// Kullanıcının haklarını kullanacağı ve soru soracağı adres.
  ///
  /// Gizlilik politikası (9. bölüm) ve Şartlar (12. bölüm) bu adresi
  /// gösteriyor. Önceden altı dilde on iki ayrı yerde köşeli parantezli bir
  /// yer tutucu vardı; adres gelince hepsini tek tek değiştirmek gerekecekti.
  ///
  /// `null` iken metinde dilin yer tutucusu görünür (`legal_email_placeholder`).
  /// Değer [ReleaseConfig.supportEmail]'de; **yayından önce doldurulmalı**.
  static const String? supportEmail = ReleaseConfig.supportEmail;

  /// Partner davet bağlantısının adresi; kod `#`'ten sonra.
  ///
  /// Alan adının kökünde Apple'ın doğrulama dosyası var
  /// (`/.well-known/apple-app-site-association`, kullanıcı sitesi deposu
  /// frclb/frclb.github.io): uygulama yüklüyse bağlantı doğrudan uygulamayı
  /// açıyor, değilse sitedeki sayfa açılıyor (`tool/build_site.dart`). Kod
  /// `#`'ten sonra durduğu için sunucuya gönderilmiyor.
  ///
  /// Değişirse birlikte: `ios/Runner/Runner.entitlements` (`applinks:`),
  /// doğrulama dosyası ve `site/site.json`.
  static const String inviteLinkBase = 'https://frclb.github.io/nilu/p/';

  /// Sitedeki sayfanın "Nilu'da aç" düğmesinin şeması (`nilu://p#KOD`).
  /// Aynı alan adındaki sayfadan bağlantıya dokunmak uygulamayı açmıyor.
  static const String linkScheme = 'nilu';
}
