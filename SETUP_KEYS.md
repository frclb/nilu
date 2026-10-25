# Hesapları ve anahtarları bağlama

Bu dosya **dışarıdaki panellerde** yapılacak işleri anlatıyor: Apple, RevenueCat,
AdMob, Firebase. Uygulama tarafı hazır; eksik olan tek şey kimlikler.

Yayın öncesi kontrol listesi ayrı dosyada: [STORE_CHECKLIST.md](STORE_CHECKLIST.md).

**Uygulamaya girilecek her değer tek dosyada:**
[`lib/core/release_config.dart`](lib/core/release_config.dart). Neyin eksik
kaldığını şu komut söylüyor; eksik varsa 1 ile çıkar:

```bash
dart run tool/check_release.dart
```

> **Anahtarları sen giriyorsun.** Hiçbir hesaba benim adıma giriş yapılmıyor,
> sertifika ve API anahtarları sende kalıyor. Aşağıda nereye yapıştırılacağı
> yazılı; üretmesi ve saklaması sana ait.

Projenin sabitleri:

| | |
|---|---|
| Bundle ID | `com.furkan.rcperiodtracker` |
| Widget Bundle ID | `com.furkan.rcperiodtracker.CycleWidget` |
| App Group | `group.com.furkan.rcperiodtracker` |
| Team ID (şu anki) | `V8MCMH5GJ7` |

---

## Sıra

Birbirine bağlılar, atlama:

```
1. Apple Developer üyeliği      → her şeyin önkoşulu
2. App ID + capability'ler      → imzalama bunsuz çalışmaz
3. App Store Connect kaydı      → RevenueCat ve AdMob buna bağlanıyor
4. Abonelik ürünleri            → RevenueCat bunları okuyor
5. RevenueCat                   → premium
6. AdMob                        → reklam
7. Firebase                     → partner eşleşmesi
8. Site (GitHub Pages)          → gizlilik, şartlar, destek adresleri
9. Son denetim                  → dart run tool/check_release.dart
10. Google Play (Android)       → 5–7'deki hesaplara Android eklenir
```

---

## 1. Apple Developer Program

Yıllık **99 USD**. Karar verildi: **bireysel** hesap, Hürkan Çelebi.

### Başlamadan önce

| Gereken | Not |
|---|---|
| Apple hesabı (Apple ID) | **İki faktörlü doğrulama açık olmalı** — kapalıysa kayıt başlamıyor |
| Resmî kimlik | Kimlik kartı ya da pasaport. Addaki Türkçe karakterler birebir eşleşmeli |
| Kredi kartı | Yıllık ücret için, otomatik yenilemeli |
| 18 yaş | |

**Apple ID seçimini ciddiye al.** O hesap "Account Holder" oluyor ve
sonradan değiştirmek zahmetli. Kaybedebileceğin bir alan adına bağlı iş
e-postası kullanma; alan adı elden çıkarsa hesaba erişimin de gider.

### Kayıt — telefondan yapmak daha hızlı

Apple bireysel kayıtta kimlik doğrulamasını **Apple Developer** uygulamasına
taşıdı. Cihazdaki kamerayla kimliği okuyor, çoğu ülkede web'den kayıttan
belirgin biçimde hızlı.

1. App Store'dan **Apple Developer** uygulamasını kur
2. Kullanacağın Apple ID ile giriş yap
3. Account → **Enroll**
4. Varlık tipi: **Individual / Sole Proprietor**
5. Kimliği okut (kimlik + selfie)
6. Ad ve adresi kimlikteki gibi onayla
7. Ödemeyi yap

Web yolu da duruyor:
[developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/).
Apple bu akışı zaman zaman değiştiriyor; ekranda farklı bir şey görürsen ona uy.

Onay genelde 24–48 saat. Apple ek belge isteyebiliyor.

### Onaydan sonra — abonelik için ayrı bir kapı var

Üyelik gelir gelmez uygulama yüklenebiliyor ama **satış yapılamıyor**.
App Store Connect → Business bölümünde şunlar tamamlanmalı:

- **Paid Applications Agreement** imzası
- **Banka hesabı** (ödemelerin geleceği yer)
- **Vergi formu** — Türkiye'deki bireysel geliştirici için **W-8BEN**

