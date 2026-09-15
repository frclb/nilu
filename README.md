# RCApp — Period Tracker

Adet döngüsü takip uygulaması (Flutter). Standart döngü takibinin yanında bir
**partner modu** sunar: kullanıcı QR kod ile eşleştiği partnerine duygusal ve
fiziksel yakınlık durumunu paylaşır, partner kendi arayüzünde bunu görüp öneri
alır.

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
veriler cihazda kalır, uzak özellikler (partner senkronizasyonu, push bildirim)
sessizce devre dışı olur. Uzak özellikleri açmak için:

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
| Biçimlendirme | `dart format lib test` |
| Lokalizasyon denetimi | `dart run tool/check_localization.dart` |
| iOS release | `flutter build ios --release` |
| Cihaza kur | `flutter run -d "<cihaz>"` |

`flutter install` **derlemez**, hazır paket bekler; kendi başına çalıştırmak
eski sürümü kaldırıp yerine bir şey koymaz. Cihaza kurmak için `flutter run`
kullanın ya da önce `flutter build ios --debug` çalıştırın.

CI (`.github/workflows/ci.yml`) her push ve PR'da biçim, analiz, test ve
lokalizasyon denetimini çalıştırır.

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

Debug ile Release **farklı yetki dosyaları** kullanıyor:

| Yapılandırma | Dosya | HealthKit + App Groups |
|---|---|---|
| Debug | `ios/Runner/RunnerDebug.entitlements` | yok |
| Release / Profile | `ios/Runner/Runner.entitlements` | var |

Sebebi: ücretsiz ("kişisel") Apple takımları bu iki yetkiyi vermiyor ve Xcode
profil üretemeyip derlemeyi durduruyor. Debug'ı yetkisiz bırakmak ücretsiz
hesapla cihaza kurmayı mümkün kılıyor; mağaza derlemesi tam yetkilerle
çıkıyor. Bu yapılandırmada sağlık senkronizasyonu ve ana ekran widget'ı
çalışmaz.

Ücretli Apple Developer Program üyeliği alındığında Debug'ın
`CODE_SIGN_ENTITLEMENTS` ayarı asıl dosyaya döndürülüp `*Debug.entitlements`
dosyaları silinebilir.

## Yazı tipleri

Inter ve Fraunces `assets/fonts/` altında **pakete gömülü** (bkz. pubspec
`fonts:`). Önce `google_fonts` ile çalışma anında indiriliyorlardı; ilk
açılışta ağ yavaşsa ekran sistem yazı tipiyle açılıp sonra değişiyordu.

## Firestore güvenlik kuralları

`firestore.rules` deploy edilmelidir:

```bash
firebase deploy --only firestore:rules
```
