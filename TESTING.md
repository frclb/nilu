# Mobilde Görüntüleme ve Test

## Hızlı bakış — hangi yol ne zaman

| Amaç | Komut | Gereken |
|---|---|---|
| Kendi iPhone'unuzda denemek | `flutter run -d "HürkanÇ"` | Xcode + kablo (ilk seferde) |
| iOS simülatöründe denemek | `flutter run -d "iPhone 17"` | Xcode |
| Mantığı doğrulamak | `flutter test` | — |

Uygulama yalnızca iOS için geliştiriliyor; Android ve web platform klasörleri
kaldırıldı.

**Aynı anda tek yol kullanın.** Terminalden `flutter run` ile Xcode'dan ⌘R'yi
birlikte çalıştırmak iki derlemenin aynı klasörü paylaşmasına yol açıyor ve
`Framework 'Pods_Runner' not found` ya da `unable to initiate PIF transfer
session` gibi yanıltıcı hatalar veriyor. Yol değiştirirken araya
`flutter clean` koyun.

---

## 1. Kendi iPhone'unuzda (en gerçekçi test)

Telefonunuz `HürkanÇ` şu an bu Mac'e kablosuz görünüyor. İlk kurulum:

**a) Telefonda Developer Mode'u açın**
Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu → Aç → telefon yeniden başlar.

**b) Kabloyla bağlayın** (ilk seferde kablo şart, sonra kablosuz çalışır)
Telefonda çıkan "Bu bilgisayara güven" sorusuna **Güven** deyin.

**c) Xcode'da imzalama ekibini seçin** — bir kez yapılır
```bash
open ios/Runner.xcworkspace
```
Runner → Signing & Capabilities → Team: kendi Apple ID'niz. **CycleWidget
hedefinde de** aynı takım seçili olmalı; uzantı ayrı imzalanıyor.

Ücretsiz hesap 7 günlük geçici imza verir — süre dolunca uygulama açılmaz
olur, aynı komutla yeniden kurmak gerekir. Ücretsiz takımlar HealthKit ve App
Groups yetkilerini de vermiyor; bu yüzden Debug ayrı bir yetki dosyası
kullanıyor (bkz. README → İmzalama ve yetkiler). O yapılandırmada sağlık
senkronizasyonu ve widget çalışmaz, geri kalan her şey çalışır.

**d) Çalıştırın**
```bash
flutter devices
```
```bash
flutter run -d 00008140-001A3C68262A801C
```

İlk açılışta telefon "Güvenilmeyen Geliştirici" diyebilir:
Ayarlar → Genel → VPN ve Cihaz Yönetimi → kendi hesabınıza güvenin.

---

## 2. iOS simülatöründe

```bash
open -a Simulator
```
```bash
flutter run -d "iPhone 17"
```

Simülatörde **çalışmayanlar:** kamera (QR tarama), push bildirim, gerçek
satın alma. Bunlar için gerçek cihaz gerekir.

### CocoaPods sorunları (ilk derlemede karşılaşabilirsiniz)

**1. `Unicode Normalization not appropriate for ASCII-8BIT`**

CocoaPods UTF-8 locale ister, bu makinede ayarlı değil. Kalıcı çözüm:
```bash
echo 'export LANG=en_US.UTF-8' >> ~/.zshrc
```
Tek seferlik:
```bash
cd ios && LANG=en_US.UTF-8 pod install && cd ..
```

**2. `CDN: trunk URL couldn't be downloaded ... 429 Too Many Requests`**

CocoaPods bazı podspec'leri `raw.githubusercontent.com` üzerinden çeker ve
GitHub bu adresi IP başına saatlik limitler. Kodla ilgisi yoktur.

Önce bayat CDN önbelleğini tazeleyin — çoğu durumda bu yeter:
```bash
rm -rf ~/.cocoapods/repos/trunk && cd ios && LANG=en_US.UTF-8 pod install --repo-update
```
Hâlâ 429 alıyorsanız limitin sıfırlanmasını bekleyin (~1 saat) veya farklı bir
ağa geçin (mobil hotspot işe yarar). Limitin kalkıp kalkmadığını şöyle
anlarsınız:
```bash
curl -s -o /dev/null -w "%{http_code}\n" https://raw.githubusercontent.com/CocoaPods/Specs/master/Specs/9/a/d/PurchasesHybridCommon/17.2.0/PurchasesHybridCommon.podspec.json
```
`200` dönerse `pod install` geçer, `429` dönerse hâlâ beklemek gerekiyor.

---

## 3. Uygulamayı gezerken nelere bakın

Otomatik testlerin göremediği şeyler: dokunma hissi, animasyon, gerçek
bildirim, gerçek kamera, gerçek mağaza. Elle bakılacaklar:

**Açılış ve kurulum**
- Firebase/RevenueCat/AdMob anahtarları yokken uygulama **açılmalı**; partner
  ekranı "şu an kullanılamıyor" der, Premium ekranı fiyat göstermez.
- Kurulumda dört yol: *Döngümü takip etmek istiyorum*, *Bebek istiyorum*
  (ne zamandır denendiği sorulur), *Hamileyim*, *Yakın zamanda doğum yaptım*
  (yalnızca doğum günü sorulur, son 42 gün). Her yolun son ekranındaki
  açıklama seçilen yola göre değişmeli.

**Takvim ve kayıt**
- Bir güne dokunun → gün sayfası: regl, lekelenme, belirti, ağrı, ruh hâli,
  not, gebelik testi. Seçili bir çipe tekrar dokunmak seçimi kaldırmalı.
- Gebelik testinde *Pozitif* → "Gebelik takibini başlat" önerisi çıkar; evre
  kendiliğinden değişmez.
