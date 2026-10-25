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
| Görünen ad | Nilu | ✅ `CFBundleDisplayName` + `CFBundleName` (widget: "Nilu") |
| Sürüm | `1.0.0` (build 1) | ✅ [pubspec.yaml:19](pubspec.yaml) |
| Minimum iOS | 15.0 (CycleWidget hedefi 17.0) | ✅ |
| Cihaz ailesi | iPhone **ve** iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) | ✅ ikisi de destekleniyor |
| Yön | iPhone dikey; iPad dikey + yatay | ✅ |
| Desteklenen diller | tr, en, de, es, fr, pt | ✅ altısı da eşit (`dart run tool/check_localization.dart`) |
| Şifreleme beyanı | `ITSAppUsesNonExemptEncryption` = `false` | ✅ — yükleme sırasında soru sorulmaz. Not: parolalı yedek AES-256 kullanıyor (`cryptography` paketi); uygulamanın birincil işlevi bilgi güvenliği olmadığı için EAR Kategori 5 Kısım 2 Not 4 kapsamında değerlendirildi. Hukuki emin olmak istersen [SUBMIT.md](SUBMIT.md) §5'e bak |

> iOS deployment target 13.0'dı ama Podfile ve Firebase 15.0 istiyor — düzeltildi.
> Uyumsuz kalsaydı App Store doğrulaması reddederdi.

**Sürüm artırma:** `pubspec.yaml` içindeki `version: 1.0.0+1` satırını
değiştirin. Nokta öncesi mağazada görünen sürüm, `+` sonrası build numarası.
Her yüklemede build numarası artmalıdır.

---

## 2. İmzalama ve yetkiler

**Apple Developer Program üyeliği ($99/yıl)** ⬜
Mağazaya yükleme, HealthKit ve App Groups bunsuz çalışmaz.
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
(21 boyut, 1024 alfasız). Renkleri paletten geliyor; `icon_palette_test.dart`
hem betiği palete hem de üretilmiş PNG'yi betiğe bağlıyor.

İkonu değiştirmek isterseniz:
```bash
python3 tool/generate_icon.py && dart run flutter_launcher_icons
```
Kendi tasarımınızı kullanacaksanız `assets/icon/app_icon.png` dosyasını
(1024×1024, şeffaflıksız) değiştirip yalnızca ikinci komutu çalıştırın.

> `flutter_launcher_icons` yapılandırmasındaki Android anahtarları kaldırıldı;
> `android/` yokken komut AndroidManifest.xml arayıp çöküyor ve iOS
> ikonlarına hiç sıra gelmiyordu.

**Açılış ekranı** ✅ — marka lotusu, uygulamanın kendi zemini üzerinde.

```bash
python3 tool/generate_launch_image.py
```

> Flutter'ın şablonu iki yer tutucu bırakmıştı: görsel 1×1 saydam bir PNG'ydi
> (Xcode her derlemede *"Launch image is set to the default placeholder icon"*
> diye uyarıyordu) ve zemin storyboard'a **sabit beyaz** yazılmıştı — karanlık
> modda uygulama önce beyaz patlayıp sonra koyuya geçiyordu. Zemin artık
> varlık kataloğundan geliyor ve açık/koyu varyantları var.
>
> Lotusun şekli `tool/lotus.py` içinde, ikonla ortak. Renkler paletle aynı
> olmak zorunda; `test/design_system/launch_screen_test.dart` ikisini
> karşılaştırıyor.

**Ekran görüntüleri ve yaratıcı görseller** ✅ — `store_assets/` (git
dışında), dile göre ayrılmış. İki komutla baştan üretiliyor:

```bash
flutter test test/gallery/store_screens_test.dart --dart-define=STORE=true
python3 tool/store_screenshots.py
```

İlki ekranları uygulamanın kendi widget'larıyla, demo veriyle ve altı dilde
çiziyor (`build/store_raw/`) ve her ekranda büyütülecek öğenin yerini
ölçüyor; ikincisi görselleri kuruyor. Simülatöre gerek yok; tasarım
değişince komutlar yeniden koşuluyor.

