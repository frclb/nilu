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

Bu turda değişen davranışlar — hepsi elle doğrulanabilir:

**Açılış**
- Firebase yapılandırması yokken uygulama **açılmalı** (eskiden çöküyordu).
  Konsolda `Firebase not configured — running in local-only mode` görürsünüz;
  bu beklenen davranış.

**Onboarding → Takvim**
- Son regl tarihi ve döngü uzunluğu sorulur, sonra ana ekran açılır.
- Takvimde bir güne dokunun → "Regl işaretle" → gün renklenir, tahmin
  çizgileri kayar. Tekrar dokunun → işaret kalkar.
- **Gelecek bir tarihe** işaretlemeyi deneyin → uyarı çıkmalı, kayıt olmamalı.

**Günlük kayıt**
- Ana ekrandaki + düğmesi → akış/semptom/ruh hâli seçip kaydedin.
- Takvimde aynı güne dönün → seçimleriniz **orada durmalı**.
  (Eskiden takvim ve log ekranı farklı kelime kullandığı için görünmüyordu.)

**Dil**
- Ayarlar yerine cihaz dilini değiştirip uygulamayı yeniden açın.
- Türkçe ve İngilizce tam çevrilidir. Almanca/İspanyolca/Fransızca/Portekizce
  seçerseniz **İngilizceye düşer** — çökmez, ham anahtar kodu göstermez.
- Dil değiştirdikten sonra kayıtlı semptomlarınız **kaybolmamalı**.

**Gizlilik ekranı** (Profil → Gizlilik ve Güvenlik)
- "Verilerimi Dışa Aktar" → JSON panoya kopyalanır, bir nota yapıştırıp görün.
- "Hesabımı Sil" → **gerçekten siler** ve onboarding'e döner. Test verisiyle deneyin.

**Kişisel bilgiler** (Profil → Kişisel Bilgiler)
- Ad girip kaydedin → ana ekrandaki selamlama adınızı göstermeli.

**Partner eşleştirme**
- QR ekranındaki "Eşleşme Kodunu Kopyala" gerçekten panoya kopyalar.
- QR **tarama** için gerçek cihaz gerekir (simülatörde kamera yok).

---

## 4. Ekran görüntüsü almak (mağaza için)

Simülatörde uygulama açıkken:
```bash
xcrun simctl io booted screenshot ~/Desktop/rcapp-01.png
```

App Store Connect'in istediği boyut zamanla değişiyor — formun o an hangi
cihazı zorunlu tuttuğuna bakın ve o simülatörde komutu tekrarlayın. Uygulama
şu an iPad'i de hedeflediği için iPad ekran görüntüsü de isteniyor
([STORE_CHECKLIST.md](STORE_CHECKLIST.md) §3'e bakın).

---

## 5. Otomatik testler

```bash
flutter test
```

44 dosyada 522 test var. Çoğu saf mantığı ve depolamayı kapsar (döngü
hesabı, tahmin, şifreli depolama, eski veri kurtarma, abonelik korumaları).
Yanına üç tür daha eklendi:

| Tür | Ne yakalar |
|---|---|
| Kaynak taraması | Sabit renk kaçağı, uzak görsel, eksik efsane işareti |
| Kontrast | Gerçek `ThemeData` üzerinden, açık/koyu × dört tema için WCAG oranı |
| Arayüz | Yönlendirme, alt gezinme, uygulama kilidi kapısı |

Ekranların görsel doğruluğunu hâlâ elle doğrulamanız gerekir; testler
düzenin *doğru göründüğünü* değil, kurallara uyduğunu kontrol eder.

Yükleme öncesi tam kontrol:
```bash
flutter analyze --fatal-infos && flutter test && dart run tool/check_localization.dart
```
