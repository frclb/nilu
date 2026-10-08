# Yaşam Evreleri — Yol Haritası

Soru: gebelik dışında ne eklenebilir, ve uygulamayı rakiplerinden ne ayırır?

Kısa cevap: rakiplerin de modları var (gebelik, gebelik planlama, son
yıllarda menopoz). Fark modların **varlığı** değil, **doğruluğu ve
derinliği**. Bu belgedeki her öneri ya klinik bir kılavuza ya da
uygulamanın zaten sahip olduğu bir altyapıya dayanıyor.

Gebelik ayrıntıları: [PREGNANCY_MODE.md](PREGNANCY_MODE.md).
Kaynaklar en altta.

---

## 1. Bulunan tek mimari kural: kanamanın anlamı evreye göre değişiyor

Araştırma boyunca aynı desen her evrede karşıma çıktı:

| Evre | Kanama ne demek | Uygulama ne yapmalı |
|---|---|---|
| Döngü | regl | regl kaydı (bugünkü davranış) |
| Gebelik | **tehlike işareti** (Bakanlık listesi) | regl kaydı açmaz → yapıldı, commit `efb181b` |
| Lohusalık (0–42. gün) | lohia — beklenen, azalarak sürer. **Azaldıktan sonra yeniden artarsa tehlike işareti** (Bakanlık listesi) | regl kaydı açmaz; lohia seyrini kaydeder; yeniden artış → uyarı |
| Lohusalık sonrası ilk regl | gerçek regl ama dönüşü öngörülemez | kayıt evet, tahmin 2–3 döngü boyunca yok |
| Menopoz sonrası (12 ay adet yok) | **tehlike işareti** (NICE NG12: endometrium kanseri şüphesi yolu) | regl kaydı açmaz; hekime yönlendirir |

Dün gebelik için `_canRecordPeriods => !_pregnant` korumasını yazdım. Ama
tablo gösteriyor ki bu tek bir durumun değil, **bir sınıfın** koruması.
Lohusalık ve menopoz sonrası eklendiğinde aynı koruma iki kez daha
yazılırsa, bu oturumda defalarca bulduğumuz hata — aynı kuralın iki yerde
yazılıp birinin eskimesi — garanti.

### Öneri: tek bir `LifeStage` kavramı

Bugün durum dağınık bayraklarla tutuluyor: `isPartner`,
`hormonalContraception`, `pregnant`. Bunlar üç farklı türden şey:

- **Evre** (kanamanın anlamını belirler): `cycle`, `pregnancy`,
  `postpartum`, `postmenopause`. Aynı anda yalnızca biri.
- **Niyet** (döngü evresi içinde vurguyu belirler, veriyi değil):
  yok / korunma / gebe kalmak.
- **Saptanan örüntü** (kullanıcı seçmez, uygulama veriden çıkarır):
  menopoza geçiş (STRAW+10, §4).

Partner modu bunların hiçbiri değil — o bir **kullanıcı rolü** (partnerin
telefonu), ayrı kalmalı.

Kanama kaydının kararı tek bir yerde verilir:
`stage.bleedingMeaning → period | warningSign | lochia`.
Lohusalık eklenmeden önce yapılmalı; sonra yapmak bütün korumaları
yeniden yazmak demek.

---

## 2. Lohusalık — "olsa iyi olur" değil, gebelik modunun çıkışı

Gebelik doğumla bittiğinde uygulama doğrudan döngü moduna dönerse ilk
lohia **regl** olarak kaydedilir: `lastPeriodStart` doğumdan sonraki güne
oturur, tahminler saçmalar, ve azalıp yeniden artan bir kanama — ki bu bir
tehlike işareti — sıradan bir "regl başladı" olarak gömülür. Yani en
asgari lohusalık evresi gebelik modunun **doğruluk** gereği.

### Bakanlık takvimi — Doğum Sonu Bakım Yönetim Rehberi (2018)

67 sayfanın tamamı okundu. Arama özetleri iki kez yanlış çıktı (izlemleri
atlıyordu), bu yüzden kaynaktan:

| İzlem | Zaman | Yer | Uygulamanın işi |
|---|---|---|---|
| 1 | 0–1. saat | hastane | — |
| 2 | 1–6. saat | hastane | — |
| 3 | 6–24. saat | hastane | — |
| 4 | **2–5. gün** | ev / sağlık kuruluşu | hatırlat |
| 5 | **13–17. gün** | ev / sağlık kuruluşu | hatırlat |
| 6 | **30–42. gün** | ev / sağlık kuruluşu | hatırlat |

