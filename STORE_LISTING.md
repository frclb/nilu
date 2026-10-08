# Mağaza metinleri

App Store Connect'e girilecek metinler, altı dilde.

Karakter sınırları: **ad 30**, **alt başlık 30**, **tanıtım metni 170**,
**anahtar kelimeler 100** (virgülle, boşluksuz), **açıklama 4000**.

Sınırlar `tool/check_store_listing.py` ile denetleniyor.

---

## Uygulama adı

**Nilu.**

Nilüfer'den geliyor; o da Farsça *nilūfar*'a, Sanskritçe "mavi lotus"a
dayanıyor. Marka işareti zaten nilüfer — ad ile ikon aynı kökten.

Dört harf, özel karakter yok, altı dilin hepsinde yazılıp okunabiliyor.

> **Müsaitliğini App Store Connect'te doğrula.** Ad benzersiz olmak zorunda
> ve ilk kullanan üzerine kilitleniyor. Alınmışsa yedekler: *Nila*, *Ayla*,
> *Neva*.

Uygulamanın ana ekranda görünen adı (`CFBundleDisplayName`) ve widget
galerisindeki adı **Nilu**. Mağaza adı ile cihazdaki ad birebir aynı olmak
zorunda değil ama birbirinden uzak düşmemeli.

### Ada eklenen açıklama dilden dile değişir

App Store adı **her dil için ayrı** giriliyor. Marka kısmı sabit, arkasına
gelen açıklama o pazarın aradığı kelime oluyor:

| Dil | Ad |
|---|---|
| Türkçe | Nilu · Regl & Adet Takvimi |
| English | Nilu · Period Tracker |
| Deutsch | Nilu · Zyklus-Tracker |
| Español | Nilu · Ciclo Menstrual |
| Français | Nilu · Suivi de Règles |
| Português | Nilu · Ciclo Menstrual |

Açıklama eklemenin sebebi arama: Apple ad alanını dizinliyor ve kimsenin
bilmediği bir markada "Nilu" tek başına hiçbir sonuçta çıkmaz.

Ama **ad, alt başlık ve anahtar kelimeler üçü de dizinleniyor** — aynı
kelimeyi ikisine birden yazmak yer israfı. Bu yüzden anahtar kelime
listelerinde adda geçen sözcükler yok.

Türkçe ad üç arama terimini birden taşıyor: **regl**, **adet**, **takvim**.
İkisi eşanlamlı ve yan yana biraz SEO kokuyor, ama ad alanı Apple'ın en
ağır dizinlediği yer ve tanınmayan bir markada keşfedilebilirlik metnin
zarafetinden önce geliyor. Bu kategoride standart bir kalıp.

Karşılığında anahtar kelimelerde yer açıldı: regl, adet ve takvim oradan
çıktı, yerlerine **takip**, **ağrı**, **gebelik** ve **hamilelik** girdi.
Gebelik modu uygulamanın ikinci büyük parçası; aranıyor ve ad alanında yok.

Hangi terimin daha çok arandığını ölçemiyorum. Bedava bir sinyal var:
App Store'un arama kutusuna "regl", "adet", "takvim", "takip" yazıp
otomatik tamamlamaya bak — öneriler popülerliğe göre sıralı geliyor.
Sıralama beklediğinden farklıysa addaki kelimeyi değiştirmek tek satır.

Aynı mantık diğer beş dilde de uygulanabilir; her pazarın hangi eşanlamlı
çifti aradığına oradaki otomatik tamamlamaya bakarak karar vermek gerekiyor.

---

## Türkçe

**Ad**
```
Nilu · Regl & Adet Takvimi
```

**Alt başlık**
```
Döngün sende kalır
```

**Tanıtım metni**
```
Bedenini tanımak için sakin bir yer. Döngün, gebeliğin ve notların telefonunda kalıyor — hesap yok, izleme yok.
```