Bunlar tamamlanmadan abonelik ürünleri "Waiting for Agreement" durumunda
kalıyor ve uygulamaya hiç görünmüyor. Sık atlanan ve premium'u tamamen
bloke eden adım bu.

### Bireysel seçmenin iki sonucu

- Mağazada **satıcı adı olarak yasal adın** görünüyor. Marka adı yazılamıyor;
  onun için şahıs şirketi + D-U-N-S ile Organization kaydı gerekiyor.
- Gizlilik politikasındaki veri sorumlusu da aynı kişi olmalı — yazıldı:
  `Hürkan Çelebi, Bağcılar/İstanbul, Türkiye`.

Sonradan şirkete geçiş Apple tarafında **dönüştürme** değil; yeni hesap açıp
uygulamayı devretmek (App Transfer) gerekiyor ve devrin koşulları var.

### Üyelik bitmesin

Ücret otomatik yenileniyor. Yenilenmezse uygulamalar mağazadan kalkıyor.

**Üyelik gelene kadar IPA dışa aktarılamıyor:** `No signing certificate "iOS
Distribution" found`. Arşiv alınabiliyor, dışa aktarım alınamıyor.

Üyelikten sonra Xcode'da takımı seç. `DEVELOPMENT_TEAM` değeri değişirse
`ios/Runner.xcodeproj/project.pbxproj` içinde iki yerde geçiyor.

Bir de: üyelik gelince `ios/Runner/RunnerDebug.entitlements` gereksizleşiyor.
Debug'ın `CODE_SIGN_ENTITLEMENTS` ayarı `Runner/Runner.entitlements` yapılıp
dosya silinebilir — o dosya yalnızca ücretsiz hesapla cihaza kurabilmek için
vardı, HealthKit ve widget onunla çalışmıyor.

---

## 2. App ID ve capability'ler

Certificates, Identifiers & Profiles → **Identifiers**.

Önce **App Group** oluştur (App ID'den önce, çünkü App ID'ye eklenecek):

```
group.com.furkan.rcperiodtracker
```

Sonra iki App ID:

| App ID | Capability |
|---|---|
| `com.furkan.rcperiodtracker` | HealthKit, App Groups, Sign in with Apple |
| `com.furkan.rcperiodtracker.CycleWidget` | App Groups |

Bunlar `ios/Runner/Runner.entitlements` ile **eşleşmek zorunda**. Sign in with
Apple isteğe bağlı hesap ve bulut eşitleme için (bkz. §7.3); "Enable as a
primary App ID" seçili kalsın. Portalda kapalı bir yeteneği yetki dosyası
isterse imzalama şu hatayla duruyor:

```
Provisioning profile "..." doesn't include the ... entitlement
```

**HealthKit'te dikkat:** yalnızca "HealthKit" açılacak. Alt seçenek olan
**"Verifiable Health Records" açılmayacak** — o klinik kayıtlar için ve Apple'ın
takıma ayrıca atamasını gerektiriyor; açılırsa imzalama durur. Uygulama
yalnızca regl akışı okuyor ve kullanıcı açarsa yazıyor; normal HealthKit
kapsamında.
(Ayrıntısı `Runner.entitlements` içindeki yorumda.)

**Push Notifications açılmayacak.** Uygulama push göndermiyor; hatırlatıcılar
cihazda planlanan yerel bildirimler ve bunlar için yetenek gerekmiyor.

---

## 3. App Store Connect kaydı

