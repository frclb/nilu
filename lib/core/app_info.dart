/// Uygulamanın görünen adı.
///
/// Tek kaynak: `MaterialApp.title`, onboarding başlığı ve mağaza adı aynı
/// yerden okunur. Onboarding'in son ekranında "FLOWELL" yazıyordu — eski bir
/// isimden kalmış tek bir sabit. Kullanıcı kurulumu bitirirken ikonunda
/// yazandan başka bir marka görüyordu.
///
/// Değiştirirken birlikte güncellenmesi gerekenler:
/// * `ios/Runner/Info.plist` → `CFBundleDisplayName`, `CFBundleName`
/// * `android/app/src/main/AndroidManifest.xml` → `android:label`
/// * Mağaza listeleme adı
class AppInfo {
  const AppInfo._();

  static const String displayName = 'Period Tracker';
}