**Açıklama**
```
Yazdıkların sende kalıyor. Gerçekten.

Regl uygulamalarının çoğu işaretlediğin günleri, belirtilerini ve notlarını kendi sunucularına taşır. Nilu taşımıyor. Hepsi telefonunda, şifreli duruyor. Hesap açman bile gerekmiyor.

Çünkü bunlar senin. Kimsenin okumasına, saklamasına ya da satmasına gerek yok.

GÜNLÜK HAYATINDA

• Takvim — reglini işaretle, bir sonrakini ve doğurgan dönemini gör
• Günlük — akış, ağrı, ruh hâli, belirtiler. Canın isterse iki kelime not
• Geçmiş — bütün döngülerin, ortalaman, en kısa ve en uzun döngün
• Kütüphane — hormonlar, beslenme, PMS ve ruh hâli üzerine kaynak gösterilen yazılar
• Hareket — dönemine göre hafif yoga ve esneme akışları
• Apple Sağlık — regl kayıtlarını içeri al; istersen işaretlediğin günleri geri yaz
• Hatırlatıcılar — bildirimler telefonunda hazırlanır, içerikleri hiçbir yere gitmez
• Ana ekran widget'ı — döngü günün, gebelik haftan ya da lohusalık günün bir bakışta

GEBELİKTE VE DOĞUMDAN SONRA

• Gebelik modu — hafta ve gün, ay ve trimester; tahmini doğum tarihi son reglinden ya da hekiminin verdiği tarihten
• Sağlık Bakanlığı rehberine göre izlem ve tarama zamanları; kendi randevularını da ekleyebilirsin
• Tehlike işaretleri — beklemeden başvurman gereken durumlar
• Tansiyon ve kilo kaydı; muayenede ekrandan gösterebileceğin özet
• Lohusalık — doğumdan sonraki 42 gün ve kanamanın seyri
• Gebelik bitince regl takibine dönüş; geçmiş gebeliklerin saklanır

GİZLİLİK SONRADAN EKLENMEDİ

Bir özellik listesine sıkıştırılmış bir madde değil; uygulama baştan böyle kuruldu.

• Döngü verin telefonundan çıkmıyor
• Reklamlar kişiselleştirilmiyor. Reklam kimliğin kullanılmıyor, izleme izni istenmiyor
• Sağlık verin hiçbir koşulda reklam için kullanılmıyor
• Ekran kilidi ücretsiz — Face ID ya da telefonunun şifresiyle
• Yedeğini ve verinin okunabilir bir kopyasını istediğin an alabilirsin, ücretsiz
• Bütün verini uygulamanın içinden silebilirsin

İSTERSEN PARTNERİNLE

Partnerine yalnızca paylaşmayı seçtiğin yakınlık durumu gider. Döngü tarihlerin, belirtilerin, notların gitmez. Fikrin değişirse erişimi geri alırsın; verdiğin kodu iptal edebilirsin.

Bazı günler anlatmak zor geliyor. Bu, anlatmanın sessiz bir yolu.

PREMIUM

• Tüm geçmişle döngü trendi — trend grafiği ücretsiz sürümde son 3 döngüyü gösterir
• Belirti–evre analizi — belirtilerin döngünün hangi evresinde yoğunlaşıyor
• Hekime götürebileceğin özet ve tabloyu dosya olarak paylaşma
• Özel temalar
• Reklamsız kullanım

Döngü geçmişinin listesi, gebelik modu, ekran kilidi ve yedek alma premium'da değil. Hepsi herkese açık, öyle kalacak.

BİLMEN GEREKENLER

Nilu tıbbi teşhis koymaz, tedavi önermez ve bir doğum kontrol yöntemi değildir. Tahminler geçmiş kayıtlarından hesaplanır, yani yaklaşıktır. Gebelik modu hekim ve ebe izleminin yerini tutmaz. Bedeninle ilgili bir endişen varsa bir hekime danış.
```

**Anahtar kelimeler**
```
takip,döngü,ovulasyon,yumurtlama,doğurganlık,gebelik,hamilelik,pms,semptom,kadın,ağrı
```