[appstoreconnect.apple.com](https://appstoreconnect.apple.com) → My Apps → **+**

- Platform: iOS
- Bundle ID: listeden `com.furkan.rcperiodtracker`
- SKU: serbest, kullanıcı görmez (ör. `rcperiodtracker-001`)
- Birincil dil: Türkçe

Doldurulacak alanlar ve uygulamanın gerçeğiyle uyumu
[STORE_CHECKLIST.md](STORE_CHECKLIST.md) içinde. Buraya bağlı iki şey:

- **Geliştirici web sitesi / Marketing URL** — AdMob'un `app-ads.txt`
  doğrulaması bu alandan okuyor (adım 6). Alan adın yoksa reklam geliri düşük
  kalır.
- **Gizlilik politikası URL'si** — zorunlu alan, uygulama içindeki metnin aynısı
  bir web sayfasında yayında olmalı.

---

## 4. Abonelik ürünleri

App Store Connect → uygulaman → **Subscriptions**.

Önce bir **Subscription Group** oluştur (ör. "Premium"). Grup önemli: aynı
gruptaki planlar arasında kullanıcı yükseltme/düşürme yapabiliyor, ayrı
gruplarda iki ayrı abonelik olurlar.

Sonra plan(lar). Uygulama **RevenueCat'te ne tanımlıysa onu** gösteriyor —
kodda sabit fiyat yok. Desteklenen süreler: haftalık, aylık, 2 aylık, 3 aylık,
6 aylık, yıllık.

Öneri: **aylık + yıllık**. İkisi bir arada "yıllıkta şu kadar tasarruf"
rozetini anlamlı kılıyor; ekran bu oranı kendisi hesaplıyor
(`subscription_pricing.dart`).

### Kararlaştırılan fiyatlar (Türkiye)

| Plan | Fiyat | Aylığa düşen | Ekrandaki rozet |
|---|---|---|---|
| Aylık | **59,99 TL** | 59,99 TL | — |
| Yıllık | **349,99 TL** | 29,17 TL | %51 daha uygun |

**Ömür boyu (tek seferlik) ürün yok.** Karar verildi; uygulama da yalnızca
abonelik sürelerini tanıyor.

Neden bu seviye: Türkiye'de kategorinin aylık bandı ₺40–150, yıllık bandı
₺100–640 (Ekim 2026; ayrıntı `reports/Nilu rakip ve eksik analizi.md`).
Gündelik referans Spotify / YouTube Premium (~₺115–120); bunun üstündeki
aylık fiyat pahalı algılanıyor. Flo'nun en düşük Premium basamağı da ₺59,99.

Rozet "en pahalı aylık eşdeğere göre" hesaplanıyor
(`SubscriptionPricing.savingPercent`): 1 − 349,99 / (12 × 59,99) = %51,4 →
**%51**. Fiyat basamağı değişirse rozet kendiliğinden değişir.

**Enflasyon:** TL fiyatları yılda en az iki kez gözden geçir (aylık
~%2–2,5 reel değer kaybı). Apple vergi kaynaklı düzeltmelerde var olan
otomatik yenilenen aboneliklerin fiyatını kendiliğinden artırmıyor; zam,
App Store Connect'te "mevcut aboneleri koru / yeni fiyata geçir" seçimiyle
yapılıyor.

### Diğer ülkelerin fiyatını ayrıca ver

Apple bir para biriminde fiyat verip gerisini **otomatik çevirebiliyor**.
Burada yapma: 59,99 TL yaklaşık 1,2 avro. Uygulama de/es/fr/pt ile
yayınlanıyor ve o pazarlarda benzer uygulamalar aylık 5–10 avro bandında.
Otomatik çeviri Avrupa'yı üçte bir fiyatın da altında satmak olur.

Tersi de geçerli: taban fiyatı avro verip Türkiye'ye çevirtmek buradaki
fiyatı erişilemez yapar.

Doğrusu: Türkiye için yukarıdaki fiyatlar, diğer bölgeler için ayrı bir
taban. App Store Connect fiyat tablosunda bölge bölge düzenlenebiliyor.

### Avrupa için öneri (henüz karara bağlanmadı)

| Plan | Fiyat | Aylığa düşen | Rozet |
|---|---|---|---|
| Aylık | 3,99 € | 3,99 € | — |
| Yıllık | 23,99 € | 2,00 € | %50 daha uygun |

Türkiye ile aynı yapı: yıllık, aylığın tam yarısı. Rozet iki pazarda da
aynı sayıyı gösteriyor.

Daha yukarısını denemek istersen 4,99 € / 29,99 € de tam %50 veriyor ve
indirim kampanyası için yer bırakıyor. Yeni ve bilinmeyen bir uygulamada
3,99 daha kolay dönüşür.

**Gösterilen fiyat cebe girmiyor.** 3,99 €'nun içinde KDV var (Apple
tahsil edip kendi ödüyor) ve üstüne komisyon geliyor:

| | Komisyon %15 | Komisyon %30 |
|---|---|---|
| 3,99 € | 2,83 € | 2,33 € |
| 4,99 € | 3,53 € | 2,91 € |

**App Store Small Business Program'a başvur.** Yıllık geliri 1 milyon
doların altındaki geliştiricilerde komisyon %30 yerine %15. Başvuru
ücretsiz ama **kendiliğinden olmuyor**; başvurmazsan %30 ödersin. Tablodaki
fark aynı satışta yaklaşık %20 daha fazla gelir demek.

Her ürün için:

- Product ID (ör. `rc_premium_monthly`, `rc_premium_annual`) — sonradan
  **değiştirilemez**
- Fiyat (Apple'ın fiyat basamaklarından)
- **Localization**: her ürüne görünen ad + açıklama. En az birincil dil zorunlu;
  uygulama altı dilde yayınlandığı için altısını da girmek doğru olur.
- **Review screenshot**: paywall ekranının görüntüsü. Bu olmadan ürün
  "Missing Metadata"da kalır ve uygulamayla birlikte incelemeye gitmez.

Tanıtım teklifi (ilk ay indirimli, deneme süresi) koyacaksan buradan; uygulama
`introductoryPrice` alanını okuyup gösteriyor.

---

## 5. RevenueCat

[app.revenuecat.com](https://app.revenuecat.com) → yeni proje.

**5.1 Uygulamayı ekle:** Apps → App Store → Bundle ID `com.furkan.rcperiodtracker`.

**5.2 App Store Connect bağlantısı:** RevenueCat'in satın almaları doğrulaması
için In-App Purchase anahtarı gerekiyor. App Store Connect → Users and Access →
Integrations → **In-App Purchase** → yeni anahtar → `.p8` indir → RevenueCat'e
yükle. (Eski "shared secret" yöntemi de çalışıyor ama Apple anahtarı öneriyor.)

**5.3 Entitlement:** Entitlements → yeni → kimliği tam olarak:

```
premium
```

Kod bu adı arıyor (`subscription_service.dart`). Başka bir ad verilirse abone
olan kullanıcı ödeme yapar ama uygulamada hiçbir şey açılmaz — sessiz ve kötü
bir hata. Ürünleri bu entitlement'a bağla.

**5.4 Offering:** Offerings → `default` adlı bir offering, içine paketler
(Monthly, Annual). Uygulama `offerings.current` okuyor, yani **current olarak
işaretlenmiş** offering gösteriliyor.

**5.5 Anahtar:** Project settings → API keys → **Public app-specific key**
(`appl_` ile başlar; `sk_` ile başlayan gizli anahtarı **uygulamaya koyma**).

Yapıştırılacak yer — `lib/core/release_config.dart`:

```dart
static const String revenueCatAppleApiKey = 'appl_…';
```

Anahtar girilene kadar SDK hiç başlatılmıyor; uygulama çalışıyor, premium
ekranı "şu an kullanılamıyor" diyor.

**5.6 Sandbox testi:** App Store Connect → Users and Access → **Sandbox
Testers** → test hesabı. Cihazda Ayarlar → App Store → Sandbox Account ile giriş
yapılır. Gerçek para çekilmez.

---

## 6. AdMob

[admob.google.com](https://admob.google.com) → hesap aç, ödeme profilini
doldur (bu olmadan gelir birikir ama ödenmez).

**6.1 Uygulamayı ekle:** Apps → Add app → iOS. "Mağazada listeli mi?"
sorusuna uygulama henüz yayında değilse **hayır**; yayına çıktıktan sonra
geri gelip **App Store listesine bağla**. Bağlanmamış uygulamalar sınırlı
reklam alıyor, yani gelir düşük kalıyor.

**6.2 App ID:** `ca-app-pub-XXXXXXXX~YYYYYYYY` (tilde ile).

İki yere, aynı değer (denetleyici karşılaştırıyor):

- `lib/core/release_config.dart` → `admobAppIdIos`
- `ios/Runner/Info.plist` → `GADApplicationIdentifier` (şu an Google'ın test
  kimliği `ca-app-pub-3940256099942544~1458002511`)

**6.3 Reklam birimi:** Ad units → Banner. Çıkan `ca-app-pub-XXXXXXXX/ZZZZZZZZ`
(eğik çizgi ile) → `lib/core/release_config.dart` → `admobBannerUnitIos`.

Geliştirme derlemesi her zaman Google'ın test birimini kullanıyor (kendi
reklamına tıklamak hesabı kapattırır). Release derlemede birim girilmemişse
reklam alanı hiç çizilmiyor — test reklamları "Test mode" rozetiyle yayına
çıkmıyor.

İki kimliği karıştırmak kolay: **tilde = uygulama**, **eğik çizgi = birim**.

**6.4 AB rıza mesajı — bunu atlamak gelir kaybettirir.** Privacy & messaging →
GDPR → mesaj oluştur, uygulamayı seç, yayınlanacak dilleri işaretle, gizlilik
politikası bağlantısını gir.

Google, Ocak 2024'ten beri AEA ve Birleşik Krallık trafiğinde sertifikalı bir
rıza platformu şart koşuyor ve bu **kişiselleştirilmemiş reklamlar için de**
geçerli. Uygulama de/es/fr/pt ile çıkıyor: altı pazarın dördü. Uygulama tarafı
hazır (`ad_consent.dart`), ama panelde mesaj tanımlı değilse gösterilecek bir
şey yok ve o trafikte reklam servisi kısıtlanır.

**6.5 `app-ads.txt`:** Site oluşturucusu App ID'den kendiliğinden üretiyor
(`google.com, pub-…, DIRECT, f08c47fec0942fa0`). Ama dosya geliştirici
sitesinin **alan adının kökünde** olmalı: `https://alanadin.com/app-ads.txt`.
GitHub'ın proje sitesi (`kullanici.github.io/nilu/`) kök değil. İki yol:

- **Kullanıcı sitesi:** `kullanici.github.io` adlı bir depo; dosya onun
  köküne (`kullanici.github.io/app-ads.txt`). App Store Connect'te geliştirici
  sitesi olarak `https://kullanici.github.io` girilir.
- **Özel alan adı:** Pages'e bir alan adı bağlanınca site kökte yayımlanır ve
  dosya kendiliğinden doğru yerde olur.

Programatik talebin büyük kısmı bu dosyayı arıyor; yoksa eCPM düşer.

**6.6 Test cihazı:** Settings → Test devices → cihazını ekle. **Kendi reklamına
tıklama** — geçersiz trafik hesabı kapattırıyor ve geri dönüşü zor.

---

## 7. Firebase

Partner eşleşmesi ve isteğe bağlı hesap / bulut eşitleme için. Uygulamanın
geri kalanı Firebase'siz çalışıyor; yapılandırılmazsa partner ekranı
eşleşmenin, hesap ekranı girişin kullanılamadığını söylüyor.

**7.1 Proje:** [console.firebase.google.com](https://console.firebase.google.com)
→ yeni proje (Analytics **kapalı**: uygulama analiz kullanmıyor ve gizlilik
politikası bunu söylüyor). Konum: `eur3` (Avrupa) — KVKK ve GDPR açısından
Türkiye'ye en yakın seçenek; politika §4 ve §6 sunucuların yurt dışında
olabileceğini söylüyor, eşitleme de bunun için açık rıza alıyor.

**7.2 iOS uygulaması ve yapılandırma dosyası:** önce 7.3'teki Google
sağlayıcısını aç, **sonra** dosyayı indir — Google açılmadan indirilen dosyada
`REVERSED_CLIENT_ID` yok ve Google ile giriş dönüş adresini bulamıyor.

```bash
dart pub global activate flutterfire_cli
flutterfire configure --platforms=ios
```

`ios/Runner/GoogleService-Info.plist` üretilir ve Runner hedefine eklenir
(denetleyici ikisini de kontrol ediyor). Uygulama `Firebase.initializeApp()`'i
seçeneksiz çağırıyor, yani `firebase_options.dart` gerekmiyor.

Ardından `ios/Runner/Info.plist` → `CFBundleURLSchemes` içindeki
`com.googleusercontent.apps.YER-TUTUCU` yerine dosyadaki
`REVERSED_CLIENT_ID`'yi yaz. Denetleyici ikisinin aynı olduğuna bakıyor.

**7.3 Giriş yöntemleri:** Authentication → Sign-in method:

- **Anonymous** → aç. Partner eşleşmesi anonim bir kimlikle çalışıyor (e-posta,
  ad yok); kimlik yalnızca eşleşme başlatılınca açılıyor.
- **Google** → aç, destek e-postasını seç.
- **Apple** → aç. iOS'ta yerel "Apple ile giriş" kullanılıyor, Services ID
  gerekmiyor. Ama hesap silinirken Apple jetonunun iptali (App Store kuralı
  5.1.1(v)) için **OAuth code flow** alanları doldurulmalı: Apple Developer →
  Keys → yeni anahtar, "Sign in with Apple" işaretli → `.p8` dosyası, Key ID
  ve Team ID Firebase'deki Apple sağlayıcısına girilir.
- Settings → **User account linking** → "Link accounts that use the same
  email" (varsayılan). Partner için açılmış anonim kimliğe hesap
  bağlanıyor (`linkWithProvider`), uid değişmiyor.

Hesap isteğe bağlı: giriş tek başına hiçbir sağlık verisi göndermiyor; bulut
eşitleme ayrı bir açık rızayla açılıyor (`sync_consent_sheet.dart`).

**7.4 Firestore ve kurallar:**

```bash
npm install -g firebase-tools   # ya da: npx firebase-tools …
firebase login
firebase use --add              # .firebaserc oluşur; commit'lenebilir
firebase deploy --only firestore
```

Kurallar (`firestore.rules`) ve indeksler (`firestore.indexes.json`) birlikte
yüklenir. Kurallar yüklenmeden uygulama yayına çıkmamalı: varsayılan kurallar
ya her şeyi kapatır ya her şeyi açar.

**7.5 Kuralların testi (hesap gerekmez):**

```bash
cd firebase_tests && npm install && npm test
```

Emülatörde gerçek kural motoruyla 28 senaryo: partnerin kendini listeye
ekleyemediği, yalnızca kendini çıkarabildiği, onaysız okuyamadığı, davet
kodunun yalnızca sahibince iptal edildiği; bulut kopyasını yalnızca Apple ya
da Google ile girmiş sahibin okuyup yazabildiği, anonim kimliğin ve onaylı
partnerin bile göremediği… CI'da da koşuyor.

**7.6 İsteğe bağlı sertleştirme — App Check:** Firestore'a yalnızca gerçek
uygulamanın erişmesini sağlar (App Attest). Yeni bir paket ve App Attest
yeteneği gerekiyor; eklenirse önce "izleme" modunda açılmalı ki eski
sürümler kesilmesin.

---

## 8. Site (GitHub Pages)

App Store **gizlilik politikası adresi** ve **destek adresi** istiyor.
Site `site/` ve `tool/build_site.dart`'tan üretiliyor; gizlilik politikası ve
şartlar **uygulamanın sözlüğünden** geliyor, yani uygulamadakiyle hep aynı.
Altı dil, çerez/analiz/harici kaynak yok.

**8.1 Depo:** GitHub'da depo oluştur (ör. `nilu`), bu projeyi gönder.

**8.2 Pages'i aç:** Depo → Settings → Pages → Source: **GitHub Actions**.
`.github/workflows/pages.yml` her gönderimde siteyi üretip yayımlıyor.

**8.3 Adres:** `site/site.json` → `baseUrl`, ör.
`https://kullanici.github.io/nilu`. Uygulama yayına çıkınca `appStoreUrl`
de girilirse ana sayfadaki "Yakında" düğmesi indirme bağlantısına dönüşür.

**8.4 App Store Connect'e girilecek adresler** (her dilin kendi sayfası):

| | Türkçe | English |
|---|---|---|
| Gizlilik politikası | `…/tr/privacy/` | `…/en/privacy/` |
| Destek | `…/tr/support/` | `…/en/support/` |

Diğer diller: `de`, `es`, `fr`, `pt` aynı düzende.

**8.5 Yerelde önizleme:**

```bash
dart run tool/build_site.dart && python3 -m http.server 8765 --directory build/site
```

---

## 9. Son denetim

```bash
dart run tool/check_release.dart
```

Hesaplara bağlı her değeri denetler: RevenueCat anahtarı, AdMob kimlikleri
(Google test kimlikleri reddedilir, Info.plist ile karşılaştırılır), destek
e-postası, `GoogleService-Info.plist` (Runner hedefinde mi, doğru uygulamaya mı
ait), `.firebaserc`, site adresi. `android/` olduğu için Android tarafını da
denetler (§10). Eksik yoksa "Yayına hazır" der.

---

## 10. Google Play (Android)

Android projesi hazır (`android/`). Kimlik iOS'la aynı, bu yüzden Firebase,
RevenueCat ve AdMob'da **aynı projelere** Android uygulaması ekleniyor.

| | |
|---|---|
| Paket adı | `com.furkan.rcperiodtracker` |
| En düşük sürüm | Android 8.0 (API 26) — health eklentisi |
| Hedef sürüm | Android 16 (API 36) — Play 31 Ağustos 2026'dan beri istiyor |

Android'de henüz olmayanlar: **Apple Sağlık eşitlemesi** (Health Connect
bağlanmadı) ve **ana ekran widget'ı**. Profil ekranında görünmüyorlar
(`lib/core/platform/app_platform.dart`); mağaza metni de onları saymıyor.

**10.1 Play Console hesabı:** [play.google.com/console](https://play.google.com/console)
→ geliştirici hesabı (tek seferlik ücret, kimlik doğrulaması).

> **Kişisel hesapta yayından önce kapalı test şart.** 13 Kasım 2023'ten sonra
> açılan kişisel hesaplar, üretime çıkmadan önce **en az 12 test kullanıcısıyla
> 14 gün kesintisiz** kapalı test yapmak zorunda; bitmeden "Production" kilitli.
> Kuruluş hesabı (D-U-N-S numarasıyla) bu şarttan muaf. 14 gün takvimi
> belirlediği için hesap ve dahili test erkenden açılmalı; test kullanıcısı
> düşerse sayaç sıfırlanabiliyor, birkaç yedek kişi eklemek iyi olur.

**10.2 Yayın imzası:**

```bash
keytool -genkey -v -keystore ~/nilu-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties.example` → `android/key.properties` olarak kopyala ve
doldur (git dışında). Play App Signing açık kalsın: Google uygulama imzalama
anahtarını tutuyor, sen yalnızca **yükleme anahtarıyla** imzalıyorsun; yükleme
anahtarı kaybolursa sıfırlatılabiliyor. `.jks` dosyasını ve parolaları
depoya **koyma**, ayrıca yedekle.

İki anahtarın SHA-1 ve SHA-256 parmak izi 10.3'te gerekecek:

```bash
keytool -list -v -keystore ~/nilu-upload.jks -alias upload
```

Uygulama imzalama anahtarınınki: Play Console → Test and release → App
integrity → App signing. Geliştirme için debug anahtarı:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
```

**10.3 Firebase Android uygulaması:** Proje ayarları → Uygulama ekle →
Android → paket adı `com.furkan.rcperiodtracker` → **SHA-1 ve SHA-256**
parmak izlerini ekle (yükleme, uygulama imzalama ve debug anahtarları). Sonra
`google-services.json` indir → `android/app/google-services.json`. Ya da:

```bash
flutterfire configure --platforms=android
```

Dosya yokken derleme yine çalışıyor (Gradle eklentisi yalnızca dosya varsa
uygulanıyor), uygulama yerel modda açılıyor.

- **Google ile giriş** Android'de parmak izi olmadan `DEVELOPER_ERROR`
  veriyor. Denetleyici dosyada sertifikalı bir OAuth istemcisi arıyor.
- **Apple ile giriş** Android'de Apple'ın web akışıyla çalışıyor ve iOS'tan
  farklı olarak bir **Services ID** istiyor: Apple Developer → Identifiers →
  Services IDs → yeni (ör. `com.furkan.rcperiodtracker.signin`) → Sign in
  with Apple → Return URL `https://<proje-kimliği>.firebaseapp.com/__/auth/handler`.
  Services ID, Firebase'deki Apple sağlayıcısına girilir. Bu yapılmazsa
  Android'de "Apple ile Devam Et" hata verir. iPhone'da Apple hesabıyla bulut
  eşitlemesi açıp Android'e geçen kullanıcı kayıtlarını ancak bununla geri
  alabiliyor.

**10.4 RevenueCat — Google Play:** RevenueCat → Apps → + Google Play →
paket adı. Play Console'da bir **hizmet hesabı** (Google Cloud → Service
accounts → JSON anahtarı; Play Console → Users and permissions'ta finans
izinleri) oluşturup RevenueCat'e yükle — RevenueCat'in Play kurulum rehberi
adım adım anlatıyor.

Play'de abonelik ürünleri: Monetize → Subscriptions. App Store'daki ürün
kimlikleriyle aynı adları kullanmak RevenueCat'te eşlemeyi kolaylaştırır;
her ürüne aylık/yıllık **base plan**. Ürünleri `premium` entitlement'ına ve
`default` offering'e bağla.

> Play, abonelik ürünü oluşturmaya ancak faturalandırma izni olan bir
> derleme yüklendikten sonra izin veriyor: önce bir AAB'yi dahili test
> kanalına yükle (10.7).

Anahtar (`goog_` ile başlar) → `lib/core/release_config.dart`:

```dart
static const String revenueCatGoogleApiKey = 'goog_…';
```

**10.5 AdMob — Android uygulaması:** AdMob'da aynı hesapta Apps → Add app →
**Android**. iOS ile kimlikler farklı:

- App ID → `release_config.dart` → `admobAppIdAndroid` **ve**
  `android/app/src/main/AndroidManifest.xml` →
  `com.google.android.gms.ads.APPLICATION_ID` (şu an Google'ın örnek kimliği;
  denetleyici ikisini karşılaştırıyor)
- Banner birimi → `admobBannerUnitAndroid`

`app-ads.txt` aynı yayıncı kimliğini taşıdığı için değişmiyor.

Manifest reklam kimliği iznini (`AD_ID`) **kaldırıyor**: reklamlar
kişiselleştirilmemiş, iOS'ta da IDFA istenmiyor. Play Console'daki "Reklam
kimliği" sorusuna bu yüzden **Hayır**.

**10.6 Play Console → Uygulama içeriği (App content):** her biri
STORE_CHECKLIST.md "Google Play" bölümünde ayrıntılı.

- Gizlilik politikası: sitenin `…/tr/privacy/` adresi
- Reklam içeriyor: **Evet**
- Uygulama erişimi: bütün özellikler girişsiz kullanılabiliyor
- **Sağlık uygulamaları beyanı:** her uygulama için zorunlu; "Period
  tracking" (regl takibi) ve gebelik ile ilgili seçenekler işaretlenir.
  Health Connect kullanılmadığı için onun izin formu yok.
- **Veri güvenliği (Data safety):** STORE_CHECKLIST.md §4 → "Google Play —
  Data safety"
- **Hesap silme bağlantısı:** `…/tr/support/#delete-account` (sitede
  hazır; uygulama dışından silme isteme yolu da orada)
- İçerik derecelendirmesi (IARC anketi), hedef kitle (13+)

**10.7 Derleme ve yükleme:**

```bash
flutter build appbundle --release
```

`build/app/outputs/bundle/release/app-release.aab` → Play Console → Test and
release → Internal testing → yeni sürüm. Sonra kapalı test (12 kişi, 14
gün), sonra üretim. Sürüm numarası iOS'la ortak: `pubspec.yaml` →
`version`.

Mağaza metinleri [STORE_LISTING.md](STORE_LISTING.md) "Google Play"
bölümünde, görseller `store_assets/google_play/`.

---

## Sonra ne kalıyor

Kimlikler bağlandıktan sonra iki kontrol:

1. **Reklam bandını gerçek birimle gör.** Test reklamları sabit boyutlu
   (320×50, 468×60, 728×90) ve geniş düzende yanlarda siyah dolgu bırakıyor.
   Gerçek uyarlanabilir envanterin bandı doldurması bekleniyor; iPad'de bir kez
   bakmak gerekiyor.
2. **Sandbox'ta satın alma akışını baştan sona geç:** satın al, kapat–aç,
   "Satın alımları geri yükle", aboneliği iptal et.