- Cinsel aktivite alanı varsayılan olarak **görünmez**; Profil → Gizlilik'te
  açılır.
- Döngü Ayarları → *Geçmiş reglleri ekle*: son 12 ay, her başlangıç tek
  dokunuş.
- Gelecek bir güne regl işaretlemek reddedilmeli.

**Tahminler**
- Ana ekranda sonraki regl tek gün değil **aralık** ("20–23 Ekim") ve altında
  *Bu tahmin nasıl hesaplandı?*. Açıklama ekranı kendi sayılarınızı söyler.
- Beklenen gün geçince ajanda yerine nazik bir not ve *Bugünü kaydet*.

**Bildirimler** (Profil → Bildirim Ayarları)
- Kaç gün önce (1–5), hatırlatma saati, günlük kayıt saati, *Gecikirse sor*.
  Gerçek bildirimi görmek için saati iki dakika sonraya alıp uygulamayı
  arka plana atın.
- *Gizli bildirim* açıkken kilit ekranında içerik görünmemeli.

**Gizlilik** (Profil → Gizlilik ve Güvenlik)
- Uygulama kilidi: Face ID/cihaz şifresi; arka plandan dönünce ister.
- *Verilerimi dışa aktar* → paylaşım sayfası. *Yedeği parolayla koru* açıkken
  dosya şifreli `.json`; içe aktarırken parola sorulmalı, yanlış parola
  reddedilmeli.
- *Tüm verilerimi sil* → kurulum ekranına döner.
- Profil → Görünüm → *Uygulama simgesi* → *Sade*: ana ekran simgesi not
  sayfasına döner (iOS bir uyarı gösterir; bu sistemin davranışı). iOS
  simgeyi kısa aralıklarla art arda değiştirmeyi birkaç dakikalığına
  sınırlıyor; o sırada uygulama "birkaç dakika sonra yeniden dene" der ve
  seçim gerçek simgede kalır. Uçtan uca test de simgeyi değiştirdiği için
  hemen ardından elle denerken bu mesajı görmek normal.

**Dil**
- Altı dil tam çevrili (tr, en, de, es, fr, pt-BR). Cihaz dilini değiştirip
  uygulamayı yeniden açın; kayıtlı belirtiler kaybolmamalı.

**Erişilebilirlik**
- VoiceOver'ı açın (Ayarlar → Erişilebilirlik): takvim günleri "17 Ekim
  2026, bugün, Adet Dönemi" gibi okunmalı; çipler seçili olup olmadığını
  söylemeli.
- Metin boyutunu en büyüğe alın: uygulama 1,5 kata kadar büyür, taşma
  olmamalı.

**Partner eşleştirme**
- Firebase bağlandıktan sonra iki cihazla: QR → onay kodu → onay. QR
  **tarama** için gerçek cihaz gerekir (simülatörde kamera yok).

---

## 4. Ekran görüntüsü almak (mağaza için)

Simülatörde uygulama açıkken:
```bash
xcrun simctl io booted screenshot ~/Desktop/rcapp-01.png
```

App Store Connect'in istediği boyut zamanla değişiyor — formun o an hangi
cihazı zorunlu tuttuğuna bakın ve o simülatörde komutu tekrarlayın. Uygulama
iPhone'u da iPad'i de hedefliyor, dolayısıyla **iki taraf için de** görüntü
isteniyor ([STORE_CHECKLIST.md](STORE_CHECKLIST.md) §3).

iPad'i yatay çevirmek için simülatörde `Cmd`+`←`. Yatayda yan gezinme menüsü
açılıyor; tanıtım görüntüsü için orası daha iyi duruyor.

---

## 5. Otomatik testler

Hepsi ağ ve hesap gerektirmeden çalışır. Yükleme öncesi tam kontrol:

```bash
dart format --output=none --set-exit-if-changed lib test tool integration_test
```

```bash
flutter analyze --fatal-infos
```

```bash
flutter test
```

```bash
dart run tool/check_localization.dart
```

```bash
python3 tool/check_store_listing.py
```

```bash
dart run tool/build_site.dart
```

Aynı zincir her push'ta GitHub Actions'ta da koşuyor (`.github/workflows/ci.yml`).

**Birim ve ekran testleri** (`flutter test`, 2300'ü aşkın test, Ekim 2026):
döngü ve tahmin hesabı, hatırlatıcı planı, şifreli depolama, yedek
şifreleme, içe/dışa aktarma, partner kuralları, her ekranın üç cihaz
boyutunda çizilmesi, erişilebilirlik taraması (etiketsiz dokunma hedefi,
44 pt altı hedef, büyük yazıda taşma), kontrast, yerelleştirme.

**Firestore kuralları** (Node 22 ve Java 21 gerekir; hesap gerekmez, yerel
emülatör `demo-nilu` projesiyle çalışır):

```bash
cd firebase_tests && npm ci && npm test
```

**Uçtan uca (simülatörde gerçek uygulama)** — `integration_test/`. Gerçek
Anahtar Zinciri ve gerçek iOS kanallarıyla kurulum yollarını, kaydı,
gizlilik ayarını ve sade simgeyi dener. Uygulama verisini **siler**; bu yüzden
yalnızca bu iş için ayrılmış bir simülatörde koşun:

```bash
xcrun simctl create "Nilu E2E" com.apple.CoreSimulator.SimDeviceType.iPhone-16e
```

```bash
flutter test integration_test -d "Nilu E2E"
```

**Yayın denetimi** — hesap anahtarları girildikten sonra eksik kalan bir şey
var mı:

```bash
dart run tool/check_release.dart
```

Ekranların görsel doğruluğunu hâlâ elle doğrulamanız gerekir; testler
düzenin *doğru göründüğünü* değil, kurallara uyduğunu kontrol eder.
