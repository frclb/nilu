# Mağaza Yayın Kontrol Listesi

App Store ve Google Play yüklemesi için gereken adımlar. ✅ = kodda hazır,
⬜ = sizin yapmanız gerekiyor (hesap, sır veya tasarım gerektiriyor).

---

## 1. Uygulama kimliği

| Alan | iOS | Android | Durum |
|---|---|---|---|
| Bundle / Application ID | `com.furkan.rcperiodtracker` | `com.furkan.rcperiodtracker` | ✅ eşitlendi |
| Görünen ad | Period Tracker | Period Tracker | ✅ |
| Sürüm | `1.0.0` (build 1) | `1.0.0` (versionCode 1) | ✅ `pubspec.yaml:19` |
| Minimum sürüm | iOS 15.0 | API 24 | ✅ |
| Desteklenen diller | tr, en, de, es, fr, pt | aynı | ✅ altısı da 562/562 |

> iOS deployment target 13.0'dı ama Podfile ve Firebase 15.0 istiyor — düzeltildi.
> Uyumsuz kalsaydı App Store doğrulaması reddederdi.

**Sürüm artırma:** `pubspec.yaml` içindeki `version: 1.0.0+1` satırını
değiştirin. Nokta öncesi mağazada görünen sürüm, `+` sonrası build numarası.
Her yüklemede build numarası artmalıdır.

---

## 2. İmzalama

**iOS** ⬜
Xcode → Runner → Signing & Capabilities → Team seçin. Apple Developer
Program üyeliği ($99/yıl) gerekir. Otomatik imzalama yeterlidir.

**Android** ⬜
```bash
keytool -genkey -v -keystore ~/rcapp-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias rcapp
```
Sonra `android/key.properties.example` dosyasını `android/key.properties`
olarak kopyalayıp doldurun. Dosya `.gitignore`'da; **keystore'u kaybederseniz
uygulamanın güncellemelerini bir daha yayınlayamazsınız** — yedekleyin.

---

## 3. Görseller

**App ikonu** ✅ — marka lotusu üretildi ve tüm platform boyutlarına uygulandı.

| Öğe | Durum |
|---|---|
| iOS app ikonu (21 boyut, 1024 alfasız) | ✅ |
| Android adaptive icon (foreground + #551B26 zemin) | ✅ |

İkonu değiştirmek isterseniz:
```bash
python3 tool/generate_icon.py && dart run flutter_launcher_icons
```
Kendi tasarımınızı kullanacaksanız `assets/icon/app_icon.png` dosyasını
(1024×1024, şeffaflıksız) değiştirip yalnızca ikinci komutu çalıştırın.

**Ekran görüntüleri** ⬜ — mağaza formlarında hâlâ sizden isteniyor:

| Gerekli | Ölçü |
|---|---|
| iPhone ekran görüntüsü | 6.7" ve 6.5" — her biri 3-10 adet |
| Android ekran görüntüsü | telefon için en az 2 adet |
| Play özellik grafiği | 1024×500 |

Ekran görüntülerini [TESTING.md](TESTING.md) §5'teki simülatör akışıyla alabilirsiniz.

---

## 4. Gizlilik beyanları

Her iki mağaza da hangi veriyi topladığınızı beyan etmenizi zorunlu tutar.
Aşağıdakiler **koddan çıkarılmıştır** — formları buna göre doldurun.

### Toplanan / işlenen veri

| Kategori | Alanlar | Nerede durur | Paylaşılır mı |
|---|---|---|---|
| Sağlık ve fitness | Regl tarihleri, semptomlar, ruh hâli, akış yoğunluğu, cinsel aktivite, döngü ayarları | Cihazda **şifreli** (`SecureStore`) | Hayır |
| Hassas kişisel | Yakınlık/cinsel istek seçimleri | Cihazda **şifreli** | Yalnızca kullanıcı açıkça eşleşirse partnerine |
| Kişisel bilgi | Ad, e-posta, doğum tarihi | Cihazda **şifreli** | Hayır |
| Tanımlayıcı | Anonim kullanıcı kimliği, partner kimliği | Cihaz + (Firebase açıksa) Firestore | Hayır |
| Cihaz kimliği | FCM push token | Firebase açıksa Firestore | Hayır |
| Satın alma | Abonelik durumu | RevenueCat açıksa | Hayır |

**Önemli:** Firebase yapılandırma dosyaları eklenmediği sürece uygulama
**yerel-only** çalışır; hiçbir veri cihazdan çıkmaz. Firebase'i açtığınızda
yukarıdaki "Firestore" satırları geçerli olur ve beyanı güncellemelisiniz.

### Apple — App Privacy
- "Data Used to Track You": **Hayır**
- "Data Linked to You": Health & Fitness, Sensitive Info, Contact Info,
  Identifiers, Purchases (Firebase açıksa)
- "Data Not Collected": Firebase kapalıyken hepsi

### Google Play — Data Safety
- Veri şifreleniyor mu: **Evet** (cihazda; ağda TLS)
- Kullanıcı silme talep edebilir mi: **Evet** — Profil → Gizlilik → Hesabımı Sil
- Sağlık verisi beyanı: **Evet**, "Health and fitness → Health info"

### Gizlilik politikası URL'si ⬜
Her iki mağaza da **herkese açık bir URL** ister. Uygulama içindeki
gizlilik metni ([privacy_policy_screen.dart](lib/presentation/legal/privacy_policy_screen.dart))
yeterli değildir. Metni bir web sayfasına koyup URL'i mağaza formlarına girin.

---

## 5. Kategori ve içerik

- **Kategori:** Health & Fitness (her iki mağazada)
- **Yaş sınırı:** Apple 12+ / Play "Teen" — cinsel sağlık içeriği nedeniyle
- Play'de **Sağlık Uygulamaları beyanı** doldurulmalıdır ⬜
- Uygulama tıbbi teşhis koymaz; bunu mağaza açıklamasına da yazın
  (kod tarafında [terms_section2_content] zaten belirtiyor)

---

## 6. Yayın öncesi bağlanması gerekenler ⬜

| Ne | Neden gerekli | Nasıl |
|---|---|---|
| Firebase yapılandırması | Partner senkronizasyonu ve push bildirim | `flutterfire configure` |
| Firestore kuralları | Veri güvenliği | `firebase deploy --only firestore:rules` |
| RevenueCat API anahtarı | Premium satın alma | [subscription_service.dart:6](lib/domain/services/subscription_service.dart) — şu an placeholder |
| Android SDK | Play derlemesi | Bu makinede kurulu değil (`flutter doctor` ✗) |

Bunlar bağlanmadan uygulama **çalışır ama** partner özelliği yerel kalır,
premium ekranı satın alma yapmaz.

---

## 7. Derleme ve yükleme

**iOS**
```bash
flutter build ipa --release
```
Çıkan `build/ios/ipa/*.ipa` dosyasını Transporter ile veya
`xcrun altool` ile App Store Connect'e yükleyin.

**Android**
```bash
flutter build appbundle --release
```
`build/app/outputs/bundle/release/app-release.aab` dosyasını Play Console'a
yükleyin. (APK değil, AAB istiyor.)

**Her yüklemeden önce:**
```bash
flutter analyze --fatal-infos && flutter test && dart run tool/check_localization.dart
```