İlk üçü hastanede, doğumdan sonraki ilk 24 saatte — o sırada kimse regl
uygulaması açmıyor. Son üçü evde ya da sağlık kuruluşunda; **unutulabilir
olanlar bunlar**, hatırlatıcının değeri burada.

### Tehlike işaretleri — resmî liste

> **Vajinal kanama:** 20–30 dakikada 2–3'ten fazla pedi kirletecek kanama,
> pıhtılı kanama, sürekli kan gelişi ya da renginin parlak kırmızıya
> dönüşmesi; **kanamanın azalmasının devamında tekrar kanamalı akıntının
> ortaya çıkması; kanamanın azalmayarak artması** · konvülsiyon ·
> solunum güçlüğü, göğüs ağrısı, hızlı solunum, öksürük, çarpıntı (bacak
> ağrısı eşlik edebilir — rehber bunu aksi kanıtlanana dek tromboemboli
> sayıyor) · 38 °C üzeri ateş · kötü kokulu akıntı · idrar yaparken ağrı
> veya idrar kaçırma · şiddetli baş ağrısı, bulanık görme · şuur kaybı

Kalın kısım tasarımı doğrudan belirliyor: lohia **seyri** kaydedilmeli
(azalıyor mu?), çünkü tehlike işareti tek bir günün değil, **eğilimin**
içinde.

### Doğum sonu depresyonu — EPDS

Rehber Edinburgh Postpartum Depresyon Ölçeği'ni kullanıyor ve şöyle
tanımlıyor: *"Kendini değerlendirme ölçeğidir… kişiler kendi başlarına
doldururlar."* Türkiye için **kesme puanı 12**: *"12 ve üzerindeki
değerleri alan anneler sevk edilmelidir."*

Yani uygulamada sunulabilir — kendi kendine doldurulmak üzere tasarlanmış
bir ölçek. Ama üç koşulla:

1. **10. madde (kendine zarar verme) ayrı.** Toplam puandan bağımsız
   olarak 10. maddeye verilen **sıfır dışındaki her cevap** acil
   değerlendirme gerektirir. Uygulama o an toplamı göstermeyi bırakıp
   kriz hattına ve acile yönlendirmeli. Bu pazarlık konusu değil.
2. **Teşhis değil, yönlendirme.** ≥12 → "bu sonucu bu hafta ebene ya da
   hekimine göster". "Depresyondasınız" asla yazılmaz.
3. **Asla paylaşılmaz.** Partner görünümüne, yedeğe düz metin olarak,
   hiçbir yere. Şifreli depoda.

⚠️ **Yayından önce hukuki kontrol gerekli:** bir tarama ölçeğini puanlayıp
sevk önermek bazı yargı alanlarında yazılımı tıbbi cihaz kapsamına
sokabilir. Bunu ben karara bağlayamam. Güvenli alternatif: EPDS yerine
yalnızca ruh hali takibi + "bunları hissediyorsan konuş" yönlendirmesi.

### Pelvik taban

Rehber açık: *"lohusalara pelvik tabanı güçlendirmeye yönelik
egzersizler öğretilmelidir."* Uygulamada egzersiz ve zamanlayıcılı seans
altyapısı zaten var (`session_screen`, `exercise_detail_screen`). Yeni
altyapı gerektirmeyen, kılavuz destekli bir program.

### Normale dönüş

- 42. günden sonra lohusalık evresi kapanır, döngü evresine geçilir.
- İlk regl ne zaman gelir öngörülemez; emzirmede daha da belirsiz.
  **2–3 döngü kaydedilene kadar tahmin gösterilmez** — "henüz
  tahmin edemiyorum" dürüst cevap.
- Rehber doğum sonu danışmanlık konuları arasında kontrasepsiyonu sayıyor.
  Uygulamanın vermesi gereken tek cümle: **ilk regl gelmeden de gebe
  kalınabilir** — yumurtlama ilk reglden önce olur.
- Demir ve D vitamini desteği lohusalıkta da sürüyor (rehber §5.11);
  gebelikteki hatırlatıcı burada da devam eder.

### Gebelik bittiğinde hatırlatıcılar anında iptal

En kötü senaryo: düşükten iki hafta sonra kilit ekranına *"18–22. hafta:
anomali taraması zamanı"* bildirimi gelmesi. Gebelik hangi sonuçla
biterse bitsin **bütün gebelik hatırlatıcıları aynı anda iptal
edilmeli**. Bu, test altına alınması gereken bir kural — yanlış gittiğinde
geri alınamayacak kadar ağır.

