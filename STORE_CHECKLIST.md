# App Store Yayın Kontrol Listesi

Uygulama **yalnızca iOS** için çıkıyor; `android/`, `linux/`, `macos/`, `web/`
ve `windows/` klasörleri depodan kaldırıldı. Bu liste App Store yüklemesi için
gerekenleri kapsar. ✅ = kodda hazır, ⬜ = sizin yapmanız gerekiyor (hesap, sır
veya tasarım gerektiriyor).

> Bir gün başka bir platforma dönülecekse klasör `flutter create --platforms=android .`
> ile yeniden üretilir; kod tarafında platforma özel bir şey yok.

---

## 1. Uygulama kimliği

| Alan | Değer | Durum |
|---|---|---|
| Bundle ID | `com.furkan.rcperiodtracker` | ✅ |
| Görünen ad | Period Tracker | ✅ `CFBundleDisplayName` + `CFBundleName` |
| Sürüm | `1.0.0` (build 1) | ✅ [pubspec.yaml:19](pubspec.yaml) |
| Minimum iOS | 15.0 (CycleWidget hedefi 17.0) | ✅ |
| Cihaz ailesi | iPhone **ve** iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) | ✅ ikisi de destekleniyor |
| Yön | iPhone dikey; iPad dikey + yatay | ✅ |
| Desteklenen diller | tr, en, de, es, fr, pt | ✅ altısı da eşit (`dart run tool/check_localization.dart`) |
| Şifreleme beyanı | `ITSAppUsesNonExemptEncryption` = `false` | ✅ — yükleme sırasında soru sorulmaz |

> iOS deployment target 13.0'dı ama Podfile ve Firebase 15.0 istiyor — düzeltildi.
> Uyumsuz kalsaydı App Store doğrulaması reddederdi.

**Sürüm artırma:** `pubspec.yaml` içindeki `version: 1.0.0+1` satırını
değiştirin. Nokta öncesi mağazada görünen sürüm, `+` sonrası build numarası.
Her yüklemede build numarası artmalıdır.

---

## 2. İmzalama ve yetkiler

**Apple Developer Program üyeliği ($99/yıl)** ⬜
Mağazaya yükleme, HealthKit, App Groups ve push bildirim bunsuz çalışmaz.
Üyelik alındıktan sonra Xcode → Runner → Signing & Capabilities → Team seçin.
Otomatik imzalama yeterlidir. **CycleWidget hedefinde de aynı takımı seçin**
— ayrı bir hedef, kendi takımını istiyor.

**Yetkiler yapılandırmaya göre ayrılmıştır:**

| Yapılandırma | Dosya | HealthKit | App Groups |
|---|---|---|---|
| Debug | `Runner/RunnerDebug.entitlements` | yok | yok |
| Release / Profile | `Runner/Runner.entitlements` | var | var |

Ücretsiz ("kişisel") Apple takımları HealthKit ve App Groups yetkisini
vermiyor; Xcode profil üretemeyip derlemeyi durduruyordu:

```
Personal development teams … do not support the HealthKit Access
(Verifiable Health Records) capability.
```

Debug bu yetkileri içermediği için uygulama ücretsiz hesapla telefona
kurulabiliyor; mağaza derlemesi (Release) tam yetkilerle çıkıyor. Debug'da
**sağlık senkronizasyonu ve ana ekran widget'ı çalışmaz** — bunları test
etmek üyelik gerektirir. Aynısı `CycleWidget/CycleWidgetDebug.entitlements`
için de geçerli.

Ücretli üyelik alındığında bu ayrıma gerek kalmaz: Debug'ın
`CODE_SIGN_ENTITLEMENTS` ayarı `Runner/Runner.entitlements` yapılıp
`*Debug.entitlements` dosyaları silinebilir.

---

## 3. Görseller

**App ikonu** ✅ — marka lotusu üretildi ve tüm iOS boyutlarına uygulandı
(21 boyut, 1024 alfasız).

İkonu değiştirmek isterseniz:
```bash
python3 tool/generate_icon.py && dart run flutter_launcher_icons
```
Kendi tasarımınızı kullanacaksanız `assets/icon/app_icon.png` dosyasını
(1024×1024, şeffaflıksız) değiştirip yalnızca ikinci komutu çalıştırın.

> `flutter_launcher_icons` yapılandırmasındaki Android anahtarları kaldırıldı;
> `android/` yokken komut AndroidManifest.xml arayıp çöküyor ve iOS
> ikonlarına hiç sıra gelmiyordu.

