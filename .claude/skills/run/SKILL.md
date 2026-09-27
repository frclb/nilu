---
name: run
description: Bu Flutter uygulamasını iOS simülatöründe başlat ve sür. "Uygulamayı çalıştır", "ekran görüntüsü al", "değişikliği gerçek uygulamada gör" dendiğinde kullan. Cihazı boot etme, derleme, kurma, dokunma koordinatları ve panel takıldığında ne yapılacağı burada.
---

# Uygulamayı çalıştırma

`com.furkan.rcperiodtracker` — Flutter, **yalnızca iOS**.

## `.claude/launch.json`'ı kullanma

O dosya bir web sunucusu tanımlıyor ve bu uygulama için **yanlış**: HealthKit,
Face ID (`local_auth`), AdMob ve `flutter_secure_storage` web'de çalışmıyor.
Web'de açılan şey uygulamanın kendisi değil.

## Sıra

```bash
D=AFD1D088-3A6A-4228-9B23-C2F6D2F1CCD6   # iPhone 17 Pro Max
# iPad için: C1B3155C-6E26-4C32-B658-F936A5A06BC0 (iPad Pro 13")

xcrun simctl boot $D
sleep 20                                  # boot bitmeden install başarısız olur

flutter build ios --simulator --debug     # ilk derleme ~100sn, sonrakiler ~20sn
xcrun simctl install $D build/ios/iphonesimulator/Runner.app

# Temiz ekran görüntüsü için — isteğe bağlı ama ucuz
xcrun simctl status_bar $D override --time "9:41" --batteryState charged \
  --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi

xcrun simctl launch $D com.furkan.rcperiodtracker
```

Kullanıcı izleyecekse simülatör panelini `attach` ile **derlemeden önce** aç.

Aynı anda birden fazla simülatör boot etme: bu oturumda üç cihaz açıkken
süreçler SIGTERM alıp kapandı.

### `uninstall` yapma

`install` üzerine kuruyor ve bu **her şey için yeterli** — `Info.plist`
değişiklikleri dahil. Uygulama adı değiştiğinde ana ekrandaki etiketin
tazelenmesi için kaldırıp kurmak gerektiğini sanıp öyle yaptım; gerekmiyordu
ve simülatördeki bütün veri gitti, onboarding'den yeniden geçmek gerekti.

Ölçtüm: ad `NiluDeney` yapılıp yalnızca `install` çalıştırıldığında ana
ekrandaki etiket hemen değişti; geri alındığında veri de yerinde durdu.

`uninstall` yalnızca gerçekten sıfır durumdan başlamak istendiğinde.

## Ekran görüntüsü: `simctl` kullan

Panelin kendi `screenshot` eylemi bu projede sık sık `captureFailed` veriyor.
Güvenilir yol:

```bash
xcrun simctl io $D screenshot /tmp/s.png
```

Çıkan görüntü **1320×2868** (iPhone 17 Pro Max). Dokunma koordinatları
**punto** cinsinden, yani 440×956. Üçe böl:

```python
from PIL import Image
im = Image.open('/tmp/s.png')
im.resize((440, 956)).save('/tmp/s_points.png')   # piksel = punto
```

Bu küçültülmüş görüntüde okuduğun x,y doğrudan `tap`'e verilir.

iPad Pro 13": görüntü 2064×2752, punto uzayı 1032×1376 — ikiye böl.

## Her dokunuştan önce ekrana bak

Bu tavsiye değil, bedeli ödenmiş bir kural.

Panel bağlantısı bozulduğunda (`machPortNotConnected`) dokunuşlar **bir önceki
ekrana** gidiyor ve hata vermiyor. Bir oturumda kör dokunuşlar sırayla
önbelleği temizledi, oturumu kapattı ve döngü verisini sildi — hiçbiri hata
üretmedi, yalnızca yanlış ekrandaki düğmelere denk geldi.

Bağlantı bozulduysa `detach` + `attach` yetmiyor; cihazı kapatıp yeniden boot
etmek gerekiyor.

## Uygulamaya özel tuzaklar

**Profil ekranı tehlikeli.** Altında "Önbelleği Temizle" ve "Çıkış Yap" var.
Çıkış `onboarding_complete` bayrağını sıfırlıyor ve uygulamayı karşılama
ekranına düşürüyor. Sağlık verisi cihazda kalıyor ama döngü kaydı gidiyor.

**Açılışta hatırlatıcı diyaloğu çıkıyor** ("Hatırlatıcılar"). Bildirim izni
verilmemişse her açılışta geliyor. "Şimdi değil" ile kapat; "Devam" iOS
sistem istemini açar ve iOS onu **bir kez** gösterir.

**Sekme çubuğu** 440 punto genişlikte beşe bölünmüş: Ana Sayfa 46, Takvim 133,
Analiz 220, Kütüphane 306, Profil 392. Simge y≈873, etiket y≈900.

**Lokalizasyon JSON'ları varlık (asset).** `lib/localization/*.json`
değiştirdiysen yeniden derlemeden görmezsin. `Info.plist` için de aynısı:
`flutter build` olmadan `install` eski paketi kurar.

## `debugPrint` çıktısını okumak

`xcrun simctl launch --console-pty` ve `log stream` Flutter'ın `debugPrint`
çıktısını **yakalamıyor**. Tek yol:

```bash
flutter run -d $D --debug > /tmp/run.txt 2>&1 &
sleep 50          # Firebase/RevenueCat hataları akmaya başlayınca hazırdır
grep "ARADIĞIN" /tmp/run.txt
```

## Demo verisini kurmak

Boş bir kurulumdan "regl 6. günü" durumuna:

1. Onboarding'i geç (son regl tarihi + döngü uzunluğu sorulur)
2. Takvim sekmesi → gün hücresine dokun → **"Regl işaretle"**

Güne dokunmak yalnızca **seçer**, işaretlemez. Bir dönemi uzatmak için
ardışık günlerin her birinde ikisini de yapmak gerekiyor.

## Yapılandırılmamış SDK'lar

`flutter run` çıktısında bunlar **normal**, uygulama çalışıyor demektir:

```
RevenueCat check premium error: ... Invalid API Key
Firebase ... not configured
```

Gerçek anahtarların bağlanması: [SETUP_KEYS.md](../../../SETUP_KEYS.md)
