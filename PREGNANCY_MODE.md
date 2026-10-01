# Gebelik Modu — Araştırma ve Plan

Üç gözle bakıldı: kadın doğum tarafı (ne tıbben doğru), analist tarafı (ne
zaman neyi yapmaya değer), tasarım tarafı (ekranda ne olacak).

Belgedeki klinik iddiaların kaynakları en altta.

---

## 1. Uygulama bugün nerede

Taradım; işe yarayan şu emsaller **zaten var**:

| İhtiyaç | Mevcut karşılığı | Dosya |
|---|---|---|
| Tahminleri susturan bayrak | `fertilityTracked=false` → `CyclePhase.suppressed` (hormonal doğum kontrolü) | `lib/domain/models/cycle_info.dart:240` |
| Tüm sekme kümesini değiştiren mod | Partner modu (`navDestinations(isPartner:)`) | `lib/presentation/home/widgets/custom_bottom_nav.dart:38` |
| Modun kalıcılığı | `UserViewModel._isPartner` + `prefs` | `lib/domain/view_models/user_view_model.dart:45` |
| Zamanlanmış hatırlatıcı | `ReminderPlanner` → `ReminderScheduler.zonedSchedule` | `lib/data/local/reminder_scheduler.dart:85` |
| Teşhis koymayan klinik araç | Yoğun kanama değerlendirmesi — *"Teşhis koymuyor, yönlendiriyor"* | `lib/presentation/health_check/heavy_bleeding_screen.dart:17` |
| Kaynak atıflı içerik | `ArticleSource(label, url)` — NHS, Office on Women's Health | `lib/domain/models/article.dart:37` |
| Hekime götürülecek özet | `DataExportService` klinik özeti | `lib/domain/services/data_export_service.dart` |
| Şifreli yerel depo | `SecureStore.sensitiveKeys` | `lib/data/local/secure_store.dart` |

**Gebelik desteği hiç yok.** Lokalizasyonda "gebelik" yalnızca döngü
metinlerinde ve şartlarda geçiyor.

Bu, işin yarısının zaten yapılmış olduğu anlamına geliyor: gebelik modu
sıfırdan bir mimari değil, var olan üç kalıbın (mod + bayrak + hatırlatıcı)
yeni bir birleşimi.

---

## 2. Klinik temel — tasarımı belirleyen kararlar

### 2.1 Tarihlendirme: tek anlamlı çıpa EDD, ve **kullanıcı onu ezebilmeli**

Gebelik haftası son adet tarihinden (SAT) sayılır, döllenmeden değil — ikisi
arasında ~2 hafta fark var ve kullanıcılar bunu sürekli karıştırıyor. Arayüz
"gebelik haftası" demeli, asla "bebeğin yaşı" dememeli.

Naegele kuralı: **EDD = SAT + 280 gün**. Ama bu 28 günlük döngü varsayar.
Uygulama kullanıcının döngü uzunluğunu **zaten biliyor**, dolayısıyla
döngüye göre düzeltilmiş tahmin verebilir:

```
EDD ≈ SAT + 280 + (döngüUzunluğu − 28)
```

35 günlük döngüsü olan birinde düz Naegele bir hafta şaşırır. Bu, uygulamanın
rakiplerinden ayrıştığı yer — ama **tahmin olduğu yazılmalı**.

**Kritik:** ACOG Committee Opinion 700, ilk trimester ultrasonu yapıldıysa
EDD'nin ona göre atanması gerektiğini söylüyor; 9+0 haftadan önce 5 günden
büyük fark EDD'yi değiştirmek için geçerli sebep. Yani **hekimin verdiği
tarih uygulamanınkini ezer.** Tasarım sonucu: EDD alanı her zaman
düzenlenebilir olmalı ve "hekimin verdiği tarih varsa onu gir" denmeli.
Bunu kilitlemek tıbben yanlış olur.

### 2.2 Döngü makinesi susmalı — ama dikkatli