---

## English

**Name**
```
Nilu · Period Tracker
```

**Subtitle**
```
Your cycle stays on your phone
```

**Promotional text**
```
Log your period, understand your cycle. Your data is written to your device, not a server — no account, no tracking.
```

**Description**
```
Your cycle data never leaves your phone.

Most period apps move the days you log, your symptoms and your notes to their own servers. Nilu doesn't. It all stays on your device, encrypted. You don't need an account.

WHAT IT DOES

• Calendar — mark your period, see predictions and your fertile window
• Daily log — flow, pain, mood, symptoms, notes
• History — every cycle, your average, your shortest and longest cycle
• Health library — sourced articles on hormones, nutrition, PMS and mood
• Movement — gentle yoga and stretching flows matched to your phase
• Apple Health — import your period records and, if you want, write the days you mark back
• Reminders — notifications are built on your device and their contents go nowhere
• Home Screen widget — your cycle day, pregnancy week or postnatal day at a glance

PREGNANCY AND AFTER BIRTH

• Pregnancy mode — weeks and days, month and trimester; due date from your last period or the date your clinician gave you
• Add your checkups and appointments and get reminders
• Warning signs — when to seek care without waiting
• Blood pressure and weight log; a summary you can show at your appointment
• Postnatal period — the 42 days after birth and how your bleeding changes
• Back to cycle tracking when your pregnancy ends; past pregnancies are kept

PRIVACY ISN'T A FEATURE HERE, IT'S THE ARCHITECTURE

• Your cycle data never leaves the device
• Ads are not personalised; no advertising identifier, no tracking prompt
• Your health data is never used for ad targeting
• App lock is free — Face ID or your device passcode
• You can export a backup and a machine-readable copy of your data at any time, free
• You can delete all your data from inside the app

PARTNER SHARING — IF YOU WANT IT

Only the closeness status you choose to share reaches your partner. Your cycle dates, symptoms and notes do not. You can revoke access whenever you like; the code you shared can be cancelled.

PREMIUM

• Cycle trend across your whole history — the free trend chart shows your last 3 cycles
• Symptom–phase analysis — which phase your symptoms concentrate in
• Share a summary and table for your doctor as a file
• Custom themes
• No ads

Your cycle history list, pregnancy mode, app lock and backups are not behind the paywall. They are free for everyone.

WHAT YOU SHOULD KNOW

Nilu does not diagnose, does not prescribe treatment, and is not a contraceptive method. Predictions are calculated from your past entries and are approximate. Pregnancy mode does not replace care from your doctor or midwife. If you're worried about your health, talk to a doctor.
```

**Keywords**
```
menstrual,ovulation,fertility,pregnancy,pms,symptom,calendar,privacy,women,diary,cramps
```

---

## Deutsch

**Name**
```
Nilu · Zyklus-Tracker
```

**Untertitel**
```
Dein Zyklus bleibt bei dir
```

**Werbetext**
```
Periode eintragen, Zyklus verstehen. Deine Daten liegen auf deinem Gerät, nicht auf einem Server — ohne Konto, ohne Tracking.
```

