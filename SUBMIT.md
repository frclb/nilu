# App Store'a yükleme

Bu dosya **yükleme mekaniğini** anlatıyor: derlemeden incelemeye kadar.

Yan dosyalar:

- [STORE_CHECKLIST.md](STORE_CHECKLIST.md) — neyin hazır, neyin eksik olduğu
- [SETUP_KEYS.md](SETUP_KEYS.md) — hesapları ve anahtarları bağlama

> **Anahtarları ve şifreleri sen giriyorsun.** Hiçbir hesaba benim adıma
> giriş yapılmıyor. Aşağıda hangi değerin nereye gittiği yazılı; üretmesi
> sende.

---

## 0. Önce bunlar bitmeli

Yükleme bunlardan birini atlarsa ya derleme durur ya inceleme reddeder.

| | Durum | Nerede |
|---|---|---|
| Apple Developer Program üyeliği | ⬜ **engelleyici** | [SETUP_KEYS.md §1](SETUP_KEYS.md) |
| Destek e-postası | ⬜ **engelleyici** | `lib/core/release_config.dart` |
| RevenueCat anahtarı + `premium` entitlement | ⬜ | [SETUP_KEYS.md §5](SETUP_KEYS.md) |
| Gerçek AdMob kimlikleri (+ Info.plist) | ⬜ | [SETUP_KEYS.md §6](SETUP_KEYS.md) |
| Firebase: `GoogleService-Info.plist`, Apple + Google giriş (anonim kapalı), Google dönüş adresi, kurallar | ⬜ | [SETUP_KEYS.md §7](SETUP_KEYS.md) |
| App ID'de "Sign in with Apple" | ⬜ | [SETUP_KEYS.md §2](SETUP_KEYS.md) |
| Site yayında (gizlilik ve destek adresleri) | ⬜ | [SETUP_KEYS.md §8](SETUP_KEYS.md) |
| Şartlar ve politikanın hukuki gözden geçirilmesi | ⬜ | [STORE_CHECKLIST.md](STORE_CHECKLIST.md) |

Hesaplara bağlı olanların hepsini tek komut denetliyor:

```bash
dart run tool/check_release.dart
```

**Köşeli parantezler özellikle tehlikeli.** Destek e-postası boşken
politika ve Şartlar `[E-POSTA ADRESİ]` gösteriyor; inceleyen kişi bunu
"tamamlanmamış uygulama" sayar. Adres tek satırda verilince altı dilin
hepsinde görünüyor.

**Test reklam kimlikleriyle gönderme.** Google'ın test kimlikleri reklamın
üstüne "Test mode" rozeti basıyor. Release derleme birim girilmemişse reklam
alanını hiç çizmiyor; ama Info.plist'teki test App ID'si yine de denetleyiciden
geçmez.

---

## 1. Yüklemeden önce koş

```bash
dart run tool/check_release.dart \
  && flutter analyze --fatal-infos \
  && flutter test \
  && dart run tool/check_localization.dart \
  && python3 tool/check_store_listing.py \
  && (cd firebase_tests && npm test)
```

Hepsi temiz olmalı. Simülatördeki uçtan uca testler ayrıca:
[TESTING.md §5](TESTING.md).

---

## 2. Sürüm ve derleme numarası

`pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Soldaki (`1.0.0`) kullanıcının gördüğü sürüm, sağdaki (`+1`) derleme numarası.

**Kural:** App Store Connect aynı derleme numarasını iki kez kabul etmiyor.
Reddedilen bir yüklemeyi düzeltip tekrar gönderirken sürümü aynı bırakıp
numarayı artır:

```yaml
version: 1.0.0+2
```

---

## 3. IPA üret

```bash
flutter build ipa --release
```

Bu iki şey üretiyor:

- `build/ios/archive/Runner.xcarchive` — arşiv
- `build/ios/ipa/*.ipa` — yüklenecek dosya

`--export-method` varsayılanı zaten `app-store`, ayrıca vermeye gerek yok.

**Üyelik yokken** arşiv alınıyor ama dışa aktarım şurada duruyor:

```
No signing certificate "iOS Distribution" found
```

Arşiv elde kalıyor; üyelik gelince Xcode Organizer'dan aynı arşiv dışa
aktarılabiliyor.

### İmza: bulut sertifikasıyla değil, bu Mac'teki sertifikayla

**Bulutta yönetilen dağıtım sertifikasıyla imzalanan paket App Store'un
doğrulamasından geçmiyor** (2026-10-27, Xcode 26):

```
Invalid Signature. Code failed to satisfy specified code requirement(s).
The file at path "Runner.app/Runner" is not properly signed.
```

Sebep, takımın adındaki Türkçe harfler (Hürkan ÇELEBİ). Bulut imzalamada
Xcode imzanın kuralına (designated requirement) sertifikanın adını
ayrıştırılmış Unicode (NFD: `u` + birleşen iki nokta) olarak yazıyor;
sertifikadaki ad bileşik (NFC: `ü`). Bu Mac'te `codesign --verify` geçiyor,
Apple'ın sunucusu baytları karşılaştırıp reddediyor. Xcode Organizer'ın
"Upload"ı da aynı yolu kullanıyor.

Çözüm: Mac'te yerel bir **Apple Distribution** sertifikası (Xcode →
Settings → Apple Accounts → takım → Manage Certificates → + → Apple
Distribution; 2026-10-27'de oluşturuldu). Varken dışa aktarım onu seçiyor ve
kural doğru yazılıyor. Yüklemeden önce denetle:

```bash
unzip -oq build/ios/ipa/*.ipa -d /tmp/nilu-ipa
codesign -d -r- /tmp/nilu-ipa/Payload/Runner.app 2>&1 | grep designated
# subject.CN] = "Apple Distribution: Hürkan ÇELEBİ (V8MCMH5GJ7)" → doğru
# subject.CN] = 0x…75cc88… (hex, "u" + U+0308)                → bulut imzası, yükleme reddedilir
```

Sertifika Mac'in anahtar zincirinde; Mac değişirse Xcode'dan dışa aktarılıp
(.p12) taşınmalı ya da yenisi oluşturulmalı.

---

## 4. Yükle

Üç yol var; biri yeter.

### a) Xcode Organizer — ilk sefer için en kolay

Xcode → Window → Organizer → arşivi seç → **Distribute App** → App Store
Connect → Upload. İmzalamayı kendisi hallediyor.

### b) Transporter

Mac App Store'dan ücretsiz. `.ipa` dosyasını sürükle, Deliver'a bas.
_(Bu makinede kurulu değil.)_

### c) Komut satırı — tekrar edilebilir olan

Şifre girmemek için **App Store Connect API anahtarı** kullan:

App Store Connect → Users and Access → Integrations → App Store Connect API →
yeni anahtar, rol **App Manager**. İnen `AuthKey_XXXXXXXX.p8` **bir kez**
indirilebiliyor.

İlk yükleme (build 1, 2026-10-27) bu yolla yapıldı; anahtar `AuthKey_8879865B4X.p8`
("Nilu yukleme", App Manager), Issuer ID `0fd78666-cacb-4657-9056-c7e822a3a36e`.
Anahtar dosyası taşınmadan `API_PRIVATE_KEYS_DIR=<klasör>` ile de gösterilebilir.

```bash
mkdir -p ~/.appstoreconnect/private_keys
mv ~/Downloads/AuthKey_XXXXXXXX.p8 ~/.appstoreconnect/private_keys/

xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/*.ipa \
  --apiKey XXXXXXXX \
  --apiIssuer 00000000-0000-0000-0000-000000000000
```

`--apiKey` anahtarın kimliği (dosya adındaki), `--apiIssuer` panelde
anahtarların üstünde yazan Issuer ID.

Alternatifi Apple kimliği + uygulamaya özel şifre; API anahtarı hem daha
güvenli hem otomatikleştirilebilir.

---

## 5. Yükleme sonrası

Derleme **işlenmesi** 5–60 dakika sürüyor. Bitince e-posta geliyor.
İşlenmeden TestFlight'ta ve sürüm sayfasında görünmüyor.

**İhracat uyumluluğu (encryption) sorusu çıkmayacak:** `Info.plist` içinde
`ITSAppUsesNonExemptEncryption` `false` beyan edildi.

Gerekçe ve senin kararın olan nokta: uygulama iki yerde şifreleme kullanıyor —
iOS'un kendi Anahtar Zinciri (cihazdaki veri) ve isteğe bağlı **parolalı
yedek** (AES-256-GCM, PBKDF2; `cryptography` paketi, iOS'un dışında bir
uygulama). Ayrıca Firebase bağlantısı TLS kullanıyor. Uygulamanın birincil
işlevi bilgi güvenliği değil (döngü takibi); ABD ihracat kurallarında
(EAR Kategori 5 Kısım 2, Not 4) bu tür kullanım muaf sayılıyor ve yaygın
uygulama `false` beyan etmek. Bu bir hukuki değerlendirme; emin olmak
istersen `false` yerine App Store Connect'in sorularını yanıtlayabilirsin:
"standart algoritma, birincil işlev güvenlik değil" → muafiyet seçeneği.
Fransa'da dağıtım için ek beyan istenirse App Store Connect bunu ayrıca
sorar.

Derleme "Invalid Binary" olursa sebebi e-postada yazıyor; en sık olanları
eksik simge boyutu ve yetki/profil uyuşmazlığı.

---

## 6. TestFlight — incelemeden önce kendinde dene

- **İç test:** 100 kişiye kadar, App Store Connect'te kullanıcı olarak
  tanımlı kişiler. **İnceleme gerekmiyor**, derleme işlenir işlenmez dağıtılır.
- **Dış test:** 10.000 kişiye kadar, ilk derleme için **Beta App Review**
  gerekiyor (genelde bir gün).

Gerçek cihazda mutlaka denenecekler — simülatörde çıkmayanlar:

1. **Partner eşleme** (Firebase yapılandırıldıktan sonra; iki cihaz gerekiyor)
2. **Push bildirim** (APNs)
3. **Satın alma**, Sandbox hesabıyla: satın al → kapat/aç → "Satın alımları
   geri yükle" → iptal et
4. **Gerçek reklam** dolduruyor mu; iPad'de bant genişliği dolduruyor mu
5. **HealthKit**: regl okuma ve (ayar açıkken) yazma
6. **Ayarlara yönlendirme** düğmesi uygulamanın kendi sayfasını açıyor mu
   (simülatörde Ayarlar kökünde açılıyor)

---

## 7. App Store Connect sürüm sayfası

Derleme yüklendikten sonra doldurulacaklar:

**Mağaza bilgileri**

| Alan | Not |
|---|---|
| Ad (30 karakter) | |
| Alt başlık (30) | |
| Açıklama | Tıbbi teşhis koymadığını yaz — inceleme sağlık iddialarına bakıyor |
| Anahtar kelimeler (100) | Virgülle, boşluksuz |
| Destek URL'si | Zorunlu |
| Pazarlama URL'si | AdMob `app-ads.txt` bu alanı okuyor |
| Ekran görüntüleri | `~/Desktop/RCApp Ekran Goruntuleri/` — 6.9" ve iPad 13", altı dil |

Ekran görüntüleri zaten üretildi. iPhone 6.9" ve iPad 13" yüklemek yeterli;
Apple küçük boyutları bunlardan türetiyor.

**Genel**

- Kategori: **Health & Fitness**
- Yaş sınırı: anketi dürüst doldur — regl takibi "Medical/Treatment
  Information" altına giriyor, cinsel sağlık içeriğiyle birlikte **12+**
  çıkıyor
- Gizlilik politikası URL'si (zorunlu)
- **App Privacy** etiketleri: [STORE_CHECKLIST.md §4](STORE_CHECKLIST.md)
  bunları uygulamanın gerçeğiyle eşleştirilmiş hâlde yazıyor. Özellikle
  **"Data Used to Track You" → Hayır** (reklamlar kişiselleştirilmiyor, ATT
  istenmiyor, `NSPrivacyTracking` `false`)

**Fiyatlandırma ve abonelikler**

Aboneliklerin bu sürüme **eklenmesi** gerekiyor. Eklenmezse sürüm onaylanır
ama satın alma çalışmaz; ürünler "Missing Metadata"da bekler.

**App Review Information**

- İletişim bilgisi
- Demo hesabı: **gerekmiyor**. Uygulama karşılama sayfalarından sonra
  Apple, Google ya da e-postayla giriş istiyor (2026-10-29'dan beri
  zorunlu); inceleyen kendi Apple kimliğiyle "Apple ile Devam Et"i
  kullanabilir, e-postasını gizleyebilir ya da "E-posta ile Devam Et" →
  "Hesap oluştur" ile herhangi bir adresle hesap açabilir (doğrulama
  beklenmiyor). İstenirse hazır bir demo hesabı verilebilir; onu hesap
  sahibi uygulamadan açıp şifresini yalnızca bu alana yazar.
- Notes alanına yaz:
  - Girişin zorunlu olduğunu ve neden: kayıtları yeni telefona taşımak
    (bulut yedeği), partner eşleşmesi; hesap silme uygulama içinde
  - Verinin cihazda kaldığını; partner eşlemesinin isteğe bağlı olduğunu
    ve sunucuya yalnızca paylaşılmayı seçilen yakınlık durumunun gittiğini
  - Girişin tek başına sağlık verisi göndermediğini, bulut eşitlemenin
    ayrı bir açık rıza ekranından sonra açıldığını (Profil → Hesap ve
    bulut yedeği)
  - Hesap silme yeri: Profil → Hesap ve bulut yedeği → Hesabı sil (kimlik
    yeniden doğrulanıyor, Apple jetonu iptal ediliyor)
  - Premium'u denemeleri için Sandbox hesabı ya da promosyon kodu
  - Uygulamanın teşhis koymadığını, içeriğin bilgilendirme amaçlı olduğunu

---

## 8. Gönder

Sürüm sayfası → **Add for Review** → Submit.

İnceleme genelde 24–48 saat. "Waiting for Review" → "In Review" →
"Pending Developer Release" (elle yayın seçtiysen) ya da doğrudan
"Ready for Sale".

Reddedilirse Resolution Center'dan gerekçe geliyor; oradan yanıt yazılabiliyor.
Metadata düzeltmesi yeni derleme istemiyor — yalnızca binary değiştiyse
numarayı artırıp yeniden yükle.

### Bu uygulamada en olası ret sebepleri

| Gerekçe | Sebep |
|---|---|
| 2.1 Tamamlanmamış | Şartlardaki köşeli parantezler, "Test mode" reklam rozeti |
| 2.1 Eksik IAP | Abonelikler sürüme eklenmemiş |
| 3.1.2 Abonelik bilgisi | Paywall'da fiyat, süre, otomatik yenileme, geri yükleme, şartlar ve politika bağlantıları — hepsi hazır ✓ |
| 5.1.1 Gizlilik | Politika URL'si ulaşılamıyor ya da etiketlerle çelişiyor |
| 5.1.1(v) Sağlık verisi | Sağlık verisinin reklamda kullanılmadığı — kullanılmıyor ✓ |
| 1.4.1 Tıbbi iddia | Açıklamada teşhis/tedavi iddiası |

---

## 9. Sonraki sürümler

1. `pubspec.yaml` derleme numarasını artır
2. `flutter analyze --fatal-infos && flutter test`
3. `flutter build ipa --release`
4. Yükle
5. App Store Connect'te **+ Version**, "What's New" yaz, yeni derlemeyi seç,
   gönder

Ekran görüntülerini yeniden üretmek gerekirse:
`python3 tool/store_screenshots.py phone 1320 2868 <dil>`