**Ekran görüntüleri** ⬜ — App Store Connect formunda sizden isteniyor.

Uygulama hem iPhone hem iPad'i hedefliyor, dolayısıyla App Store Connect
**her ikisi için de** ekran görüntüsü ister ve inceleme uygulamayı iPad'de de
açar. Düzen iki tarafta da doğrulandı (bkz. "Ekran uyumu" bölümü).

Ekran görüntülerini [TESTING.md](TESTING.md)'deki simülatör akışıyla
alabilirsiniz. Her boyut için 3–10 adet istenir; App Store Connect o an hangi
cihaz boyutunu zorunlu tuttuğunu formda gösterir. iPad görüntülerini yatayda
almak yan menüyü gösterdiği için daha iyi tanıtır.

---

## Ekran uyumu

Uygulama tek bir telefon genişliği varsayılarak yazılmıştı; iPad'de kartlar
1032 pt'ye kadar geriliyordu. Üç şey eklendi:

| Genişlik | Ne olur |
|---|---|
| < 600 pt | Tek sütun, kenardan kenara, alt menü — bütün iPhone'lar |
| 600–899 pt | Sütun 600 pt'de ortalanır, alt menü kalır — iPad mini, katlanabilir açıkken |
| ≥ 900 pt | Ortalanmış sütun + **yan menü** — iPad 13" portre, bütün iPad'ler yatay |

Kütüphane ve Analiz ayrıca **700 pt'den sonra iki sütuna** açılıyor: makale
kartları ızgaraya, iki analiz kartı yan yana geçiyor. Bu ikisi 1000 pt'ye
kadar genişleyebiliyor — 600 pt'lik tek sütun sınırına sıkıştırılsalardı her
sütun 280 pt'ye düşerdi.

Karar cihaz adına değil **gelen genişliğe** göre veriliyor: iPadOS 26
pencereleri serbestçe boyutlandırıyor ve katlanabilir telefon açılıp
kapandığında genişlik çalışma anında değişiyor.

`test/presentation/device_sizes_test.dart` uygulamayı on cihaz boyutunda
açıp taşma (`RenderFlex overflowed`) olmadığını doğruluyor — iPhone 16e'den
iPad 13" yataya, iPhone Duo'nun açık ve kapalı hâlleri dâhil.

> Testlerin metni gerçekçi ölçmesi için `test/flutter_test_config.dart`
> uygulamanın kendi yazı tiplerini yüklüyor. Yüklenmezse `flutter test` her
> karakteri aynı genişlikte kutu olarak çizen yedek yazı tipini kullanıyor ve
> cihazda rahat sığan başlıklar için "96 piksel taştı" diyor.

---

## 4. Gizlilik beyanları

App Store, hangi veriyi topladığınızı beyan etmenizi zorunlu tutar.
Aşağıdakiler **koddan çıkarılmıştır** — formu buna göre doldurun.

### Toplanan / işlenen veri

| Kategori | Alanlar | Nerede durur | Paylaşılır mı |
|---|---|---|---|
| Sağlık ve fitness | Regl tarihleri, semptomlar, ruh hâli, akış yoğunluğu, cinsel aktivite, döngü ayarları | Cihazda **şifreli** (`SecureStore`) | Hayır |
| Hassas kişisel | Yakınlık/cinsel istek seçimleri | Cihazda **şifreli** | Yalnızca kullanıcı açıkça eşleşirse partnerine |
| Kişisel bilgi | Ad, e-posta, doğum tarihi | Cihazda **şifreli** | Hayır |
| Tanımlayıcı | Anonim kullanıcı kimliği, partner kimliği | Cihaz + (Firebase açıksa) Firestore | Hayır |
| Cihaz kimliği | FCM push token | Firebase açıksa Firestore | Hayır |
| Satın alma | Abonelik durumu | RevenueCat açıksa | Hayır |

**Önemli:** Firebase yapılandırma dosyası eklenmediği sürece uygulama
**yerel-only** çalışır; hiçbir veri cihazdan çıkmaz. Firebase'i açtığınızda
yukarıdaki "Firestore" satırları geçerli olur ve beyanı güncellemelisiniz.

### Apple — App Privacy
- "Data Used to Track You": **Hayır** (reklamlar kişiselleştirilmiyor, ATT istenmiyor)
- "Data Linked to You": Health & Fitness, Sensitive Info, Contact Info,
  Identifiers, Purchases (Firebase açıksa)
- "Data Not Collected": Firebase kapalıyken hepsi