- Regl ve doğurganlık tahminleri durur (`suppressed` emsali).
- **Gebelikte kanama regl değildir.** Kullanıcı kanama kaydederse bu bir
  `PeriodLog` açmamalı ve `lastPeriodStart`'ı kaydırmamalı. Bu oturumda
  düzelttiğimiz halka/takvim hatalarının tamamı bu sınıftandı; burada aynı
  tuzak daha ağır sonuçlu. Gebelikte kanama bir **uyarı bulgusu** olarak
  kaydedilmeli.
- Döngü hatırlatıcıları iptal, randevu hatırlatıcıları kurulur.

### 2.3 Randevu takvimi ülkeye göre değişiyor — şablon + düzenlenebilir

| | İzlem sayısı |
|---|---|
| **T.C. Sağlık Bakanlığı** (2018) | **en az 4** izlem — riske göre artırılır |
| NHS (İngiltere) | ilk gebelikte en az 10 + 2 ultrason; sonraki gebelikte 7 |
| ACOG (ABD) | 28. haftaya dek 4 haftada bir, 36'ya dek 2 haftada bir, sonra haftalık (~13) |

**4 ile 13 arası fark var.** Uygulama 6 dilde çıkıyor; tek bir ülkenin
takvimini gömmek yanlış olur. Türkiye şablonu ayrıntılı olarak §2.7'de.

**Tasarım:** bölgeye göre bir **şablon** öner, her kalemi düzenlenebilir/
silinebilir yap, "kendi randevunu ekle" bırak, şablonun kaynağını ekranda
göster. Kullanıcının gerçek takvimi hekiminden gelir; uygulamanın işi onu
**hatırlatmak**, dayatmak değil.

### 2.4 Fetal hareket: **sayaç koymuyoruz** — bu bilinçli bir karar

Rakiplerin çoğunda "tekme sayacı" var. RCOG Green-top 57: biçimsel hareket
sayımının perinatal mortaliteye olumlu etkisi olduğunu gösteren yeterli kanıt
**yok**; kick chart'lar artık önerilmiyor. Onun yerine kadının bebeğinin
**kendi örüntüsünü** tanıması ve **herhangi bir azalma/değişiklikte** derhal
sağlık hizmetine başvurması öneriliyor.

Sayaç koymak iki yönlü zarar: eşiği tutturan kadın yanlış güven kazanır,
tutturamayan gereksiz kaygılanır.

**Tasarım:** sayaç yok. Bunun yerine tek dokunuşluk *"hareketler değişti"*
→ "şimdi ara" yönlendirmesi ve "bebeğinin normalini tanı" anlatımı.

### 2.5 Uyarı bulguları — en önemli güvenlik yüzeyi

Yoğun kanama ekranının kalıbı birebir uygulanmalı: bulguları listele, teşhis
koyma, "şimdi ara" de, kaynağı göster. Gebelik ana ekranından **tek
dokunuş** uzakta olmalı.

Kapsanması gerekenler: kanama, şiddetli karın ağrısı, görme bozukluğuyla
giden şiddetli baş ağrısı, ani yüz/el şişmesi, fetal hareketlerde azalma,
ateş, sıvı gelişi, dinmeyen kusma.

### 2.6 Gebeliğin bitişi — her sonuç, zarafetle

Bu, bu tür uygulamaların en sık batırdığı yer.

- Sonuçlar: doğum, düşük, tıbbi tahliye, dış gebelik, ölü doğum,
  *"artık gebe değilim / belirtmek istemiyorum"*.
- **Sebep hiçbir zaman zorunlu olmamalı.**
- Çıkışta kutlama yok, konfeti yok, "tebrikler" yok.
- Kayıp sonrası döngü tahminleri **hemen ve kendinden emin** dönmemeli;
  doğum sonrası ve kayıp sonrası döngünün ne zaman döneceği belirsizdir
  (emzirme varsa daha da). "Henüz tahmin edemiyorum" dürüst cevaptır.
- Partner paylaşımı açıksa bitiş **otomatik bildirilmemeli**.

### 2.7 Türkiye protokolü — Doğum Öncesi Bakım Yönetim Rehberi (2018)

Rehberin tamamını okudum (48 sayfa, Halk Sağlığı Genel Müdürlüğü, Yayın
No: 925). Türkiye şablonu şöyle:

**Dört izlem, riske göre artırılır:**

| İzlem | Hafta | Süre |
|---|---|---|
| 1. İzlem (İlk izlem) | **ilk 14 hafta** | 30 dk |
| 2. İzlem | **18–24** | — |
| 3. İzlem | **24–28** | — |
| 4. İzlem | **36–38** | 20 dk |

Önemli kural: *"14. gebelik haftasından sonraki gebe tespitleri, gebelik
haftasına bakılmaksızın **İlk İzlem** olarak değerlendirilir."* Yani gebeliğini
20. haftada işaretleyen kullanıcıya da birinci izlem kontrol listesi
gösterilmeli. Uygulamanın bunu bilmesi gerekiyor.

**Tarama pencereleri izlemlerden ayrı** — bunlar randevularla aynı güne
düşmeyebilir, bu yüzden veri modelinde ayrı kalem olmalılar:

| Tarama | Hafta |
|---|---|
| USG ense saydamlığı + kombine test | **11–14** |
| Maternal serum AFP | 16–20 |
| Üçlü/dörtlü test (kombine yapılmadıysa) | 16–20 |
| USG fetal anomali taraması | **18–22** |
| 75 g OGTT (ilk test negatifse) | **24–28** |
| İndirekt Coombs tekrarı (Rh uygunsuzluğunda) → negatifse anti-D | **28** |

**Birinci izlem tetkikleri:** tam idrar tahlili + idrar kültürü, tam kan
sayımı, HBsAg (aşılı olsa dahi), kan grubu (gebe **ve eş**), sifiliz taraması,
HIV (gebenin bilgi ve onayıyla), TSH.

**Zamana bağlı destek ve aşılar** — bunlar uygulamanın en kolay ve en
değerli hatırlatabileceği şeyler, çünkü tarihe bağlılar:

| | Ne zaman |
|---|---|
| Folik asit 400–800 µg/gün | gebelikten **en az 1 ay önce** (yüksek riskte 4 mg/gün, 12. haftaya dek) |
| D vitamini 1200 IU/gün | **12. haftadan** itibaren |
| Tetanoz toksoid | **12. haftadan** itibaren |
| Demir desteği | anemi yoksa **16. haftadan** itibaren |

**Tehlike işaretleri — resmî liste (13 madde).** Bunu kendim yazmama gerek
yok; Bakanlığın listesi var ve Türkçe pazarda kaynak olarak gösterilebilir:

> şiddetli bulantı-kusma · vajinal kanama · konvülziyon · şiddetli baş ağrısı ·
> görmede bulanıklık · ateş · günlük aktiviteleri yerine getirememe ·
> karın ağrısı · solunum güçlüğü veya sık solunum · yüz, el ve bacaklarda
> şişme · **bebek hareketlerinde azalma** · su gelmesi · nedeni açıklanamayan
> cilt kaşıntısı

"Bebek hareketlerinde azalma"nın bu listede olması §2.4'teki kararı
destekliyor: Bakanlık da sayaç değil, **azalmayı bildir** diyor.

**Tarihlendirme Türkiye'de de aynı:** *"Son adet tarihini bilmiyorsa veya
şüpheli ise mevcut ultrason raporları ile gebelik yaşının belirlenmesi."*
ACOG ile aynı yönde — EDD alanı düzenlenebilir olmalı.

**Sevk ilkesi:** Gebelikte Risk Değerlendirme Formu'ndaki kriterlerden
**birine bile "evet"** denmişse kadın hastalıkları ve doğum uzmanı bulunan
bir kuruluşa sevk. Uygulama bu formu **uygulamamalı** — risk
değerlendirmesi hekimin işi ve yanlış pozitif/negatif ikisi de zararlı.
Uygulamanın yapabileceği: kullanıcıya böyle bir değerlendirmenin
yapıldığını anlatmak ve sonucunu not olarak saklamasına izin vermek.

#### Bunun ürüne üç sonucu