**Beschreibung**
```
Deine Zyklusdaten verlassen dein Telefon nicht.

Die meisten Perioden-Apps übertragen deine eingetragenen Tage, Symptome und Notizen auf eigene Server. Nilu nicht. Alles bleibt verschlüsselt auf deinem Gerät. Ein Konto brauchst du nicht.

WAS DIE APP KANN

• Kalender — Periode eintragen, Vorhersagen und fruchtbare Tage sehen
• Tägliches Protokoll — Blutung, Schmerzen, Stimmung, Symptome, Notizen
• Verlauf — alle Zyklen, dein Durchschnitt, dein kürzester und längster Zyklus
• Gesundheitsbibliothek — belegte Artikel zu Hormonen, Ernährung, PMS und Stimmung
• Bewegung — sanfte Yoga- und Dehnabläufe passend zur Zyklusphase
• Apple Health — Periodendaten importieren und, wenn du willst, eingetragene Tage zurückschreiben
• Erinnerungen — Mitteilungen entstehen auf deinem Gerät, ihre Inhalte gehen nirgendwohin
• Widget für den Home-Bildschirm — Zyklustag, Schwangerschaftswoche oder Tag im Wochenbett auf einen Blick

SCHWANGERSCHAFT UND NACH DER GEBURT

• Schwangerschaftsmodus — Wochen und Tage, Monat und Trimester; errechneter Geburtstermin aus deiner letzten Periode oder der Termin, den dir deine Ärztin genannt hat
• Vorsorgetermine eintragen und erinnert werden
• Warnzeichen — wann du nicht warten solltest
• Blutdruck und Gewicht eintragen; eine Übersicht zum Zeigen beim Termin
• Wochenbett — die 42 Tage nach der Geburt und der Verlauf der Blutung
• Nach der Schwangerschaft zurück zum Zyklus; frühere Schwangerschaften bleiben gespeichert

DATENSCHUTZ IST HIER KEIN FEATURE, SONDERN DIE BAUWEISE

• Deine Zyklusdaten verlassen das Gerät nicht
• Werbung wird nicht personalisiert; keine Werbe-ID, keine Tracking-Abfrage
• Deine Gesundheitsdaten werden nie für Werbung genutzt
• App-Sperre ist kostenlos — Face ID oder Gerätecode
• Du kannst jederzeit ein Backup und eine maschinenlesbare Kopie deiner Daten exportieren, kostenlos
• Du kannst alle deine Daten in der App löschen

PARTNER-FREIGABE — WENN DU WILLST

Bei deinem Partner kommt nur der Nähe-Status an, den du teilst. Zyklusdaten, Symptome und Notizen nicht. Du kannst den Zugriff jederzeit entziehen; der geteilte Code lässt sich widerrufen.

PREMIUM

• Zyklustrend über deinen ganzen Verlauf — kostenlos zeigt das Trenddiagramm die letzten 3 Zyklen
• Symptom-Phasen-Analyse
• Zusammenfassung und Tabelle für den Arztbesuch als Datei teilen
• Eigene Themes
• Ohne Werbung

Zyklusverlauf, Schwangerschaftsmodus, App-Sperre und Backup stehen nicht hinter der Bezahlschranke. Alles ist für alle kostenlos.

WAS DU WISSEN SOLLTEST

Nilu stellt keine Diagnose, empfiehlt keine Behandlung und ist kein Verhütungsmittel. Vorhersagen werden aus deinen früheren Einträgen berechnet und sind ungefähr. Der Schwangerschaftsmodus ersetzt nicht die Betreuung durch Ärztin, Arzt oder Hebamme. Bei gesundheitlichen Sorgen wende dich an eine Ärztin oder einen Arzt.
```

**Keywords**
```
periode,menstruation,eisprung,fruchtbar,pms,symptome,kalender,datenschutz,frau,tagebuch,regel
```

---

## Español

**Nombre**
```
Nilu · Ciclo Menstrual
```

**Subtítulo**
```
Tu ciclo se queda en tu móvil
```

**Texto promocional**
```
Registra tu regla y entiende tu ciclo. Tus datos se guardan en tu dispositivo, no en un servidor: sin cuenta y sin rastreo.
```

