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
| Şartlardaki hukuk seçimi (`[UYGULANACAK HUKUK]`) | ⬜ **engelleyici** | [STORE_CHECKLIST.md](STORE_CHECKLIST.md) |
| Politikadaki e-posta ve veri sorumlusu | ⬜ **engelleyici** | aynı |
| Gizlilik politikası yayında bir URL'de | ⬜ | zorunlu alan |
| Gerçek AdMob kimlikleri | ⬜ | [SETUP_KEYS.md §6](SETUP_KEYS.md) |
| RevenueCat anahtarı + `premium` entitlement | ⬜ | [SETUP_KEYS.md §5](SETUP_KEYS.md) |
| `GoogleService-Info.plist` | ⬜ | `flutterfire configure` |

**Köşeli parantezler özellikle tehlikeli.** İnceleyen kişi Şartlar ekranını
açtığında `[UYGULANACAK HUKUK]` yazısını görür; bu "tamamlanmamış uygulama"
sayılır.

**Test reklam kimlikleriyle gönderme.** Google'ın test kimlikleri reklamın
üstüne "Test mode" rozeti basıyor. İnceleyen bunu bozuk ya da yarım bir ekran
olarak okur.

---

## 1. Yüklemeden önce koş

```bash
flutter analyze --fatal-infos && flutter test && dart run tool/check_localization.dart
```

Üçü de temiz olmalı (Ekim 2026: 1900'ü aşkın test).

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
- Demo hesabı: uygulamada zorunlu hesap yok, **gerekmiyor**
- Notes alanına yaz:
  - Verinin cihazda kaldığını; partner eşlemesinin isteğe bağlı olduğunu ve
    yalnızca anonim bir kimlik ile paylaşılmayı seçilen yakınlık durumunun
    sunucuya gittiğini
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