1. **Türkiye şablonu en seyrek olan.** 4 izlem + 6 tarama penceresi. Bu,
   uygulamanın Türkiye'de randevu hatırlatıcısı olarak **daha da değerli**
   olduğu anlamına geliyor: aralar uzun, unutmak kolay.
2. **İzlem ve tarama ayrı kalemler.** `AntenatalEvent` modeli bunu zaten
   kaldırıyor (`targetWeekFrom/To`), ama şablon üretirken ikisi ayrı
   listelenmeli.
3. **Destek hatırlatıcıları Türkiye'de somut bir kazanç.** 12. hafta
   (D vitamini, tetanoz) ve 16. hafta (demir) tarihe bağlı; uygulama bunları
   zaten kurulu `ReminderScheduler` ile hatırlatabilir. Faz 1'e girmeli.

---

## 3. Ürün kararları

### Neden yapılmalı (analist)

Döngü uygulamasının kullanıcısı gebe kaldığında, gebelik özelliği yoksa
9–12 ay boyunca başka bir uygulamaya gidiyor ve çoğu geri dönmüyor. Bu, bu
kategorideki en büyük tek elde tutma kaldıracı.

### Ücretsiz / Premium ayrımı

**Ücretsiz kalmalı** (güvenlikle ilgili olan hiçbir şey ödeme duvarının
arkasında olamaz):
- Gebeliği işaretleme, hafta/trimester görünümü
- Randevu listesi ve hatırlatıcıları
- Uyarı bulguları ekranı
- Gebeliği sonlandırma akışı