**Descripción**
```
Los datos de tu ciclo no salen de tu teléfono.

La mayoría de las apps de regla llevan los días que registras, tus síntomas y tus notas a sus propios servidores. Nilu no. Todo se queda cifrado en tu dispositivo. No necesitas crear una cuenta.

QUÉ HACE

• Calendario — marca tu regla y consulta las previsiones y los días fértiles
• Registro diario — flujo, dolor, ánimo, síntomas y notas
• Historial — todos tus ciclos, tu media, tu ciclo más corto y el más largo
• Biblioteca de salud — artículos con fuentes sobre hormonas, alimentación, SPM y ánimo
• Movimiento — yoga suave y estiramientos según la fase del ciclo
• Apple Salud — importa tus registros de regla y, si quieres, guarda allí los días que marcas
• Recordatorios — las notificaciones se crean en tu dispositivo y su contenido no va a ninguna parte
• Widget de pantalla de inicio — tu día del ciclo, tu semana de embarazo o tu día de posparto de un vistazo

EMBARAZO Y DESPUÉS DEL PARTO

• Modo embarazo — semanas y días, mes y trimestre; fecha prevista de parto según tu última regla o la que te dio tu médico
• Añade tus controles y citas y recibe recordatorios
• Señales de alarma — cuándo acudir sin esperar
• Registro de tensión y peso; un resumen para enseñar en la consulta
• Posparto — los 42 días tras el parto y la evolución del sangrado
• Al terminar el embarazo vuelves al seguimiento del ciclo; los embarazos anteriores se guardan

AQUÍ LA PRIVACIDAD NO ES UNA FUNCIÓN, ES LA ESTRUCTURA

• Los datos de tu ciclo no salen del dispositivo
• Los anuncios no se personalizan; sin identificador publicitario ni permiso de rastreo
• Tus datos de salud nunca se usan para segmentar anuncios
• El bloqueo de la app es gratis — con Face ID o el código del dispositivo
• Puedes exportar una copia de seguridad y una copia legible por máquina cuando quieras, gratis
• Puedes borrar todos tus datos desde la propia app

COMPARTIR CON TU PAREJA — SI QUIERES

A tu pareja solo le llega el estado de cercanía que decides compartir. Ni las fechas de tu ciclo, ni tus síntomas, ni tus notas. Puedes retirar el acceso cuando quieras; el código compartido se puede anular.

PREMIUM

• Tendencia del ciclo con todo tu historial — gratis, el gráfico muestra los 3 últimos ciclos
• Análisis síntoma–fase
• Compartir como archivo un resumen y una tabla para tu médico
• Temas personalizados
• Sin anuncios

El historial de ciclos, el modo embarazo, el bloqueo de la app y las copias de seguridad no están detrás del muro de pago. Son gratis para todo el mundo.

LO QUE DEBES SABER

Nilu no diagnostica, no recomienda tratamientos y no es un método anticonceptivo. Las previsiones se calculan a partir de tus registros anteriores y son aproximadas. El modo embarazo no sustituye el seguimiento de tu médico o matrona. Si te preocupa tu salud, consulta a un profesional médico.
```

**Palabras clave**
```
regla,ovulacion,fertilidad,sintomas,calendario,mujer,periodo,privacidad,salud,diario,dolor
```

---

## Français

**Nom**
```
Nilu · Suivi de Règles
```

**Sous-titre**
```
Ton cycle reste sur ton mobile
```

**Texte promotionnel**
```
Note tes règles, comprends ton cycle. Tes données sont écrites sur ton appareil, pas sur un serveur — sans compte, sans pistage.
```