---

## 3. Gebelik planlama — ucuz, ve gebelik moduna giriş kapısı

Bir niyet, ayrı bir evre değil: döngü evresi içinde "gebe kalmak
istiyorum".

- **Folik asit.** Bakanlık rehberi: gebelikten **en az 1 ay önce**
  400–800 µg/gün. Niyet seçildiği gün hatırlatıcı kurulur. Gebe kaldıktan
  sonra başlamak geç; uygulamanın bunu söyleyebileceği tek an bu.
- **Hekime ne zaman?** ASRM: 35 yaş altında 12 ay, 35 ve üstünde 6 ay
  denemeden sonra değerlendirme; 40 üstünde daha erken. Profilde doğum
  tarihi zaten var, niyetin başlangıç tarihi saklanırsa uygulama
  "denemeye başladığın günden bu yana 12 ay geçti" diyebilir. Teşhis
  değil, takvim.
- **Kesintisiz geçiş.** Pozitif test → gebelik modu; son adet tarihi
  zaten biliniyor, kurulum tek dokunuş.

---

## 4. Menopoza geçiş — en az hizmet alan kitle

Döngü uygulamaları 40 yaş üstünde kullanıcı kaybediyor: döngü
düzensizleşiyor, tahminler tutmuyor, kullanıcı uygulamanın bozuk olduğunu
düşünüp bırakıyor. Oysa düzensizlik burada **bilginin kendisi**.

### STRAW+10 — veriden çıkarılabiliyor

| Evre | Ölçüt |
|---|---|
| Erken geçiş | ardışık döngü uzunlukları arasında **≥7 gün** fark, ilkinden sonraki 10 döngü içinde **tekrarlıyor** |
| Geç geçiş | **≥60 gün** adet görmeme |
| Menopoz | son adetten **12 ay** sonra |

Uygulama döngü uzunluklarını ve değişkenliği zaten hesaplıyor (Analiz
ekranı: "en kısa ile en uzun arasında X gün fark"). Yeni veri girişi
gerekmiyor.

İki koşul:

- **Yaş kapısı.** 25 yaşında değişken döngü menopoza geçiş değildir
  (PKOS ya da başka bir sebep olabilir). Profildeki doğum tarihi
  kullanılır; bilinmiyorsa örüntü hiç yorumlanmaz.
- **Tanımlayıcı, teşhis değil.** "Döngülerin son dönemde menopoza geçişte
  görülen bir örüntü gösteriyor; hekimine danışabilirsin."

### Menopoz sonrası evre

12 ay adet görmedikten sonra kanama **tehlike işareti**: NICE NG12, 55
yaş ve üstünde açıklanamayan menopoz sonrası kanamada endometrium kanseri
şüphesiyle hızlı sevk öneriyor, 55 altında da düşünülmesini söylüyor.
Gebelikteki korumanın aynısı: regl kaydı açılmaz, hekime yönlendirilir.

Belirtiler: sıcak basması, gece terlemesi, uyku, ruh hali. (HealthKit'ten
uyku okuma Ekim 2026'da kaldırıldı — hiçbir ekran kullanmıyordu; bu evre
gelirse yeniden ve yalnızca gösterilecekse istenmeli.)

---

## 5. Evrelerden bağımsız farklılaştırıcılar