**Premium olabilir** (derinlik):
- Haftalık içerik
- Randevuya götürülecek klinik özet (mevcut export'un gebelik sürümü)
- Partner görünümü
- Kilo/tansiyon grafikleri

### Kapsam dışı (şimdilik)

- Doğum sonrası (postpartum) modu — veri modeli engellememeli ama Faz 1'de yok
- Emzirme takibi
- Bebek büyüme/aşı takibi
- Meyve boyu karşılaştırmaları tek başına içerik olarak (eklenebilir ama
  **baş içerik olamaz**; kullanıcıya ne yapacağını söylemiyor)

---

## 4. Veri modeli

Yeni, şifreli depoda (`SecureStore.sensitiveKeys`'e eklenecek):

```dart
class Pregnancy {
  final String id;
  final DateTime? lmp;              // bilinen son adet
  final DateTime estimatedDueDate;  // türetilen ya da kullanıcı/hekim girdisi
  final bool dueDateFromClinician;  // ezildi mi — klinik olarak önemli
  final DateTime confirmedAt;       // işaretleme tarihi
  final PregnancyOutcome? outcome;  // bitişte
  final DateTime? endedAt;
  final String? note;
}

enum PregnancyOutcome { birth, miscarriage, termination, ectopic, stillbirth, undisclosed }

class AntenatalEvent {        // randevu / tarama / test
  final String id;
  final String kindKey;       // lokalize edilebilir kod (LogVocabulary kalıbı)
  final int? targetWeekFrom;  // şablondan gelen hedef aralık
  final int? targetWeekTo;
  final DateTime? scheduledAt;
  final bool done;
  final String? note;         // "hekime soracaklarım" burada
  final bool reminderOn;
}
```

Dikkat edilecekler:

- **Kod sakla, etiket değil.** `LogVocabulary`'nin aldığı ders: çevrilmiş
  etiket saklanınca dil değişince kayıt kayboluyor.
- **Yedekleme yuvarlak gitmeli.** `backup_roundtrip_test.dart` genişletilecek;
  dışa aktarılıp içe alınan gebelik kaydı birebir dönmeli.
- **Geçmiş gebelikler saklanmalı.** Sonraki gebelikte "ilk mi, sonraki mi"
  sorusunun cevabı randevu şablonunu değiştiriyor (NHS 10 vs 7).

---

## 5. Ekranlar

### Giriş noktası

İki yerden: Profil → yeni satır, ve ana ekranda gecikme varken çıkan
bağlam duyarlı bir öneri ("Regl gecikti — gebelik mi?"). İkincisi değerli
ama **ısrarcı olmamalı**; gecikmenin bir sürü sebebi var ve her gecikmede
gebelik sormak rahatsız edici.

### Gebelik kurulumu (3 adım)

1. **Çıpa:** "Son adetin ne zaman başladı?" (uygulama zaten biliyor → ön
   dolu) veya "Hekimin verdiği tahmini doğum tarihi var mı?"
2. **EDD onayı:** hesaplananı göster, nasıl hesaplandığını yaz, **değiştir**
   düğmesi belirgin. Döngü uzunluğuna göre düzeltildiyse söyle.
3. **Ne değişecek:** döngü tahminlerinin duracağını, hatırlatıcıların
   değişeceğini açıkça söyle. Sürpriz olmasın.

### Gebelik ana ekranı

Mevcut çelenk 28 güne göre; 280 güne ölçeklenmiyor. **Yeni ana görsel:**
40 haftalık yay, mevcut hafta vurgulu, trimester bantları. Çiçek dili
korunur (marka sürekliliği), ölçek değişir.

Üstte: `24. hafta 3. gün` + trimester + `EDD'ye 112 gün`.
Altında: sıradaki randevu, bu hafta beklenenler, "bir şeyler yolunda değil"
girişi (uyarı bulguları — tek dokunuş).

### Sekmeler (partner modu kalıbı)

`Gebelik · Takvim · Randevular · Kütüphane · Profil`

Analiz sekmesi gebelikte anlamını yitiriyor (döngü trendi yok); yerini
Randevular alıyor.

### Randevular ekranı

Zaman çizgisi: geçmiş / sıradaki / ileride. Her kalem: hedef hafta aralığı,
varsa randevu tarihi, hatırlatıcı anahtarı, not alanı ("hekime soracaklarım").
Üstte şablonun kaynağı yazılı.

### Bitiş akışı

Profil → "Gebeliği sonlandır". Sonuç listesi + *"belirtmek istemiyorum"*.
Onay ekranı sakin, kutlama yok. Sonrasında uygulama döngü moduna döner ama
tahminler "henüz yeterli veri yok" durumunda başlar.

---

## 6. Aşamalar

**Faz 0 — İskelet, arayüz yok**
Veri modeli, mod bayrağı, tahmin susturma, yedek yuvarlaklığı, testler.
Burada hiçbir şey görünmez ama sonraki her şey buna dayanıyor.

**Faz 1 — Güvenli asgari gebelik modu**
İşaretleme + EDD (düzenlenebilir) + hafta/trimester görünümü + randevu
listesi ve hatırlatıcıları (Türkiye şablonu: 4 izlem + 6 tarama penceresi) +
**zamana bağlı destek hatırlatıcıları** (12. hafta D vitamini ve tetanoz,
16. hafta demir) + uyarı bulguları (Bakanlığın 13 maddelik resmî listesi) +
bitiş akışı (tüm sonuçlar).
**Hiç editoryal içerik yok.** Bu hâliyle bile kullanıcıyı elde tutar,
çünkü sorduğunuz iki şeyi (işaretleme + doktor kontrolleri) karşılıyor —
üstelik Türkiye'de izlem araları uzun olduğu için hatırlatıcı burada
diğer ülkelerden daha çok işe yarıyor.

**Faz 2 — Takip derinliği**
Gebelik semptom sözlüğü (bulantı, mide yanması, ödem, Braxton Hicks),
isteğe bağlı kilo/tansiyon, randevuya götürülecek klinik özet.

**Faz 3 — İçerik ve paylaşım**
Haftalık içerik (6 dil — asıl maliyet burada), partner görünümü,
doğum sonrası.

### Maliyetin nerede olduğu

| Kalem | Ağırlık | Not |
|---|---|---|
| Veri modeli + mod + susturma | orta | emsaller mevcut |
| Randevu motoru + hatırlatıcılar | orta | `ReminderPlanner` genişletilir |
| Yeni ana görsel (40 hafta yayı) | orta | çelenkten ders alınmış; kendi testleri şart |
| Uyarı bulguları | düşük | kanama ekranının birebir kalıbı |
| Bitiş akışı | düşük–orta | teknik değil, metin ve ton işi |
| **Lokalizasyon** | **yüksek** | Faz 1 ~150–250 anahtar; Faz 3 haftalık içerikle 500+ |
| Testler | orta | bu oturumun standardı: her iddia yanlışlanabilir |

Not: şu an 809 anahtar var. Tam gebelik modu lokalizasyon yüzeyini neredeyse
ikiye katlar. Faz 1'i içeriksiz tutmanın asıl sebebi bu.

---

## 7. Riskler

1. **Kapsam.** Gebelik modu halkaya, takvime, analize, hatırlatıcılara,
   dışa aktarmaya, partnere, yedeklemeye ve onboarding'e dokunuyor. Fazlara
   bölünmezse yayın tarihi kayar.
2. **Gebelikte kanama → regl kaydı.** En olası ve en ağır hata. Faz 0'da
   test altına alınmalı.
3. **Tıbbi sorumluluk.** "Teşhis koymuyor, yönlendiriyor" duruşu korunmalı;
   her klinik ekran kaynaklı olmalı; şartlardaki sorumluluk reddi
   gebeliği de kapsayacak şekilde güncellenmeli.
4. **App Store.** Sağlık iddiaları incelemede dikkat çekiyor. Tıbbi cihaz
   izlenimi verecek dil (tanı, teşhis, "güvenli") kullanılmamalı.
5. **Ton.** Kayıp yaşamış bir kullanıcının gördüğü her ekran gözden
   geçirilmeli. Bu teknik değil, metin işi — ve en kolay unutulan.

---

## 8. Karar bekleyenler

1. **Faz 1'de hangi şablonlar olacak?** Türkiye protokolünü doğruladım ve
   §2.7'ye işledim — Türkçe için hazır. Önerim Faz 1'de **yalnızca Türkiye
   şablonu** olsun, diğer diller için "kendi randevunu ekle" ile başlansın;
   NHS/ACOG şablonları Faz 2'de. Yanlış ülkenin takvimini göstermektense
   boş liste göstermek daha dürüst.
2. **Gecikme algılandığında gebelik önerilsin mi?** Değerli ama hassas.
3. **Partner gebelikte ne görecek?** Hiçbir şey / sadece hafta / randevular?
4. **Faz 1 yayına mı girecek, yoksa mevcut sürüm çıktıktan sonra mı?**
   Önerim: **mevcut sürüm önce çıksın.** Uygulama yayına hazır durumda;
   gebelik modu onu aylarca geciktirir.

---

## Kaynaklar

- **T.C. Sağlık Bakanlığı, Halk Sağlığı Genel Müdürlüğü, *Doğum Öncesi
  Bakım Yönetim Rehberi*, Ankara 2018 (Yayın No: 925)** — dört izlem,
  tarama pencereleri, destek takvimi, tehlike işaretleri listesi:
  https://www.saglikaktuel.com/d/file/dogum_oncesi_bakim_yonetim_rehberi.pdf
  (WHO aynası: https://platform.who.int/docs/default-source/mca-documents/policy-documents/guideline/TUR-MN-21-01-GUIDELINE-2018-tur-Antenatal-Care-Management-Guidelines.pdf)
- RCOG Green-top Guideline No. 57, *Reduced Fetal Movements* — biçimsel
  hareket sayımı önerilmiyor:
  https://obgyn.onlinelibrary.wiley.com/doi/10.1111/1471-0528.70198
- ACOG Committee Opinion No. 700, *Methods for Estimating the Due Date* —
  ilk trimester ultrasonu EDD'yi belirler:
  https://www.acog.org/clinical/clinical-guidance/committee-opinion/articles/2017/05/methods-for-estimating-the-due-date
- NHS, *Your antenatal care and appointments* — ilk gebelikte 10, sonraki
  gebelikte 7 randevu:
  https://www.nhs.uk/pregnancy/your-pregnancy-care/your-antenatal-care-and-appointments/
- Tommy's, *Your Antenatal Appointment Schedule*:
  https://www.tommys.org/pregnancy-information/im-pregnant/antenatal-care/your-antenatal-appointment-schedule