**Description**
```
Les données de ton cycle ne quittent pas ton téléphone.

La plupart des applis de règles envoient les jours que tu notes, tes symptômes et tes notes sur leurs propres serveurs. Nilu non. Tout reste chiffré sur ton appareil. Aucun compte n'est nécessaire.

CE QU'ELLE FAIT

• Calendrier — note tes règles, vois les prévisions et ta période fertile
• Journal quotidien — flux, douleurs, humeur, symptômes, notes
• Historique — tous tes cycles, ta moyenne, ton cycle le plus court et le plus long
• Bibliothèque santé — des articles sourcés sur les hormones, l'alimentation, le SPM et l'humeur
• Mouvement — yoga doux et étirements adaptés à ta phase
• Apple Santé — importe tes règles et, si tu veux, enregistre-y les jours que tu notes
• Rappels — les notifications sont créées sur ton appareil et leur contenu ne part nulle part
• Widget d'écran d'accueil — ton jour du cycle, ta semaine de grossesse ou ton jour de post-partum en un coup d'œil

GROSSESSE ET APRÈS LA NAISSANCE

• Mode grossesse — semaines et jours, mois et trimestre ; terme calculé à partir de tes dernières règles ou de la date donnée par ton médecin
• Ajoute tes consultations et rendez-vous et reçois des rappels
• Signes d'alerte — quand consulter sans attendre
• Suivi de la tension et du poids ; un résumé à montrer en consultation
• Post-partum — les 42 jours après la naissance et l'évolution des saignements
• Retour au suivi du cycle à la fin de la grossesse ; les grossesses passées sont conservées

ICI LA CONFIDENTIALITÉ N'EST PAS UNE OPTION, C'EST L'ARCHITECTURE

• Les données de ton cycle ne quittent pas l'appareil
• Les publicités ne sont pas personnalisées ; aucun identifiant publicitaire, aucune demande de pistage
• Tes données de santé ne servent jamais au ciblage publicitaire
• Le verrouillage de l'app est gratuit — Face ID ou code de l'appareil
• Tu peux exporter une sauvegarde et une copie lisible par machine quand tu veux, gratuitement
• Tu peux supprimer toutes tes données depuis l'app

PARTAGE AVEC UN PARTENAIRE — SI TU VEUX

Seul l'état de proximité que tu choisis de partager lui parvient. Ni tes dates de cycle, ni tes symptômes, ni tes notes. Tu peux retirer l'accès quand tu veux ; le code partagé est révocable.

PREMIUM

• Tendance du cycle sur tout ton historique — en version gratuite, le graphique montre les 3 derniers cycles
• Analyse symptôme–phase
• Partager en fichier un résumé et un tableau pour ton médecin
• Thèmes personnalisés
• Sans publicité

L'historique des cycles, le mode grossesse, le verrouillage et les sauvegardes ne sont pas derrière le paywall. Tout cela est gratuit pour tout le monde.

CE QU'IL FAUT SAVOIR

Nilu ne pose pas de diagnostic, ne prescrit aucun traitement et n'est pas un moyen de contraception. Les prévisions sont calculées à partir de tes saisies passées et restent approximatives. Le mode grossesse ne remplace pas le suivi par ton médecin ou ta sage-femme. En cas d'inquiétude, consulte un médecin.
```

**Mots-clés**
```
menstruel,ovulation,fertilite,spm,symptomes,calendrier,femme,confidentialite,journal,douleur
```

---

## Português

**Nome**
```
Nilu · Ciclo Menstrual
```

**Subtítulo**
```
Seu ciclo fica no seu celular
```

**Texto promocional**
```
Registre a menstruação e entenda seu ciclo. Seus dados ficam no seu aparelho, não num servidor — sem conta e sem rastreamento.
```

