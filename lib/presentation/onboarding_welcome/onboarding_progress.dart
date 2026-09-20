/// Onboarding ilerleme göstergesinin ortak değerleri.
///
/// Adım sayısı üç ekranda ayrı ayrı yazılıydı (`List.generate(6, ...)`).
/// Araya bir ekran eklendiğinde üçünü birden güncellemek gerekiyordu;
/// biri unutulsaydı kullanıcı adım sayısı değişen bir gösterge görürdü.
library;

/// Karşılama sayfalarından sonra gelen soru ekranları dahil, toplam adım.
const int onboardingStepCount = 7;

/// Geçilmemiş noktanın saydamlığı.
///
/// Eskiden her ekranda `(isDark ? 0.4 : 0.2 * 255).toInt()` yazıyordu.
/// Çarpma ternary'den önce bağlandığı için koyu temada değer `0.4.toInt()`
/// yani **0** oluyordu: geçilmemiş noktalar tamamen görünmezdi, kullanıcı
/// tek bir nokta görüp kaç adım kaldığını bilemiyordu. Parantez düzeltildi.
int onboardingIdleDotAlpha(bool isDark) => ((isDark ? 0.4 : 0.2) * 255).round();

/// Çarktaki seçim şeridinin saydamlığı — aynı hata oradaydı, seçili değerin
/// arkasındaki vurgu koyu temada hiç çizilmiyordu.
int onboardingHighlightAlpha(bool isDark) =>
    ((isDark ? 0.2 : 0.1) * 255).round();