> **Tasarım:** koyu mürdüm–böğürtlen zemin, ışık lekeleri ve ince gren.
> Sekiz panel tek bir geniş zeminden kesiliyor; paneller arasında iki ipek
> şerit akıyor: her panel sınırında çaprazlanıyorlar, her panelde biri
> cihazın arkasından yukarı kıvrılıyor, öteki cihazın altından önüne
> geçiyor (önden arkaya geçiş sınırda, görünmeyen yerde). Döngü halkasının
> evre renkli boncukları şeridin üstünde; mağazada kaydırınca görseller
> birbirine bağlanıyor. Başlık, arama sonucu ve öne çıkan görselde şerit
> cihazların arkasından, yazının altından geçiyor. Her panelde ekranın
> asıl öğesi (halka, takvim, belirtiler, trend, cevap…) büyütülüp cihazın
> dışına taşıyor; başlıklarda bir kelime pembe degradeyle vurgulu. Çizim
> parçaları `tool/store_kit.py`'de, kurgu ve metinler
> `tool/store_screenshots.py`'de.
>
> **Google Play'de** sekiz panelin ikisi Android'e özgü: ana ekran
> widget'ı (widget önizleme ekranından kesilen kartlarla kurulan bir ana
> ekran) ve Health Connect; asistan ve kütüphane yalnızca App Store'da.

| Görsel | Boyut | Dil başına |
|---|---|---|
| App Store iPhone 6,9" (Dynamic Island, büyük) | 1320×2868 | 8 |
| App Store iPhone 6,3" (Dynamic Island, orta — **zorunlu**) | 1206×2622 | 8 |
| App Store iPad 13" | 2064×2752 | 8 |
| App Store ürün sayfası başlığı (21:9) | 3840×1646 | 1 |
| App Store arama sonucu görseli (3:2) | 3840×2560 | 1 |
| Google Play telefon (9:16) | 1080×1920 | 8 |
| Google Play 10" tablet (9:16) | 1440×2560 | 8 |
| Google Play 7" tablet | 10" tabletle aynı dosyalar | 8 |
| Google Play öne çıkan görsel | 1024×500 | 1 |
| Google Play simgesi | 512×512 | tek |

