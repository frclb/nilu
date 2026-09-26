# Hesapları ve anahtarları bağlama

Bu dosya **dışarıdaki panellerde** yapılacak işleri anlatıyor: Apple, RevenueCat,
AdMob, Firebase. Uygulama tarafı hazır; eksik olan tek şey kimlikler.

Yayın öncesi kontrol listesi ayrı dosyada: [STORE_CHECKLIST.md](STORE_CHECKLIST.md).

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
7. Firebase                     → partner senkronizasyonu, bildirim
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
| `com.furkan.rcperiodtracker` | HealthKit, App Groups, Sign in with Apple, Push Notifications |
| `com.furkan.rcperiodtracker.CycleWidget` | App Groups |

Bu dördü `ios/Runner/Runner.entitlements` ile **eşleşmek zorunda**. Portalda
kapalı bir yeteneği yetki dosyası isterse imzalama şu hatayla duruyor:

```
Provisioning profile "..." doesn't include the ... entitlement
```

**HealthKit'te dikkat:** yalnızca "HealthKit" açılacak. Alt seçenek olan
**"Verifiable Health Records" açılmayacak** — o klinik kayıtlar için ve Apple'ın
takıma ayrıca atamasını gerektiriyor; açılırsa imzalama durur. Uygulama regl
akışı, uyku ve dinlenme nabzı okuyor, hepsi normal HealthKit kapsamında.
(Ayrıntısı `Runner.entitlements` içindeki yorumda.)

**Push Notifications için** ayrıca bir APNs anahtarı gerekiyor: Keys → yeni
anahtar → "Apple Push Notifications service (APNs)". İnen `.p8` dosyası **bir
kez** indirilebiliyor. Firebase'e yüklenecek (adım 7).

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
| Aylık | **99,99 TL** | 99,99 TL | — |
| Yıllık | **599,99 TL** | 50,00 TL | %50 daha uygun |

Yıllık, aylığın tam yarısına denk gelsin diye seçildi: rozet yuvarlak bir
sayı gösteriyor ve "ayda 50 lira" anlatması kolay.

### Diğer ülkelerin fiyatını ayrıca ver

Apple bir para biriminde fiyat verip gerisini **otomatik çevirebiliyor**.
Burada yapma: 99,99 TL yaklaşık 2,5 avro. Uygulama de/es/fr/pt ile
yayınlanıyor ve o pazarlarda benzer uygulamalar aylık 5–10 avro bandında.
Otomatik çeviri Avrupa'yı üçte bir fiyata satmak olur.

Tersi de geçerli: taban fiyatı avro verip Türkiye'ye çevirtmek buradaki
fiyatı erişilemez yapar.

Doğrusu: Türkiye için yukarıdaki fiyatlar, diğer bölgeler için ayrı bir
taban. App Store Connect fiyat tablosunda bölge bölge düzenlenebiliyor.

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

Yapıştırılacak yer — `lib/domain/services/subscription_service.dart`:

```dart
static const _appleApiKey = 'appl_api_key_placeholder';
```

Anahtar girilene kadar uygulama çalışıyor ama premium ekranı satın alma
yapmıyor; altı giriş noktası korumalı (anahtarsız çağrı SDK'yı `fatalError` ile
çökertiyordu).

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

`ios/Runner/Info.plist`:

```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3940256099942544~1458002511</string>
```

**6.3 Reklam birimi:** Ad units → Banner. Çıkan `ca-app-pub-XXXXXXXX/ZZZZZZZZ`
(eğik çizgi ile) →
`lib/data/datasources/ads_datasource.dart` içindeki `_testBannerIOS`.

İki kimliği karıştırmak kolay: **tilde = uygulama**, **eğik çizgi = birim**.

**6.4 AB rıza mesajı — bunu atlamak gelir kaybettirir.** Privacy & messaging →
GDPR → mesaj oluştur, uygulamayı seç, yayınlanacak dilleri işaretle, gizlilik
politikası bağlantısını gir.

Google, Ocak 2024'ten beri AEA ve Birleşik Krallık trafiğinde sertifikalı bir
rıza platformu şart koşuyor ve bu **kişiselleştirilmemiş reklamlar için de**
geçerli. Uygulama de/es/fr/pt ile çıkıyor: altı pazarın dördü. Uygulama tarafı
hazır (`ad_consent.dart`), ama panelde mesaj tanımlı değilse gösterilecek bir
şey yok ve o trafikte reklam servisi kısıtlanır.

**6.5 `app-ads.txt`:** App Store Connect'teki geliştirici web sitesinin **kök
dizinine** konur (`https://alanadin.com/app-ads.txt`). İçeriği AdMob'un verdiği
tek satır. Programatik talebin büyük kısmı bu dosyayı arıyor; yoksa eCPM düşer.

**6.6 Test cihazı:** Settings → Test devices → cihazını ekle. **Kendi reklamına
tıklama** — geçersiz trafik hesabı kapattırıyor ve geri dönüşü zor.

---

## 7. Firebase

```bash
flutterfire configure
```

`ios/Runner/GoogleService-Info.plist` üretilir. Sonra:

- **APNs anahtarı** (adım 2'deki `.p8`) → Firebase Console → Project settings →
  Cloud Messaging → Apple app configuration. Bu olmadan bildirim gitmez.
- **Firestore kuralları:**

  ```bash
  firebase deploy --only firestore:rules
  ```

Partner senkronizasyonu ve bildirim bunlara bağlı; yapılandırılmazsa uygulama
çalışıyor ama partner özelliği yerel kalıyor.

---

## Sonra ne kalıyor

Kimlikler bağlandıktan sonra iki kontrol:

1. **Reklam bandını gerçek birimle gör.** Test reklamları sabit boyutlu
   (320×50, 468×60, 728×90) ve geniş düzende yanlarda siyah dolgu bırakıyor.
   Gerçek uyarlanabilir envanterin bandı doldurması bekleniyor; iPad'de bir kez
   bakmak gerekiyor.
2. **Sandbox'ta satın alma akışını baştan sona geç:** satın al, kapat–aç,
   "Satın alımları geri yükle", aboneliği iptal et.
