# Nilu

Regl, gebelik ve lohusalık takibi (Flutter, iOS). Sağlık verisi **cihazda**
kalır ve Anahtar Zinciri'nde şifreli durur; analiz SDK'sı yok, hesap zorunlu
değil. İsteğe bağlı Apple/Google hesabıyla bulut eşitleme var: yalnızca açık
rızayla açılıyor, kapatınca buluttaki kopya siliniyor (`lib/domain/services/
sync_engine.dart`). Tahminler kullanıcının kendi kayıtlarından, açıklanabilir
kurallarla hesaplanır (yapay zekâ yok).

Öne çıkanlar: dört kurulum yolu (döngü, bebek istiyorum, gebelik, yeni doğum),
tahmin aralığı ve "nasıl hesaplandı" ekranı, ayarlanabilir hatırlatıcılar
(kaç gün önce, saat, gecikme), gebelik testi kaydı, geçmiş reglleri toplu
ekleme, Türkiye izlem takvimiyle gebelik/lohusalık bakımı, hekim özeti,
uygulama kilidi, gizli bildirim, sade ana ekran simgesi, parolalı yedek, altı
dil (tr, en, de, es, fr, pt-BR) ve isteğe bağlı partner modu (yalnızca
kullanıcının açıkça paylaştığı durum; döngü verisi gitmez).

Belgeler: kurulum anahtarları [SETUP_KEYS.md](SETUP_KEYS.md), yükleme
[SUBMIT.md](SUBMIT.md), mağaza [STORE_CHECKLIST.md](STORE_CHECKLIST.md) ve
[STORE_LISTING.md](STORE_LISTING.md), test [TESTING.md](TESTING.md).

## Gereksinimler

- Flutter (stable), Dart SDK `^3.10.7`
- Xcode

Uygulama **yalnızca iOS** için geliştiriliyor. Android, web ve masaüstü
platform klasörleri kaldırıldı; gerekirse
`flutter create --platforms=android .` ile yeniden üretilebilir.

## Kurulum

```bash
flutter pub get
```

Uygulama **Firebase yapılandırması olmadan da çalışır** (yerel-only mod): tüm
veriler cihazda kalır, yalnızca partner modu "şu an kullanılamıyor" der.
Partner modunu açmak için:

```bash
flutterfire configure
```

Bu komut `lib/firebase_options.dart` ile platform yapılandırma dosyalarını
üretir; `FirebaseConfig.init()` bunları bulduğunda `isAvailable` true olur ve
datasource'lar canlanır. Yapılandırma dosyaları `.gitignore`'dadır.

## Komutlar

| İş | Komut |
|---|---|
| Bağımlılıklar | `flutter pub get` |
| Çalıştır | `flutter run` |
| Statik analiz | `flutter analyze` |
| Testler | `flutter test` |
| Biçimlendirme | `dart format lib test tool integration_test` |
| Uçtan uca (ayrı simülatörde) | `flutter test integration_test -d "Nilu E2E"` |
| Firestore kuralları | `cd firebase_tests && npm ci && npm test` |
| Yayın denetimi | `dart run tool/check_release.dart` |
| Lokalizasyon denetimi | `dart run tool/check_localization.dart` |
| iOS release | `flutter build ios --release` |
| Cihaza kur | `flutter run -d "<cihaz>"` |

`flutter install` **derlemez**, hazır paket bekler; kendi başına çalıştırmak
eski sürümü kaldırıp yerine bir şey koymaz. Cihaza kurmak için `flutter run`
kullanın ya da önce `flutter build ios --debug` çalıştırın.

CI (`.github/workflows/ci.yml`) her push ve PR'da biçim, analiz, test,
lokalizasyon ve mağaza metni denetimini, site üretimini ve Firestore kural
testlerini çalıştırır. Site `.github/workflows/pages.yml` ile GitHub Pages'e
yayınlanır.

## Mimari

```
lib/
├── core/          # Firebase bootstrap, go_router yapılandırması, navigasyon
├── data/          # Repository'ler (yerel depolama) + uzak datasource'lar
├── domain/        # Modeller, saf iş mantığı servisleri, ViewModel'lar
├── design_system/ # AppTokens (rol renkleri) + AppTheme (light/dark)
├── localization/  # JSON tabanlı i18n
└── presentation/  # Feature-first ekranlar ve widget'lar
```