**Descrição**
```
Os dados do seu ciclo não saem do seu celular.

A maioria dos apps de menstruação leva os dias que você registra, seus sintomas e suas anotações para os próprios servidores. O Nilu não. Tudo fica criptografado no seu aparelho. Você não precisa criar conta.

O QUE ELE FAZ

• Calendário — marque a menstruação e veja as previsões e o período fértil
• Registro diário — fluxo, dor, humor, sintomas e anotações
• Histórico — todos os seus ciclos, sua média, seu ciclo mais curto e o mais longo
• Biblioteca de saúde — artigos com fontes sobre hormônios, alimentação, TPM e humor
• Movimento — ioga leve e alongamentos de acordo com a fase do ciclo
• Apple Saúde — importe seus registros de menstruação e, se quiser, grave lá os dias que você marca
• Lembretes — as notificações são criadas no seu aparelho e o conteúdo não vai para lugar nenhum
• Widget da Tela de Início — seu dia do ciclo, sua semana de gravidez ou seu dia de pós-parto num relance

GRAVIDEZ E DEPOIS DO PARTO

• Modo gravidez — semanas e dias, mês e trimestre; data provável do parto pela última menstruação ou pela data que seu médico informou
• Adicione suas consultas e exames e receba lembretes
• Sinais de alerta — quando procurar atendimento sem esperar
• Registro de pressão e peso; um resumo para mostrar na consulta
• Pós-parto — os 42 dias depois do parto e a evolução do sangramento
• Quando a gravidez termina, você volta a acompanhar o ciclo; as gestações anteriores ficam guardadas

AQUI A PRIVACIDADE NÃO É UM RECURSO, É A ESTRUTURA

• Os dados do seu ciclo não saem do aparelho
• Os anúncios não são personalizados; sem identificador de publicidade e sem pedido de rastreamento
• Seus dados de saúde nunca são usados para segmentar anúncios
• O bloqueio do app é gratuito — com Face ID ou o código do aparelho
• Você pode exportar um backup e uma cópia legível por máquina quando quiser, de graça
• Você pode apagar todos os seus dados dentro do próprio app

COMPARTILHAR COM SEU PARCEIRO — SE QUISER

Ao seu parceiro chega apenas o status de proximidade que você escolhe compartilhar. As datas do ciclo, os sintomas e as anotações não. Você pode retirar o acesso quando quiser; o código compartilhado pode ser cancelado.

PREMIUM

• Tendência do ciclo com todo o seu histórico — na versão gratuita, o gráfico mostra os últimos 3 ciclos
• Análise sintoma–fase
• Compartilhar como arquivo um resumo e uma tabela para o seu médico
• Temas personalizados
• Sem anúncios

O histórico de ciclos, o modo gravidez, o bloqueio do app e os backups não ficam atrás do paywall. São gratuitos para todo mundo.

O QUE VOCÊ PRECISA SABER

O Nilu não faz diagnóstico, não indica tratamento e não é um método contraceptivo. As previsões são calculadas a partir dos seus registros anteriores e são aproximadas. O modo gravidez não substitui o acompanhamento do seu médico ou da sua obstetriz. Se estiver preocupada com a sua saúde, fale com um médico.
```

**Palavras-chave**
```
menstruacao,periodo,ovulacao,fertilidade,tpm,sintomas,calendario,gravidez,saude,privacidade
```

---

## Notlar

**Açıklamada fiyat yazmıyor.** Bilerek: fiyat değiştiğinde altı dilde metin
güncellemek gerekirdi ve eski fiyat bir süre yayında kalırdı. Abonelik
bilgisi paywall'da ve App Store'un kendi abonelik bölümünde görünüyor.

**"Gizlilik bir özellik değil" bölümünde yazan her madde uygulamada
gerçekten var.** Mağaza metninde vaat edilip uygulamada bulunmayan bir şey
hem ret sebebi hem kötü bir yorum sebebi. Liste
[STORE_CHECKLIST.md](STORE_CHECKLIST.md) §4'teki beyanlarla eşleşiyor.

**Premium listesi paywall ile birebir aynı.** İkisi ayrışırsa kullanıcı
ödediğini bulamaz. Kaynak: `premium_feature_*` anahtarları. Döngü
geçmişinin listesi ücretsiz (`CycleHistoryCard`); Premium'un kattığı, tüm
geçmişle trend grafiği.

**Portekizce Brezilya Portekizcesi (pt-BR).** Uygulamanın `pt.json`'u da
aynı lehçede: "você", "celular", "registro". App Store Connect'te dil
**Portuguese (Brazil)** seçilmeli; Portekiz için ayrı yerelleştirme yok.

**Uyku kaydı ve nefes egzersizi yazılmıyor.** Önceki metin ikisini de
vaat ediyordu; uygulamada ikisi de yok. Sağlık'tan yalnızca regl okunuyor.

**Tıbbi uyarı her dilde var.** İnceleme sağlık iddialarına bakıyor ve
uygulama zaten Şartlar'da teşhis koymadığını söylüyor; mağaza metni de
aynı şeyi söylemeli.