Hepsi alfasız RGB; başlık ve arama görselleri JPEG (gren dokusuyla PNG
10 MB'ı geçiyordu), diğerleri PNG. Sıra mağazadaki sıra; App Store'da ilk
üçü (ana sayfa, takvim, gizlilik) arama sonuçlarında görünüyor. Play'de
sıra: ana sayfa, takvim, widget, gizlilik, günlük, içgörüler, gebelik,
Health Connect. Play Console'da 7" ve 10" tablet alanları ayrı; ikisine de
`tablet_10/` yükleniyor (9:16, kenarlar 1080–7680 px arasında: Play'in
büyük ekran kuralı). Tablet için en az 4 görsel isteniyor, sekizi de
yükleniyor.

> **iPhone'da zorunlu olan "Dynamic Island, orta ekran"** (1206×2622).
> Apple'ın sayfası büyük ekran için iki ayrı yedek kuralı veriyor ve
> birbirine işaret ediyor; belirsizlik kalmasın diye iki set de yükleniyor.
> 6,3" seti 6,9" panellerden küçültülüyor (oranlar aynı). iPhone Duo
> (katlanabilir) kareleri Nisan 2027'den itibaren iOS 27.1 SDK ile derlenen
> sürümlerde zorunlu olacak; o zaman `_devices` listesine eklenmeli.
>
> **Başlık ve arama sonucu görselleri** (iOS/iPadOS 27, 5 Ekim 2026'dan
> beri) sürümden bağımsız yüklenebiliyor ama ilk sürüm onaylandıktan sonra.
> Güvenli alanlar Apple'ın şablonundan: başlıkta x 1097–2743, y 493–1154
> (iPhone'da görünen orta karenin, gezinme çubuğu ile simge/ad katmanı
> arasındaki bandı); arama görselinde x 836–3004, y 765–1795. Yazı ve asıl
> içerik bunların içinde. Görsellerde fiyat, indirim, URL, © ya da başka
> platform adı yok.
>
> **Durum çubuğu** iPhone 17 Pro Max simülatöründen ölçülüp çizildi (9:41,
> tam sinyal, dolu pil); Apple'ın görseli depoda tutulmuyor. Emojiler
> macOS'un Apple Color Emoji yazı tipiyle çiziliyor, betik bu yüzden macOS
> istiyor.
>
> Ham ekranlarda reklam bandı yok: test ortamında reklam SDK'sı çalışmıyor.
> Ücretsiz sürümde bant var; mağaza görselinde göstermek zorunlu değil.
>
> **Google Play görselleri hazır ama uygulamanın Android derlemesi yok.**
> Kareler Android ölçülerinde (Pixel sınıfı telefon, 10" tablet) ve Android
> durum çubuğuyla çizildi; Play metinleri için bkz.
> [STORE_LISTING.md](STORE_LISTING.md) "Google Play".

Uygulama hem iPhone hem iPad'i hedefliyor, dolayısıyla App Store Connect
**her ikisi için de** ekran görüntüsü ister ve inceleme uygulamayı iPad'de de
açar. Düzen iki tarafta da doğrulandı (bkz. "Ekran uyumu" bölümü).

Her boyut için 1–10 kare kabul ediliyor; App Store Connect o an hangi cihaz
boyutunu zorunlu tuttuğunu formda gösterir. iPad 13" portrede 1032 pt geniş;
yan menü bu genişlikte zaten açılıyor, kareler onu gösteriyor.

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
| Sağlık ve fitness | Regl tarihleri, semptomlar, ruh hâli, akış yoğunluğu, cinsel aktivite, gebelik testi, gebelik/lohusalık kayıtları, ölçümler, notlar, döngü ayarları | Cihazda **şifreli** (`SecureStore`); **bulut eşitleme açıksa** (açık rızayla) hesaba bağlı olarak Firestore'da (`syncData/{uid}`) | Hayır |
| Hassas kişisel | Yakınlık/cinsel istek seçimleri | Cihazda **şifreli** | Yalnızca kullanıcı açıkça eşleşirse partnerine |
| Kişisel bilgi | Profildeki ad, e-posta, doğum tarihi | Cihazda **şifreli**; bulut eşitleme açıksa Firestore'da | Hayır |
| İletişim bilgisi | Hesabın e-postası ve adı — **yalnızca Apple ya da Google ile giriş yapılırsa** | Firebase Authentication | Hayır |
| Tanımlayıcı | Anonim kullanıcı kimliği, partner kimliği — **yalnızca partner eşleşmesi başlatılırsa**; hesap kimliği — **yalnızca giriş yapılırsa** | Cihaz + Firebase | Hayır |
| Cihaz kimliği | Reklam SDK'sı (kişiselleştirilmemiş reklam) | Google AdMob | Hayır |
| Satın alma | Abonelik durumu | RevenueCat açıksa | Hayır |

**Önemli:** Firebase yapılandırma dosyası eklenmediği sürece uygulama
**yerel-only** çalışır; hiçbir veri cihazdan çıkmaz. Yayın derlemesinde
Firebase açık olacağı için beyan aşağıdaki gibi, **isteğe bağlı** toplamayı da
kapsayarak yapılmalı — Apple isteğe bağlı toplanan veriyi de beyan istiyor.

### Apple — App Privacy
- "Data Used to Track You": **Hayır** (reklamlar kişiselleştirilmiyor, ATT istenmiyor)
- "Data Linked to You" (amaç: **App Functionality**; hiçbiri izleme ya da
  reklam için değil):
  - **Health & Fitness → Health**: bulut eşitleme açıksa kayıtların kopyası;
    partner paylaşımı açıksa yakınlık durumu
  - **Contact Info → Email Address, Name**: Apple ya da Google ile giriş
    yapılırsa (Apple'da e-posta gizlenebiliyor)
  - **User Content → Other User Content**: eşitleme açıksa gün notları
  - **Identifiers → User ID**: hesap kimliği ya da partner için anonim kimlik
  - **Purchases → Purchase History**: abonelik (RevenueCat)
- "Data Not Linked to You": **Identifiers → Device ID** (reklam,
  kişiselleştirilmemiş)
- Formda her kategoride "optional" ayrımı yok; açıklama alanı olmadığı için
  politika §4 isteğe bağlı olduğunu anlatıyor.

### Google Play — Data safety
Play Console → Uygulama içeriği → Veri güvenliği. Aynı tablodan; Play'de
"isteğe bağlı" işareti **var**, kullanılmalı.

- **Toplanan veri** (cihazdan çıkan), hepsi **isteğe bağlı**, amaç
  **Uygulama işlevselliği**, hiçbiri **paylaşılmıyor** (partnere gönderilen
  yakınlık durumu kullanıcının kendi başlattığı bir aktarım; Play bunu
  paylaşım saymıyor):
  - **Sağlık ve fitness → Sağlık bilgisi:** bulut eşitleme açıksa kayıtların
    kopyası; partner paylaşımı açıksa yakınlık durumu
  - **Kişisel bilgiler → Ad, E-posta adresi:** Apple ya da Google ile giriş
  - **Kişisel bilgiler → Kullanıcı kimlikleri:** hesap kimliği, partner için
    anonim kimlik
  - **Uygulama etkinliği → Kullanıcı tarafından oluşturulan diğer içerik:**
    eşitleme açıksa gün notları
  - **Finansal bilgiler → Satın alma geçmişi:** abonelik (RevenueCat)
- **Reklam SDK'sı:** Google'ın
  [Google Mobile Ads SDK beyan rehberine](https://developers.google.com/admob/android/privacy/play-data-disclosure)
  göre doldurulmalı (IP adresinden yaklaşık konum, uygulama etkileşimleri,
  tanılama, cihaz kimlikleri — amaç reklam ve dolandırıcılık önleme).
  Reklam kimliği izni manifestte kaldırıldı (SETUP_KEYS.md §10.5).
- **Firebase:** [Firebase'in Play beyan rehberi](https://firebase.google.com/docs/android/play-data-disclosure)
  — Authentication ve Firestore'un topladıkları yukarıdaki kalemlerle örtüşüyor.
- **Health Connect:** okunan regl günleri cihazda işleniyor; yalnızca
  bulut eşitleme açıksa (açık rızayla) kayıtlarla birlikte hesaba gidiyor —
  yukarıdaki "Sağlık bilgisi" kalemi bunu kapsıyor. Health Connect verisi
  reklam için kullanılmıyor, kimseyle paylaşılmıyor (Health Connect
  politikasının şartı).
- **Güvenlik:** aktarımda şifreli — **Evet**. Kullanıcı silme isteyebilir —
  **Evet** (uygulama içinden; dışarıdan: sitede `support/#delete-account`).

### Hesap silme ✅
Apple, hesap oluşturan uygulamalarda **uygulama içinden hesap silmeyi**
zorunlu tutar (App Store Review Guideline 5.1.1(v)).

- Profil → **Hesap ve bulut yedeği → Hesabı sil**: kimlik yeniden
  doğrulanıyor, Apple ile girildiyse Apple jetonu iptal ediliyor
  (`revokeTokenWithAuthorizationCode`), bulut kopyası, partner verisi ve
  kimlik siliniyor. Cihazdaki kayıtlar kalıyor.
- Profil → Gizlilik → **Tüm verilerimi sil**: giriş yapılmışsa önce aynı hesap
  silme akışı, sonra cihazdaki her şey. Doğrulamadan vazgeçilirse hiçbir şey
  silinmiyor.
- Apple jetonunun iptali için Firebase'deki Apple sağlayıcısına anahtar
  girilmeli (SETUP_KEYS.md §7.3).

### Destek e-postası ⬜ — **engelleyici**
Politikanın 10. bölümü (haklar) ve Şartların 12. bölümü (iletişim) aynı
adresi gösteriyor; adres `lib/core/app_info.dart` → `AppInfo.supportEmail`.
Boşken ekranda dilin köşeli parantezli yer tutucusu görünüyor
(`legal_email_placeholder`) — bilerek: gözden kaçmasın.

Kullanıcı erişim, düzeltme, silme, taşınabilirlik ve itiraz haklarını bu
adresten kullanacak; adres olmadan bu haklar fiilen kullanılamaz.

### Hukuk seçimi ve veri sorumlusu ✅ (gözden geçirilmeli)
Şartlar: Türkiye Cumhuriyeti hukuku, İstanbul Mahkemeleri ve İcra
Daireleri. Politika: veri sorumlusu Hürkan Çelebi, Bağcılar/İstanbul.
Yayından önce bir avukatın okuması önerilir.

### Gizlilik politikası URL'si ⬜
App Store **herkese açık bir URL** ister. Uygulama içindeki gizlilik metni
([privacy_policy_screen.dart](lib/presentation/legal/privacy_policy_screen.dart))
yeterli değildir. Metni bir web sayfasına koyup URL'i mağaza formuna girin.
Yayınlanan sürüm uygulama içindeki metinle **aynı** olmalı; ikisi ayrışırsa
hangisinin geçerli olduğu belirsizleşir.

### Gizlilik etiketleri ⬜
Politikanın 5. ve 6. bölümleri uygulamanın gerçekte kullandığı hizmetleri
sayıyor: Firebase (anonim kimlik, partner eşleme), RevenueCat, Google AdMob. App Store
gizlilik etiketleri bunlarla tutarlı olmalı — özellikle reklam kimliği ve
kullanım verisi kalemleri. Partner paylaşımını "yakınlık durumu" olarak
beyan edin; döngü verisi cihazdan çıkmıyor.

---

## Mağaza metinleri ✅

Ad, alt başlık, tanıtım metni, açıklama ve anahtar kelimeler altı dilde
[STORE_LISTING.md](STORE_LISTING.md) içinde. Karakter sınırları
`python3 tool/check_store_listing.py` ile denetleniyor.

Uygulama adı **Nilu**; cihazda görünen ad (`CFBundleDisplayName`) ve widget
adı güncellendi. Kalan tek iş: adın müsait olduğunu App Store Connect'te
uygulama kaydını açarken doğrulamak.

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
| `GoogleService-Info.plist` | Partner eşleşmesi | `flutterfire configure` |
| Firestore kuralları | Veri güvenliği | `firebase deploy --only firestore:rules` |
| RevenueCat API anahtarı | Premium satın alma | [subscription_service.dart](lib/domain/services/subscription_service.dart) — şu an `appl_api_key_placeholder` |
| Gerçek AdMob kimlikleri | Reklam alanının dolması | `Info.plist` → `GADApplicationIdentifier` ve [ads_datasource.dart](lib/data/datasources/ads_datasource.dart) — şu an Google'ın test kimlikleri |
| AdMob GDPR mesajı | AEA'da reklam servisi | AdMob → Privacy & messaging → GDPR; uygulama tarafı hazır |

Bu panellerin adım adım kurulumu ayrı dosyada: [SETUP_KEYS.md](SETUP_KEYS.md).

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
Üçü de temiz olmalı.

**Derleme:**
```bash
flutter build ipa --release
```

Derlemeden incelemeye kadar bütün adımlar — derleme numarası, yükleme yolları,
TestFlight, sürüm sayfasında doldurulacak alanlar ve bu uygulamada en olası
ret sebepleri — ayrı dosyada: [SUBMIT.md](SUBMIT.md).

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
| Cihaz kimliği | Reklam (AdMob; bağlantısız, üçüncü taraf reklam amacı) |
| Satın alma geçmişi | RevenueCat |

**Cihazdan çıkmayanlar:** günlük sağlık kayıtları (sunucuya yazan kod
kaldırıldı), ad, e-posta, doğum tarihi (hepsi `SecureStore`). Push jetonu
toplanmıyor; FCM kaldırıldı.

Gerekçeli API olarak yalnızca `UserDefaults` beyan edildi: CA92.1
(`shared_preferences`) ve 1C8F.1 (widget ile paylaşılan App Group). Widget
uzantısının kendi bildirimi var (`ios/CycleWidget/PrivacyInfo.xcprivacy`).

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

**AB rıza formu (UMP)** ✅ — [ad_consent.dart](lib/data/datasources/ad_consent.dart).

Google, 16 Ocak 2024'ten beri AEA ve Birleşik Krallık trafiğinde sertifikalı
bir rıza platformu (CMP) şart koşuyor. Bu **kişiselleştirilmemiş reklamlar
için de** geçerli: reklam hedeflenmese bile cihazda okuma/yazma yapılıyor ve
ePrivacy bunu rızaya bağlıyor. Formsuz, o trafikte reklam servisi kısıtlanır —
uygulama de/es/fr/pt ile yayınlandığı için bu altı pazarın dördü demek.

Google'ın kendi CMP'si (UMP) `google_mobile_ads` paketiyle geliyor, ek
bağımlılık yok. Kurulum iki parça:

1. **AdMob konsolunda** mesajın oluşturulması: Privacy & messaging → GDPR.
   Uygulama seçilir, yayınlanacak diller işaretlenir, gizlilik politikası
   bağlantısı girilir. Form orada tanımlanmazsa uygulama tarafı bir şey
   gösteremez.
2. **Uygulamada** zaten hazır: rıza reklamın çıktığı ilk ekranda soruluyor
   (açılışta değil — onboarding'in ortasında Google formu çıkmasın diye).
   Rıza alınamazsa reklam **istenmiyor**.

Rızanın geri alınabilmesi de zorunlu: Gizlilik ve Güvenlik ekranında "Reklam
tercihlerini değiştir" düğmesi, yalnızca Google "gerekli" dediğinde çiziliyor.

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
