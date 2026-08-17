# 📄 RCApp - Period Tracker Mimari Dökümanı

## Sisteme Genel Bakış
RCApp, üretim standartlarında (production-grade), ölçeklenebilir ve sürdürülebilir bir adet döngüsü takip (period tracking) mobil uygulamasıdır. Clean Architecture prensiplerine dayanır, modüler bir yapıya sahiptir. Gelecekte giyilebilir cihazlar (wearables), yapay zeka (AI) tahminlemeleri ve bulut senkronizasyonu (cloud sync) gibi özelliklerin kolayca eklenebileceği bir vizyonla tasarlanmıştır.

## Teknoloji Yığını (Technology Stack)
- **Framework:** Flutter (Dart)
- **Mimari Desen:** Clean Architecture & MVVM
- **Durum Yönetimi (State Management):** MVVM uyumlu state yönetimi (ör. Riverpod veya Provider)
- **Navigasyon:** Taslağa uygun güçlü navigasyon paketi (go_router)
- **Lokalizasyon:** flutter_localizations ve custom JSON tabanlı sistem
- **Tasarım Kaynağı:** Stitch (Asset'ler ve layout referansları)
- **Yerel Depolama:** Şifrelenmiş depolama

## Katmanlı Mimari Açıklaması (Layered Architecture)
Uygulama, kodun sürdürülebilirliğini sağlamak amacıyla ana katmanlara ayrılmıştır:
1. **Domain Katmanı:** Uygulamanın merkezidir. İş kurallarını, Use Case'leri ve kısıtlamaları (Entity) barındırır. Hiçbir dış bağımlılığı yoktur.
2. **Data Katmanı:** Veri kaynakları (API, yerel veritabanı) ve Repository implementasyonlarını içerir.
3. **Presentation Katmanı:** Kullanıcı arayüzü (UI) ve State Management kodlarını içerir. Stitch'ten alınan tasarımlar burada hayat bulur.

## Modül Sınırları (Module Boundaries)
Her özellik (feature), kendi içerisinde bağımsız bir modül gibi davranır (örn: Home, Calendar, Log Entry). Ortak kullanılan özellikler (tema, core utils) `core` ve `design_system` modüllerinde toplanır. Özellik modülleri, yalnızca `domain` üzerinden haberleşir.

## Durum Yönetimi Yaklaşımı (State Management)
- **MVVM / Clean Architecture:** UI (View), doğrudan veri kaynaklarıyla konuşmaz. View, ViewModel üzerinden State'i dinler.
- **Veri Akışı (Data Flow):** UI (Action) -> ViewModel -> Use Case (Domain) -> Repository (Data) -> Data Source.
- **Bağımlılık Yönü (Dependency Direction):** Dış katmanlardan her zaman içeriye (Domain'e) doğru tek yönlüdür.

## Navigasyon Yapısı (Navigation)
Uygulama genelinde merkezi bir yönlendirme sistemi bulunur. Ana rotalar şunlardır:
- `/onboarding` (Karşılama ve Tanıtım)
- `/home` (Ana Ekran)
- `/calendar` (Takvim)
- `/log-entry` (Veri/Log Girişi)
- `/insights` (İstatistikler ve Analizler)
- `/profile` (Profil)
- `/settings` (Ayarlar)
- `/premium` (Premium Özelliklere Geçiş)

## Lokalizasyon Stratejisi (Localization Strategy)
Çoklu dil desteği (Türkçe, İngilizce, Almanca, Fransızca, İspanyolca, Portekizce) için JSON tabanlı bir altyapı kullanılmaktadır.
- Kesinlikle kod içine gömülü (hardcoded) metin (string) kullanılmaz.
- Her yeni UI metni için tüm dil dosyalarına (tr.json, en.json vb.) bir anahtar (key) eklenir.

## Asset Yönetimi (Stitch Yüklemeleri)
Tasarım ekibinden (Stitch) gelen varlıklar ve düzen referansları doğrudan `assets/` klasörüne aktarılır. `design_system` klasöründe bu assetleri ve standart renk/tipografi setini yöneten bir tema bileşeni konumlandırılır.

## Ölçeklenebilirlik (Scalability)
- **Modüler Yapı:** Özelliklerin birbirinden ayrılması sayesinde takım büyüdükçe farklı geliştiricilerin çakışma yaşamadan çalışmasına olanak tanır.
- **Genişletilebilirlik:** AI tahmin modeli veya WearOS/watchOS eklentileri için veri ve domain katmanları hazır tutulmuştur.

## Gizlilik ve Güvenlik (Privacy & Security)
Adet döngüsü verileri son derece hassas kişisel sağlık verileridir (Hassas Veri / Sensitive Data).
- **Yerel Depolama:** Kullanıcı verileri cihazda mutlaka şifrelenerek saklanacaktır (Encrypted Local Storage).
- **İzin Yönetimi (Permissions):** Sağlık verilerine (örneğin Apple HealthKit) erişimde şeffaf izin yönetimi uygulanır.
- **Gizlilik İlkesi:** Veriler varsayılan olarak cihazda kalır, bulut senkronizasyonu eklenecekse de uçtan uca şifreli tasarlanacaktır.