**Gizli bildirim.** Bugün kilit ekranında *"Reglin yaklaşıyor. Hazırlıklı
olmak ister misin?"* ve *"Doğurganlık pencerene giriyorsun."* yazıyor.
Gebelik ve lohusalıkla bu çok daha hassas hâle geliyor ("12. hafta:
D vitamini", "Lohusa izlemi"). Seçenek: başlık "Nilu", gövde "Bugün için
bir hatırlatman var". Ucuz, ve paylaşılan telefonların yaygın olduğu bir
pazarda gerçek bir fark.

**Her evre için "hekime götür" özeti.** `DataExportService` döngü için
klinik özet zaten üretiyor. Gebelik (izlem notları, hekime sorulacaklar),
lohusalık (lohia seyri; EPDS yalnızca kullanıcı isterse), menopoza geçiş
(STRAW örüntüsünün kanıtı + belirtiler) için genişletilir.

**Ağrı günlüğü → "doktoruna götür".** Ağrının yeri, bağlamı, şiddeti ve
günlük işleri kısıtlayıp kısıtlamadığı zaten kaydediliyor. Endometriozis
gibi tanısı uzun süren durumlarda bu kayıt hekim için değerli. Yeni veri
değil, mevcut verinin paketlenmesi.

**Doğum kontrol hapı hatırlatıcısı.** Rakiplerde var, ucuz,
`ReminderScheduler` ile hazır.

**Partner.** Gebelikte haftayı görebilir — **açık onayla**. EPDS ve
gebeliğin nasıl bittiği **hiçbir koşulda** paylaşılmaz.

---

## 6. Önceliklendirme

Her ekleme yayını geciktirir. Sıralama üç ölçüte göre: doğruluk gereği
mi, ne kadar farklılaştırıyor, ne kadar pahalı.

| Ne | Neden bu sırada | Sürüm |
|---|---|---|
| `LifeStage` mimarisi | lohusalıktan **önce** olmalı, sonra yapmak bütün korumaları yeniden yazmak | **v1** |
| Gebelik Faz 1–2 | karar verildi | **v1** |
| Lohusalık asgarisi: lohia koruması, 3 izlem hatırlatıcısı, tehlike işaretleri, 42. gün dönüşü, tahminsiz başlangıç | gebelik modunun doğru bitmesi için zorunlu | **v1** |
| Gebelik bitince hatırlatıcıların iptali | yanlış gitmesi geri alınamaz | **v1** |
| Gizli bildirim | ucuz, gebelikle birlikte hassasiyet artıyor | **v1** |
| Gebelik planlama niyeti (folik asit + ASRM takvimi) | ucuz, gebelik moduna giriş kapısı | **v1** |
| Pelvik taban programı | altyapı hazır, kılavuz destekli | v1.1 |
| EPDS | değerli ama **hukuki kontrol** gerektiriyor | v1.1 |
| Menopoza geçiş + menopoz sonrası | büyük fark, ama yeni bir evre ve yeni metinler | v1.2 |
| Ağrı günlüğü paketlemesi, hap hatırlatıcısı | ucuz ama acil değil | v1.2 |
| Haftalık gebelik içeriği, partner gebelik görünümü | 6 dilde içerik maliyeti | sonra |

---

## Kaynaklar

- T.C. Sağlık Bakanlığı, Halk Sağlığı Genel Müdürlüğü, *Doğum Sonu Bakım
  Yönetim Rehberi*, Ankara 2018 — altı izlem, tehlike işaretleri, EPDS
  kullanım kılavuzu ve Türkiye kesme puanı (12), pelvik taban:
  https://platform.who.int/docs/default-source/mca-documents/policy-documents/guideline/TUR-MN-48-04-GUIDELINE-2018-tur-Postnatal-Care-Management-Guidelines.pdf
  (Bakanlık kopyası: https://dosyaism.saglik.gov.tr/Eklenti/115526/0/dogum-sonu-bakim-rehberi-2018pdf.pdf)
- T.C. Sağlık Bakanlığı, *Doğum Öncesi Bakım Yönetim Rehberi*, Ankara 2018
  — folik asit takvimi (bkz. PREGNANCY_MODE.md)
- EPDS 10. madde: toplam puandan bağımsız acil değerlendirme —
  King Edward Memorial Hospital, *EPDS Referral Pathway*:
  https://www.kemh.health.wa.gov.au/~/media/HSPs/NMHS/Hospitals/WNHS/Documents/Professionals/SPIMHP/WNHS-EPDS-Referral-Pathway.pdf ;
  Black Dog Institute, *Edinburgh Postnatal Depression Scale*:
  https://www.blackdoginstitute.org.au/wp-content/uploads/2020/04/edinburgh-postnatal-depression-scale.pdf
- STRAW+10 — ASRM, *Executive summary of the Stages of Reproductive Aging
  Workshop + 10*:
  https://www.asrm.org/practice-guidance/practice-committee-documents/executive-summary-of-the-stages-of-reproductive-aging-workshopd10-addressing-the-unfinished-agenda-of-staging-reproductive-aging-2012/
- NICE NG12, *Suspected cancer: recognition and referral* — menopoz
  sonrası kanama:
  https://www.nice.org.uk/guidance/ng12/chapter/Recommendations-organised-by-site-of-cancer
- ASRM, *Fertility evaluation of infertile women: a committee opinion*
  (2021) — 12 ay / 6 ay:
  https://www.asrm.org/practice-guidance/practice-committee-documents/fertility-evaluation-of-infertile-women-a-committee-opinion-2021/
