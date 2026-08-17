# RCApp — Period Tracker

Adet döngüsü takip uygulaması (Flutter). Standart döngü takibinin yanında bir
**partner modu** sunar: kullanıcı QR kod ile eşleştiği partnerine duygusal ve
fiziksel yakınlık durumunu paylaşır, partner kendi arayüzünde bunu görüp öneri
alır.

## Gereksinimler

- Flutter (stable), Dart SDK `^3.10.7`
- iOS derlemesi için Xcode, Android için JDK 17

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
| Android release | `flutter build appbundle --release` |

CI (`.github/workflows/ci.yml`) her push ve PR'da biçim, analiz, test ve
lokalizasyon denetimini çalıştırır.

## Mimari

```
lib/
├── core/          # Firebase bootstrap, go_router yapılandırması, navigasyon
├── data/          # Repository'ler (yerel depolama) + uzak datasource'lar
├── domain/        # Modeller, saf iş mantığı servisleri, ViewModel'lar
├── design_system/ # AppColors + AppTheme (light/dark)
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

## Release imzalama (Android)

`android/key.properties.example` dosyasını `android/key.properties` olarak
kopyalayıp doldurun. Dosya yoksa release derlemesi debug anahtarıyla imzalanır
(yerel test için); mağaza yüklemesinde dosya zorunludur.

## Firestore güvenlik kuralları

`firestore.rules` deploy edilmelidir:

```bash
firebase deploy --only firestore:rules
```