### Hesap silme ✅
Apple, hesap oluşturan uygulamalarda **uygulama içinden hesap silmeyi**
zorunlu tutar (App Store Review Guideline 5.1.1(v)).
Profil → Gizlilik → Hesabımı Sil; yerel veriyle birlikte Firestore'daki
profil, loglar ve yakınlık dokümanı da siliniyor, ardından kimliğin kendisi
kaldırılıyor. (Önceden yalnızca cihazdaki veri siliniyordu — bağlı partner
hesap silindikten sonra da veriyi okuyabiliyordu.)

### Şartlardaki hukuk seçimi ⬜ — **engelleyici**
Kullanım şartlarının 12. bölümü üç yer tutucu içeriyor ve bunlar bir
**karar**, doldurulacak boşluk değil:

- `[UYGULANACAK HUKUK]` — hangi ülkenin hukuku?
- `[YETKİLİ MAHKEME VE İCRA DAİRELERİ]` — uyuşmazlıklar nerede görülecek?
- `[E-POSTA ADRESİ]` — politikadakiyle aynı adres olmalı.

Bu seçim şirketin nerede kurulu olduğuna ve kullanıcıların nerede olduğuna
bağlı; bir avukata sorulması gereken kısım burası.

### Politikadaki iki boşluk ⬜ — **engelleyici**
Politikanın 9. bölümü iki yer tutucu içeriyor ve bunlar sizden başkası
tarafından doldurulamaz:

- `[E-POSTA ADRESİ]` — kullanıcı erişim, düzeltme, silme, taşınabilirlik
  ve itiraz haklarını buradan kullanacak. Adres olmadan bu haklar fiilen
  kullanılamaz.
- `[ŞİRKET VEYA KİŞİ ADI, ADRES]` — veri sorumlusu kim?

Altı dilde de aynı yer tutucular var (`privacy_policy_section9_content`).
Köşeli parantezler bilerek bırakıldı: ekranda gözle görülür duruyorlar.

### Gizlilik politikası URL'si ⬜
App Store **herkese açık bir URL** ister. Uygulama içindeki gizlilik metni
([privacy_policy_screen.dart](lib/presentation/legal/privacy_policy_screen.dart))
yeterli değildir. Metni bir web sayfasına koyup URL'i mağaza formuna girin.
Yayınlanan sürüm uygulama içindeki metinle **aynı** olmalı; ikisi ayrışırsa
hangisinin geçerli olduğu belirsizleşir.

### Gizlilik etiketleri ⬜
Politikanın 5. ve 6. bölümleri uygulamanın gerçekte kullandığı hizmetleri
sayıyor: Firebase, Apple ile Giriş, RevenueCat, Google AdMob. App Store
gizlilik etiketleri bunlarla tutarlı olmalı — özellikle reklam kimliği ve
kullanım verisi kalemleri. Partner paylaşımını "yakınlık durumu" olarak
beyan edin; döngü verisi cihazdan çıkmıyor.

---

## 5. Kategori ve içerik

- **Kategori:** Health & Fitness
- **Yaş sınırı:** 12+ — cinsel sağlık içeriği nedeniyle
- Uygulama tıbbi teşhis koymaz; bunu mağaza açıklamasına da yazın
  (kod tarafında `terms_section2_content` zaten belirtiyor)
- Sağlık içeriklerinin **uzman gözünden geçirilmesi** ⬜ — inceleme sağlık
  iddialarına dikkat ediyor

---

## 6. Yayın öncesi bağlanması gerekenler ⬜

| Ne | Neden gerekli | Nasıl |
|---|---|---|
| `GoogleService-Info.plist` | Partner senkronizasyonu ve push bildirim | `flutterfire configure` |
| Firestore kuralları | Veri güvenliği | `firebase deploy --only firestore:rules` |
| RevenueCat API anahtarı | Premium satın alma | [subscription_service.dart](lib/domain/services/subscription_service.dart) — şu an `appl_api_key_placeholder` |
| Gerçek AdMob kimlikleri | Reklam alanının dolması | `Info.plist` → `GADApplicationIdentifier` ve [ads_datasource.dart](lib/data/datasources/ads_datasource.dart) — şu an Google'ın test kimlikleri |

Bunlar bağlanmadan uygulama **çalışır ama** partner özelliği yerel kalır,
premium ekranı satın alma yapmaz, reklam alanı boş görünür. Yapılandırılmamış
SDK'lara istek gitmiyor: RevenueCat anahtarsızken çağrı yapılsa süreç
`fatalError` ile çöküyordu, bu yüzden altı giriş noktası da korumalı
(`test/domain/services/subscription_guard_test.dart`).