Veri akışı: `Widget → ViewModel (ChangeNotifier) → Service → Repository → depolama`.
Durum yönetimi `provider`; ViewModel'lar `main.dart`'ta kayıtlı, `IntimacyViewModel`
ve `PartnerViewModel` kimlik bilgisi için `UserViewModel`'a `ProxyProvider` ile bağlı.

Ayrıntı için [architecture.md](architecture.md), yeni ekran ekleme akışı için
[ui_workflow.md](ui_workflow.md).

### Depolama

Sağlık verileri (regl kayıtları, günlük semptom/ruh hali logları, yakınlık
seçimleri, döngü ayarları) **şifreli olarak** saklanır — bkz.
`lib/data/local/secure_store.dart`. Hassas olmayan tercihler (onboarding
tamamlandı bayrağı, bildirim açık/kapalı) düz `SharedPreferences`'ta kalır.

## Lokalizasyon

Metinler `lib/localization/<dil>.json` dosyalarında tutulur, kodda
`context.tr('anahtar')` ile okunur. **Hiçbir kullanıcıya görünen metin koda
gömülmez.**

Referans dil `tr`, fallback dil `en`: bir anahtar aktif dilde yoksa otomatik
olarak İngilizceye düşülür, ham anahtar kodu ekrana çıkmaz. Yeni bir anahtar
eklerken en azından `tr.json` ve `en.json` güncellenmelidir — CI bunu denetler.

## İmzalama ve yetkiler

Bütün yapılandırmalar aynı yetki dosyalarını kullanıyor:
`ios/Runner/Runner.entitlements` (HealthKit, App Groups, Apple ile giriş) ve
`ios/CycleWidget/CycleWidget.entitlements` (App Groups). Takım
`V8MCMH5GJ7` (Hürkan ÇELEBİ, bireysel üyelik), otomatik imzalama.

Üyelikten önce Debug yetkisiz ayrı dosyalar kullanıyordu: ücretsiz
("kişisel") takımlar HealthKit ve App Groups vermiyor. Üyelik gelince
(2026-10-27) o dosyalar kaldırıldı; cihazdaki geliştirme sürümünde de sağlık
senkronizasyonu, widget ve Apple ile giriş çalışıyor.

## Ekran uyumu

Düzen cihaz adına göre değil gelen genişliğe göre kararını verir
([app_layout.dart](lib/design_system/app_layout.dart)):

| Genişlik | Düzen |
|---|---|
| < 600 pt | Tek sütun, kenardan kenara, alt menü |
| 600–899 pt | 600 pt'de ortalanmış sütun, alt menü |
| ≥ 900 pt | Ortalanmış sütun + yan menü ([side_nav_rail.dart](lib/presentation/home/widgets/side_nav_rail.dart)) |

Kütüphane ve Analiz `AppColumns` ile 700 pt'den sonra iki sütuna açılır ve
1000 pt'ye kadar genişler. Eşik içerikten geliyor: kütüphane kartı 96 pt
görsel + başlık taşıyor, kart başına ~320 pt gerekiyor.

iPadOS pencereleri serbestçe boyutlandırıyor ve katlanabilir telefonlar
çalışma anında genişlik değiştiriyor; "iPad mi?" sorusunun sabit bir cevabı
yok, "şu an kaç pt?" sorusunun var.

`AppContentWidth` daraltmayı `Padding` ile yapar, `Center`/`Align` ile değil:
ikisi de dikey kısıtı gevşetip gövdesi `Stack` olan ekranları büzüyor.

## Yazı tipleri

Inter ve Fraunces `assets/fonts/` altında **pakete gömülü** (bkz. pubspec
`fonts:`). Önce `google_fonts` ile çalışma anında indiriliyorlardı; ilk
açılışta ağ yavaşsa ekran sistem yazı tipiyle açılıp sonra değişiyordu.

## Firestore güvenlik kuralları

`firestore.rules` deploy edilmelidir:

```bash
firebase deploy --only firestore:rules
```
