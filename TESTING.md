# Mobilde Görüntüleme ve Test

## Hızlı bakış — hangi yol ne zaman

| Amaç | Komut | Gereken |
|---|---|---|
| Kendi iPhone'unuzda denemek | `flutter run -d <device-id>` | Xcode + kablo (ilk seferde) |
| iOS simülatöründe denemek | `flutter run -d "iPhone 17"` | Xcode |
| Android telefonda denemek | `flutter run -d <device-id>` | Android SDK **(bu makinede kurulu değil)** |
| Sadece arayüze bakmak | `flutter run -d chrome` | Chrome |
| Mantığı doğrulamak | `flutter test` | — |

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
Runner → Signing & Capabilities → Team: kendi Apple ID'niz. Ücretsiz hesap
7 günlük geçici imza verir, denemek için yeterlidir.

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

---

## 3. Android'de

Bu makinede Android SDK kurulu değil (`flutter doctor` → `[✗] Android toolchain`).
Play Store'a çıkacaksanız kurulumu şart:

```bash
brew install --cask android-studio
```
Android Studio'yu açıp SDK + bir AVD (emülatör) oluşturun, sonra:
```bash
flutter doctor --android-licenses
```
```bash
flutter run -d emulator-5554
```

---

## 4. Uygulamayı gezerken nelere bakın

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

## 5. Ekran görüntüsü almak (mağaza için)

Simülatörde uygulama açıkken:
```bash
xcrun simctl io booted screenshot ~/Desktop/rcapp-01.png
```

Mağaza 6.7" ve 6.5" boyut ister; iPhone 17 Pro Max ve iPhone 16 Plus
simülatörlerinde aynı komutu tekrarlayın.

---

## 6. Otomatik testler

```bash
flutter test
```

101 test var; hepsi saf mantığı ve depolamayı kapsar (döngü hesabı, tahmin,
şifreli depolama, eski veri kurtarma). Arayüz testi yoktur — onu elle
doğrulamanız gerekir.

Yükleme öncesi tam kontrol:
```bash
flutter analyze --fatal-infos && flutter test && dart run tool/check_localization.dart
```