---

## 7. Derleme ve yükleme

**Her yüklemeden önce:**
```bash
flutter analyze --fatal-infos && flutter test && dart run tool/check_localization.dart
```
522 test geçiyor.

**Derleme:**
```bash
flutter build ipa --release
```
Çıkan `build/ios/ipa/*.ipa` dosyasını Transporter ile veya `xcrun altool` ile
App Store Connect'e yükleyin.

---

## Gizlilik bildirimi ve izin metinleri

**`ios/Runner/PrivacyInfo.xcprivacy`** ✅

Mayıs 2024'ten beri zorunlu. Uygulama hedefinde yoksa App Store Connect
yüklemeyi **ITMS-91053** ile reddediyor; Pod'ların kendi bildirimleri bunun
yerine geçmiyor. Dosya oluşturuldu ve Xcode hedefine (Copy Bundle Resources)
eklendi.

Beyan edilenler koddan çıkarıldı:

| Veri | Nereye gidiyor |
|---|---|
| Yakınlık durumu (sağlık) | `intimacy/{uid}` — yalnızca partner paylaşımı açıkken |
| Kullanıcı kimliği | Firebase anonim UID |
| Cihaz kimliği | FCM jetonu (bildirim) ve reklam (üçüncü taraf reklam amacı beyan edildi) |
| Satın alma geçmişi | RevenueCat |

**Cihazdan çıkmayanlar:** günlük sağlık kayıtları (`saveDailyLog` tanımlı ama
hiçbir yerden çağrılmıyor), ad, e-posta, doğum tarihi (hepsi `SecureStore`).

Gerekçeli API olarak yalnızca `UserDefaults` (CA92.1) beyan edildi —
`shared_preferences` bunu kullanıyor.

> App Store Connect'teki "App Privacy" formunu da bu tabloya göre doldurun;
> iki beyan tutarsız olursa inceleme takılır.

**Yerelleştirilmiş izin metinleri** ✅

`ios/Runner/<dil>.lproj/InfoPlist.strings` — kamera ve Face ID açıklamaları
altı dilde. Öncesinde `Info.plist` içindeki İngilizce metin Türkçe cihazda da
İngilizce çıkıyordu. Kullanılmayan `NSPhotoLibraryUsageDescription`
kaldırıldı — istemediğiniz bir izni beyan etmek incelemede soru doğuruyor.

---

## Reklam

Uygulamada **AdMob var** (`google_mobile_ads`), ama reklamlar
**kişiselleştirilmiyor**: `AdRequest(nonPersonalizedAds: true)`. Reklam
kimliği (IDFA) kullanılmıyor, ATT izni istenmiyor ve `NSPrivacyTracking`
`false` beyan edildi. İçerik derecesi `MaxAdContentRating.g` ile sınırlı.

Karşılığı gelirin düşmesi; bilinçli bir takas — uygulama kullanıcıya üç yerde
verisinin cihazda kaldığını söylüyor, davranış verisiyle hedefli reklam bu
sözle çelişirdi.

**`SKAdNetworkItems`** ✅ — `Info.plist` içinde 50 reklam ağı kimliği.
Bunlar olmadan kişiselleştirilmemiş reklamlarda bile yükleme atfı çalışmaz ve
eCPM düşer; IDFA gerektirmezler, gizlilik açısından bedelsizdir.

**Kişiselleştirilmiş reklama geçilecek olursa** şunlar zorunlu olur:

1. `PrivacyInfo.xcprivacy` içinde `NSPrivacyTracking` `true`, ilgili veri
   tiplerinde `NSPrivacyCollectedDataTypeTracking` `true`, ve reklam ağının
   alan adları `NSPrivacyTrackingDomains` listesine.
2. `Info.plist` içine `NSUserTrackingUsageDescription` ve uygulama içinde ATT
   izin isteği (`AppTrackingTransparency`). İzin alınmadan IDFA kullanılamaz.
3. App Store Connect "App Privacy" formunda "Used for Tracking" işaretlemesi.

**Dikkat:** Bu bir regl takip uygulaması. Sağlık verisi GDPR'da özel nitelikli
veri (Md. 9), KVKK'da da özel nitelikli kişisel veri. Bu veriyi reklam
hedeflemesinde kullanmak ya da reklam ağına aktarmak ayrı bir açık rıza
gerektirir ve emsali kötüdür. Mevcut kişiselleştirilmemiş kurulum bu riski
taşımıyor.
