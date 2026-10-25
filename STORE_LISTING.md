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
Bedenini tanımak için sakin bir yer. Döngün, gebeliğin ve notların telefonunda kalıyor — hesap zorunlu değil, izleme yok.
```

**Açıklama**
```
Yazdıkların sende kalıyor. Gerçekten.

Regl uygulamalarının çoğu işaretlediğin günleri, belirtilerini ve notlarını kendi sunucularına taşır. Nilu taşımıyor. Hepsi telefonunda, şifreli duruyor. Hesap açman bile gerekmiyor; buluta yedeklemek isteğe bağlı ve yalnızca senin açık rızanla.

Çünkü bunlar senin. Kimsenin okumasına, saklamasına ya da satmasına gerek yok.

GÜNLÜK HAYATINDA

• Takvim — reglini işaretle; bir sonrakini aralıkla ve nasıl hesaplandığıyla, tahmini doğurgan dönemini de gör
• Günlük — akış, ağrı, ruh hâli, belirtiler. Canın isterse iki kelime not
• Geçmiş — bütün döngülerin, ortalaman, en kısa ve en uzun döngün
• Verine sor — "Reglime kaç gün kaldı?" gibi sorulara kendi kayıtlarından hesaplanan cevaplar. Sohbet robotu değil; soruların telefonundan çıkmaz
• Kütüphane — hormonlar, beslenme, PMS ve ruh hâli üzerine kaynak gösterilen yazılar
• Hareket — dönemine göre hafif yoga ve esneme akışları
• Apple Sağlık — regl kayıtlarını içeri al; istersen işaretlediğin günleri geri yaz
• Hatırlatıcılar — kaç gün önce ve hangi saatte, sen seç; bildirimler telefonunda hazırlanır, içerikleri hiçbir yere gitmez
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

• Döngü verin telefonundan çıkmıyor — buluta yedeklemeyi sen açmadıkça
• İstersen Apple ya da Google hesabınla bulut yedeği: yeni telefona geçince kayıtların gelir, kapatınca buluttaki kopya silinir
• Reklamlar kişiselleştirilmiyor. Reklam kimliğin kullanılmıyor, izleme izni istenmiyor
• Sağlık verin hiçbir koşulda reklam için kullanılmıyor
• Ekran kilidi ücretsiz — Face ID ya da telefonunun şifresiyle
• Yedeğini ve verinin okunabilir bir kopyasını istediğin an alabilirsin, istersen parolayla şifreli, ücretsiz
• Sade ana ekran simgesi ve gizli bildirim — kimse ne takip ettiğini görmesin
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
Log your period, understand your cycle. Your data is written to your device, not a server — no account required, no tracking.
```

**Description**
```
Your cycle data stays on your phone.

Most period apps move the days you log, your symptoms and your notes to their own servers. Nilu doesn't. It all stays on your device, encrypted. You don't need an account; cloud backup is optional and only with your explicit consent.

WHAT IT DOES

• Calendar — mark your period; see the next one as a range, with how it was calculated, plus your estimated fertile window
• Daily log — flow, pain, mood, symptoms, notes
• History — every cycle, your average, your shortest and longest cycle
• Ask your data — answers to questions like “How many days until my period?”, calculated from your own entries. Not a chatbot; your questions never leave your phone
• Health library — sourced articles on hormones, nutrition, PMS and mood
• Movement — gentle yoga and stretching flows matched to your phase
• Apple Health — import your period records and, if you want, write the days you mark back
• Reminders — you choose how many days ahead and what time; notifications are built on your device and their contents go nowhere
• Home Screen widget — your cycle day, pregnancy week or postnatal day at a glance

PREGNANCY AND AFTER BIRTH

• Pregnancy mode — weeks and days, month and trimester; due date from your last period or the date your clinician gave you
• Add your checkups and appointments and get reminders
• Warning signs — when to seek care without waiting
• Blood pressure and weight log; a summary you can show at your appointment
• Postnatal period — the 42 days after birth and how your bleeding changes
• Back to cycle tracking when your pregnancy ends; past pregnancies are kept

PRIVACY ISN'T A FEATURE HERE, IT'S THE ARCHITECTURE

• Your cycle data never leaves the device unless you turn on cloud backup
• Optional cloud backup with your Apple or Google account: your entries follow you to a new phone, and turning it off deletes the cloud copy
• Ads are not personalised; no advertising identifier, no tracking prompt
• Your health data is never used for ad targeting
• App lock is free — Face ID or your device passcode
• You can export a backup and a machine-readable copy of your data at any time, optionally password-encrypted, free
• A plain home-screen icon and discreet notifications — no one sees what you track
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
Periode eintragen, Zyklus verstehen. Deine Daten liegen auf deinem Gerät, nicht auf einem Server — kein Konto nötig, kein Tracking.
```

**Beschreibung**
```
Deine Zyklusdaten bleiben auf deinem Telefon.

Die meisten Perioden-Apps übertragen deine eingetragenen Tage, Symptome und Notizen auf eigene Server. Nilu nicht. Alles bleibt verschlüsselt auf deinem Gerät. Ein Konto brauchst du nicht; ein Cloud-Backup ist freiwillig und nur mit deiner ausdrücklichen Einwilligung.

WAS DIE APP KANN

• Kalender — Periode eintragen; die nächste als Zeitraum sehen, mit Erklärung der Berechnung, dazu die geschätzten fruchtbaren Tage
• Tägliches Protokoll — Blutung, Schmerzen, Stimmung, Symptome, Notizen
• Verlauf — alle Zyklen, dein Durchschnitt, dein kürzester und längster Zyklus
• Frag deine Daten — Antworten auf Fragen wie „Wie viele Tage bis zu meiner Periode?“, berechnet aus deinen eigenen Einträgen. Kein Chatbot; deine Fragen verlassen dein Handy nicht
• Gesundheitsbibliothek — belegte Artikel zu Hormonen, Ernährung, PMS und Stimmung
• Bewegung — sanfte Yoga- und Dehnabläufe passend zur Zyklusphase
• Apple Health — Periodendaten importieren und, wenn du willst, eingetragene Tage zurückschreiben
• Erinnerungen — du wählst, wie viele Tage vorher und um wie viel Uhr; Mitteilungen entstehen auf deinem Gerät, ihre Inhalte gehen nirgendwohin
• Widget für den Home-Bildschirm — Zyklustag, Schwangerschaftswoche oder Tag im Wochenbett auf einen Blick

SCHWANGERSCHAFT UND NACH DER GEBURT

• Schwangerschaftsmodus — Wochen und Tage, Monat und Trimester; errechneter Geburtstermin aus deiner letzten Periode oder der Termin, den dir deine Ärztin genannt hat
• Vorsorgetermine eintragen und erinnert werden
• Warnzeichen — wann du nicht warten solltest
• Blutdruck und Gewicht eintragen; eine Übersicht zum Zeigen beim Termin
• Wochenbett — die 42 Tage nach der Geburt und der Verlauf der Blutung
• Nach der Schwangerschaft zurück zum Zyklus; frühere Schwangerschaften bleiben gespeichert

DATENSCHUTZ IST HIER KEIN FEATURE, SONDERN DIE BAUWEISE

• Deine Zyklusdaten verlassen das Gerät nicht, außer du schaltest das Cloud-Backup ein
• Freiwilliges Cloud-Backup mit deinem Apple- oder Google-Konto: Deine Einträge kommen mit aufs neue Handy, und beim Ausschalten wird die Cloud-Kopie gelöscht
• Werbung wird nicht personalisiert; keine Werbe-ID, keine Tracking-Abfrage
• Deine Gesundheitsdaten werden nie für Werbung genutzt
• App-Sperre ist kostenlos — Face ID oder Gerätecode
• Du kannst jederzeit ein Backup und eine maschinenlesbare Kopie deiner Daten exportieren, auf Wunsch passwortverschlüsselt, kostenlos
• Ein schlichtes Home-Bildschirm-Symbol und diskrete Mitteilungen — niemand sieht, was du erfasst
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
Registra tu regla y entiende tu ciclo. Tus datos se guardan en tu dispositivo, no en un servidor: sin cuenta obligatoria y sin rastreo.
```

**Descripción**
```
Los datos de tu ciclo se quedan en tu teléfono.

La mayoría de las apps de regla llevan los días que registras, tus síntomas y tus notas a sus propios servidores. Nilu no. Todo se queda cifrado en tu dispositivo. No necesitas crear una cuenta; la copia en la nube es opcional y solo con tu consentimiento explícito.

QUÉ HACE

• Calendario — marca tu regla; consulta la siguiente como un rango, con cómo se calculó, y tus días fértiles estimados
• Registro diario — flujo, dolor, ánimo, síntomas y notas
• Historial — todos tus ciclos, tu media, tu ciclo más corto y el más largo
• Pregunta a tus datos — respuestas a preguntas como «¿Cuántos días faltan para mi regla?», calculadas a partir de tus propios registros. No es un chatbot; tus preguntas no salen de tu móvil
• Biblioteca de salud — artículos con fuentes sobre hormonas, alimentación, SPM y ánimo
• Movimiento — yoga suave y estiramientos según la fase del ciclo
• Apple Salud — importa tus registros de regla y, si quieres, guarda allí los días que marcas
• Recordatorios — tú eliges cuántos días antes y a qué hora; las notificaciones se crean en tu dispositivo y su contenido no va a ninguna parte
• Widget de pantalla de inicio — tu día del ciclo, tu semana de embarazo o tu día de posparto de un vistazo

EMBARAZO Y DESPUÉS DEL PARTO

• Modo embarazo — semanas y días, mes y trimestre; fecha prevista de parto según tu última regla o la que te dio tu médico
• Añade tus controles y citas y recibe recordatorios
• Señales de alarma — cuándo acudir sin esperar
• Registro de tensión y peso; un resumen para enseñar en la consulta
• Posparto — los 42 días tras el parto y la evolución del sangrado
• Al terminar el embarazo vuelves al seguimiento del ciclo; los embarazos anteriores se guardan

AQUÍ LA PRIVACIDAD NO ES UNA FUNCIÓN, ES LA ESTRUCTURA

• Los datos de tu ciclo no salen del dispositivo salvo que actives la copia en la nube
• Copia opcional en la nube con tu cuenta de Apple o Google: tus registros te siguen al móvil nuevo y, al desactivarla, se borra la copia en la nube
• Los anuncios no se personalizan; sin identificador publicitario ni permiso de rastreo
• Tus datos de salud nunca se usan para segmentar anuncios
• El bloqueo de la app es gratis — con Face ID o el código del dispositivo
• Puedes exportar una copia de seguridad y una copia legible por máquina cuando quieras, cifrada con contraseña si lo deseas, gratis
• Un icono sencillo en la pantalla de inicio y notificaciones discretas: nadie ve lo que registras
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
Note tes règles, comprends ton cycle. Tes données sont écrites sur ton appareil, pas sur un serveur — sans compte obligatoire, sans pistage.
```

**Description**
```
Les données de ton cycle restent sur ton téléphone.

La plupart des applis de règles envoient les jours que tu notes, tes symptômes et tes notes sur leurs propres serveurs. Nilu non. Tout reste chiffré sur ton appareil. Aucun compte n'est nécessaire ; la sauvegarde cloud est facultative et uniquement avec ton consentement explicite.

CE QU'ELLE FAIT

• Calendrier — note tes règles ; vois les prochaines sous forme de période, avec la façon dont elle est calculée, et ta période fertile estimée
• Journal quotidien — flux, douleurs, humeur, symptômes, notes
• Historique — tous tes cycles, ta moyenne, ton cycle le plus court et le plus long
• Interroge tes données — des réponses à des questions comme « Combien de jours avant mes règles ? », calculées à partir de tes propres saisies. Pas un chatbot ; tes questions ne quittent pas ton téléphone
• Bibliothèque santé — des articles sourcés sur les hormones, l'alimentation, le SPM et l'humeur
• Mouvement — yoga doux et étirements adaptés à ta phase
• Apple Santé — importe tes règles et, si tu veux, enregistre-y les jours que tu notes
• Rappels — tu choisis combien de jours avant et à quelle heure ; les notifications sont créées sur ton appareil et leur contenu ne part nulle part
• Widget d'écran d'accueil — ton jour du cycle, ta semaine de grossesse ou ton jour de post-partum en un coup d'œil

GROSSESSE ET APRÈS LA NAISSANCE

• Mode grossesse — semaines et jours, mois et trimestre ; terme calculé à partir de tes dernières règles ou de la date donnée par ton médecin
• Ajoute tes consultations et rendez-vous et reçois des rappels
• Signes d'alerte — quand consulter sans attendre
• Suivi de la tension et du poids ; un résumé à montrer en consultation
• Post-partum — les 42 jours après la naissance et l'évolution des saignements
• Retour au suivi du cycle à la fin de la grossesse ; les grossesses passées sont conservées

ICI LA CONFIDENTIALITÉ N'EST PAS UNE OPTION, C'EST L'ARCHITECTURE

• Les données de ton cycle ne quittent pas l'appareil, sauf si tu actives la sauvegarde cloud
• Sauvegarde cloud facultative avec ton compte Apple ou Google : tes données te suivent sur un nouveau téléphone, et la désactiver supprime la copie cloud
• Les publicités ne sont pas personnalisées ; aucun identifiant publicitaire, aucune demande de pistage
• Tes données de santé ne servent jamais au ciblage publicitaire
• Le verrouillage de l'app est gratuit — Face ID ou code de l'appareil
• Tu peux exporter une sauvegarde et une copie lisible par machine quand tu veux, chiffrée par mot de passe si tu le souhaites, gratuitement
• Une icône sobre sur l'écran d'accueil et des notifications discrètes : personne ne voit ce que tu suis
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
Registre a menstruação e entenda seu ciclo. Seus dados ficam no seu aparelho, não num servidor — sem conta obrigatória e sem rastreamento.
```

**Descrição**
```
Os dados do seu ciclo ficam no seu celular.

A maioria dos apps de menstruação leva os dias que você registra, seus sintomas e suas anotações para os próprios servidores. O Nilu não. Tudo fica criptografado no seu aparelho. Você não precisa criar conta; o backup na nuvem é opcional e só com seu consentimento explícito.

O QUE ELE FAZ

• Calendário — marque a menstruação; veja a próxima como um intervalo, com a explicação do cálculo, e o período fértil estimado
• Registro diário — fluxo, dor, humor, sintomas e anotações
• Histórico — todos os seus ciclos, sua média, seu ciclo mais curto e o mais longo
• Pergunte aos seus dados — respostas para perguntas como “Quantos dias faltam para meu período?”, calculadas a partir dos seus próprios registros. Não é um chatbot; suas perguntas não saem do seu celular
• Biblioteca de saúde — artigos com fontes sobre hormônios, alimentação, TPM e humor
• Movimento — ioga leve e alongamentos de acordo com a fase do ciclo
• Apple Saúde — importe seus registros de menstruação e, se quiser, grave lá os dias que você marca
• Lembretes — você escolhe quantos dias antes e em que horário; as notificações são criadas no seu aparelho e o conteúdo não vai para lugar nenhum
• Widget da Tela de Início — seu dia do ciclo, sua semana de gravidez ou seu dia de pós-parto num relance

GRAVIDEZ E DEPOIS DO PARTO

• Modo gravidez — semanas e dias, mês e trimestre; data provável do parto pela última menstruação ou pela data que seu médico informou
• Adicione suas consultas e exames e receba lembretes
• Sinais de alerta — quando procurar atendimento sem esperar
• Registro de pressão e peso; um resumo para mostrar na consulta
• Pós-parto — os 42 dias depois do parto e a evolução do sangramento
• Quando a gravidez termina, você volta a acompanhar o ciclo; as gestações anteriores ficam guardadas

AQUI A PRIVACIDADE NÃO É UM RECURSO, É A ESTRUTURA

• Os dados do seu ciclo não saem do aparelho, a menos que você ative o backup na nuvem
• Backup opcional na nuvem com sua conta Apple ou Google: seus registros vão junto para o celular novo, e desativá-lo apaga a cópia na nuvem
• Os anúncios não são personalizados; sem identificador de publicidade e sem pedido de rastreamento
• Seus dados de saúde nunca são usados para segmentar anúncios
• O bloqueio do app é gratuito — com Face ID ou o código do aparelho
• Você pode exportar um backup e uma cópia legível por máquina quando quiser, criptografado com senha se preferir, de graça
• Um ícone simples na tela inicial e notificações discretas — ninguém vê o que você acompanha
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

---

# Google Play

Play Console'a girilecek metinler. Sınırlar: **başlık 30**, **kısa
açıklama 80**, **tam açıklama 4000** — `tool/check_store_listing.py`
bunları da sayıyor.

Tam açıklama App Store metninden türetildi; Android'de olmayan ya da
farklı olan maddeler değişti (bkz. sondaki notlar).

---

## Türkçe · Google Play

**Google Play başlık**
```
Nilu · Regl & Adet Takvimi
```

**Google Play kısa açıklama**
```
Regl takvimi, gebelik ve lohusalık takibi. Verin telefonunda kalır.
```

**Google Play tam açıklama**
```
Yazdıkların sende kalıyor. Gerçekten.

Regl uygulamalarının çoğu işaretlediğin günleri, belirtilerini ve notlarını kendi sunucularına taşır. Nilu taşımıyor. Hepsi telefonunda, şifreli duruyor. Hesap açman bile gerekmiyor; buluta yedeklemek isteğe bağlı ve yalnızca senin açık rızanla.

Çünkü bunlar senin. Kimsenin okumasına, saklamasına ya da satmasına gerek yok.

GÜNLÜK HAYATINDA

• Takvim — reglini işaretle; bir sonrakini aralıkla ve nasıl hesaplandığıyla, tahmini doğurgan dönemini de gör
• Günlük — akış, ağrı, ruh hâli, belirtiler. Canın isterse iki kelime not
• Geçmiş — bütün döngülerin, ortalaman, en kısa ve en uzun döngün
• Verine sor — "Reglime kaç gün kaldı?" gibi sorulara kendi kayıtlarından hesaplanan cevaplar. Sohbet robotu değil; soruların telefonundan çıkmaz
• Kütüphane — hormonlar, beslenme, PMS ve ruh hâli üzerine kaynak gösterilen yazılar
• Hareket — dönemine göre hafif yoga ve esneme akışları
• Hatırlatıcılar — kaç gün önce ve hangi saatte, sen seç; bildirimler telefonunda hazırlanır, içerikleri hiçbir yere gitmez

GEBELİKTE VE DOĞUMDAN SONRA

• Gebelik modu — hafta ve gün, ay ve trimester; tahmini doğum tarihi son reglinden ya da hekiminin verdiği tarihten
• Sağlık Bakanlığı rehberine göre izlem ve tarama zamanları; kendi randevularını da ekleyebilirsin
• Tehlike işaretleri — beklemeden başvurman gereken durumlar
• Tansiyon ve kilo kaydı; muayenede ekrandan gösterebileceğin özet
• Lohusalık — doğumdan sonraki 42 gün ve kanamanın seyri
• Gebelik bitince regl takibine dönüş; geçmiş gebeliklerin saklanır

GİZLİLİK SONRADAN EKLENMEDİ

Bir özellik listesine sıkıştırılmış bir madde değil; uygulama baştan böyle kuruldu.

• Döngü verin telefonundan çıkmıyor — buluta yedeklemeyi sen açmadıkça
• İstersen hesabınla giriş yapıp bulut yedeği aç: yeni telefona geçince kayıtların gelir, kapatınca buluttaki kopya silinir
• Reklamlar kişiselleştirilmiyor
• Sağlık verin hiçbir koşulda reklam için kullanılmıyor
• Ekran kilidi ücretsiz — parmak izi, yüz tanıma ya da telefonunun ekran kilidiyle
• Yedeğini ve verinin okunabilir bir kopyasını istediğin an alabilirsin, istersen parolayla şifreli, ücretsiz
• Sade ana ekran simgesi ve gizli bildirim — kimse ne takip ettiğini görmesin
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

---

## English · Google Play

**Google Play başlık**
```
Nilu · Period Tracker
```

**Google Play kısa açıklama**
```
Period, pregnancy & postnatal tracking. Your data stays on your phone.
```

**Google Play tam açıklama**
```
Your cycle data stays on your phone.

Most period apps move the days you log, your symptoms and your notes to their own servers. Nilu doesn't. It all stays on your device, encrypted. You don't need an account; cloud backup is optional and only with your explicit consent.

WHAT IT DOES

• Calendar — mark your period; see the next one as a range, with how it was calculated, plus your estimated fertile window
• Daily log — flow, pain, mood, symptoms, notes
• History — every cycle, your average, your shortest and longest cycle
• Ask your data — answers to questions like “How many days until my period?”, calculated from your own entries. Not a chatbot; your questions never leave your phone
• Health library — sourced articles on hormones, nutrition, PMS and mood
• Movement — gentle yoga and stretching flows matched to your phase
• Reminders — you choose how many days ahead and what time; notifications are built on your device and their contents go nowhere

PREGNANCY AND AFTER BIRTH

• Pregnancy mode — weeks and days, month and trimester; due date from your last period or the date your clinician gave you
• Add your checkups and appointments and get reminders
• Warning signs — when to seek care without waiting
• Blood pressure and weight log; a summary you can show at your appointment
• Postnatal period — the 42 days after birth and how your bleeding changes
• Back to cycle tracking when your pregnancy ends; past pregnancies are kept

PRIVACY ISN'T A FEATURE HERE, IT'S THE ARCHITECTURE

• Your cycle data never leaves the device unless you turn on cloud backup
• Optional cloud backup when you sign in: your entries follow you to a new phone, and turning it off deletes the cloud copy
• Ads are not personalised
• Your health data is never used for ad targeting
• App lock is free — fingerprint, face unlock or your screen lock
• You can export a backup and a machine-readable copy of your data at any time, optionally password-encrypted, free
• A plain home-screen icon and discreet notifications — no one sees what you track
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

---

## Deutsch · Google Play

**Google Play başlık**
```
Nilu · Zyklus-Tracker
```

**Google Play kısa açıklama**
```
Zyklus, Schwangerschaft & Wochenbett. Deine Daten bleiben auf deinem Handy.
```

**Google Play tam açıklama**
```
Deine Zyklusdaten bleiben auf deinem Telefon.

Die meisten Perioden-Apps übertragen deine eingetragenen Tage, Symptome und Notizen auf eigene Server. Nilu nicht. Alles bleibt verschlüsselt auf deinem Gerät. Ein Konto brauchst du nicht; ein Cloud-Backup ist freiwillig und nur mit deiner ausdrücklichen Einwilligung.

WAS DIE APP KANN

• Kalender — Periode eintragen; die nächste als Zeitraum sehen, mit Erklärung der Berechnung, dazu die geschätzten fruchtbaren Tage
• Tägliches Protokoll — Blutung, Schmerzen, Stimmung, Symptome, Notizen
• Verlauf — alle Zyklen, dein Durchschnitt, dein kürzester und längster Zyklus
• Frag deine Daten — Antworten auf Fragen wie „Wie viele Tage bis zu meiner Periode?“, berechnet aus deinen eigenen Einträgen. Kein Chatbot; deine Fragen verlassen dein Handy nicht
• Gesundheitsbibliothek — belegte Artikel zu Hormonen, Ernährung, PMS und Stimmung
• Bewegung — sanfte Yoga- und Dehnabläufe passend zur Zyklusphase
• Erinnerungen — du wählst, wie viele Tage vorher und um wie viel Uhr; Mitteilungen entstehen auf deinem Gerät, ihre Inhalte gehen nirgendwohin

SCHWANGERSCHAFT UND NACH DER GEBURT

• Schwangerschaftsmodus — Wochen und Tage, Monat und Trimester; errechneter Geburtstermin aus deiner letzten Periode oder der Termin, den dir deine Ärztin genannt hat
• Vorsorgetermine eintragen und erinnert werden
• Warnzeichen — wann du nicht warten solltest
• Blutdruck und Gewicht eintragen; eine Übersicht zum Zeigen beim Termin
• Wochenbett — die 42 Tage nach der Geburt und der Verlauf der Blutung
• Nach der Schwangerschaft zurück zum Zyklus; frühere Schwangerschaften bleiben gespeichert

DATENSCHUTZ IST HIER KEIN FEATURE, SONDERN DIE BAUWEISE

• Deine Zyklusdaten verlassen das Gerät nicht, außer du schaltest das Cloud-Backup ein
• Freiwilliges Cloud-Backup, wenn du dich anmeldest: Deine Einträge kommen mit aufs neue Handy, und beim Ausschalten wird die Cloud-Kopie gelöscht
• Werbung wird nicht personalisiert
• Deine Gesundheitsdaten werden nie für Werbung genutzt
• App-Sperre ist kostenlos — Fingerabdruck, Gesichtsentsperrung oder Displaysperre
• Du kannst jederzeit ein Backup und eine maschinenlesbare Kopie deiner Daten exportieren, auf Wunsch passwortverschlüsselt, kostenlos
• Ein schlichtes Home-Bildschirm-Symbol und diskrete Mitteilungen — niemand sieht, was du erfasst
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

---

## Español · Google Play

**Google Play başlık**
```
Nilu · Ciclo Menstrual
```

**Google Play kısa açıklama**
```
Regla, embarazo y posparto en una app. Tus datos se quedan en tu móvil.
```

**Google Play tam açıklama**
```
Los datos de tu ciclo se quedan en tu teléfono.

La mayoría de las apps de regla llevan los días que registras, tus síntomas y tus notas a sus propios servidores. Nilu no. Todo se queda cifrado en tu dispositivo. No necesitas crear una cuenta; la copia en la nube es opcional y solo con tu consentimiento explícito.

QUÉ HACE

• Calendario — marca tu regla; consulta la siguiente como un rango, con cómo se calculó, y tus días fértiles estimados
• Registro diario — flujo, dolor, ánimo, síntomas y notas
• Historial — todos tus ciclos, tu media, tu ciclo más corto y el más largo
• Pregunta a tus datos — respuestas a preguntas como «¿Cuántos días faltan para mi regla?», calculadas a partir de tus propios registros. No es un chatbot; tus preguntas no salen de tu móvil
• Biblioteca de salud — artículos con fuentes sobre hormonas, alimentación, SPM y ánimo
• Movimiento — yoga suave y estiramientos según la fase del ciclo
• Recordatorios — tú eliges cuántos días antes y a qué hora; las notificaciones se crean en tu dispositivo y su contenido no va a ninguna parte

EMBARAZO Y DESPUÉS DEL PARTO

• Modo embarazo — semanas y días, mes y trimestre; fecha prevista de parto según tu última regla o la que te dio tu médico
• Añade tus controles y citas y recibe recordatorios
• Señales de alarma — cuándo acudir sin esperar
• Registro de tensión y peso; un resumen para enseñar en la consulta
• Posparto — los 42 días tras el parto y la evolución del sangrado
• Al terminar el embarazo vuelves al seguimiento del ciclo; los embarazos anteriores se guardan

AQUÍ LA PRIVACIDAD NO ES UNA FUNCIÓN, ES LA ESTRUCTURA

• Los datos de tu ciclo no salen del dispositivo salvo que actives la copia en la nube
• Copia opcional en la nube al iniciar sesión: tus registros te siguen al móvil nuevo y, al desactivarla, se borra la copia en la nube
• Los anuncios no se personalizan
• Tus datos de salud nunca se usan para segmentar anuncios
• El bloqueo de la app es gratis — con huella, desbloqueo facial o el bloqueo de pantalla
• Puedes exportar una copia de seguridad y una copia legible por máquina cuando quieras, cifrada con contraseña si lo deseas, gratis
• Un icono sencillo en la pantalla de inicio y notificaciones discretas: nadie ve lo que registras
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

---

## Français · Google Play

**Google Play başlık**
```
Nilu · Suivi de Règles
```

**Google Play kısa açıklama**
```
Règles, grossesse et post-partum. Tes données restent sur ton téléphone.
```

**Google Play tam açıklama**
```
Les données de ton cycle restent sur ton téléphone.

La plupart des applis de règles envoient les jours que tu notes, tes symptômes et tes notes sur leurs propres serveurs. Nilu non. Tout reste chiffré sur ton appareil. Aucun compte n'est nécessaire ; la sauvegarde cloud est facultative et uniquement avec ton consentement explicite.

CE QU'ELLE FAIT

• Calendrier — note tes règles ; vois les prochaines sous forme de période, avec la façon dont elle est calculée, et ta période fertile estimée
• Journal quotidien — flux, douleurs, humeur, symptômes, notes
• Historique — tous tes cycles, ta moyenne, ton cycle le plus court et le plus long
• Interroge tes données — des réponses à des questions comme « Combien de jours avant mes règles ? », calculées à partir de tes propres saisies. Pas un chatbot ; tes questions ne quittent pas ton téléphone
• Bibliothèque santé — des articles sourcés sur les hormones, l'alimentation, le SPM et l'humeur
• Mouvement — yoga doux et étirements adaptés à ta phase
• Rappels — tu choisis combien de jours avant et à quelle heure ; les notifications sont créées sur ton appareil et leur contenu ne part nulle part

GROSSESSE ET APRÈS LA NAISSANCE

• Mode grossesse — semaines et jours, mois et trimestre ; terme calculé à partir de tes dernières règles ou de la date donnée par ton médecin
• Ajoute tes consultations et rendez-vous et reçois des rappels
• Signes d'alerte — quand consulter sans attendre
• Suivi de la tension et du poids ; un résumé à montrer en consultation
• Post-partum — les 42 jours après la naissance et l'évolution des saignements
• Retour au suivi du cycle à la fin de la grossesse ; les grossesses passées sont conservées

ICI LA CONFIDENTIALITÉ N'EST PAS UNE OPTION, C'EST L'ARCHITECTURE

• Les données de ton cycle ne quittent pas l'appareil, sauf si tu actives la sauvegarde cloud
• Sauvegarde cloud facultative en te connectant : tes données te suivent sur un nouveau téléphone, et la désactiver supprime la copie cloud
• Les publicités ne sont pas personnalisées
• Tes données de santé ne servent jamais au ciblage publicitaire
• Le verrouillage de l'app est gratuit — empreinte, déverrouillage par le visage ou verrouillage de l'écran
• Tu peux exporter une sauvegarde et une copie lisible par machine quand tu veux, chiffrée par mot de passe si tu le souhaites, gratuitement
• Une icône sobre sur l'écran d'accueil et des notifications discrètes : personne ne voit ce que tu suis
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

---

## Português · Google Play

**Google Play başlık**
```
Nilu · Ciclo Menstrual
```

**Google Play kısa açıklama**
```
Ciclo, gravidez e pós-parto num só app. Seus dados ficam no seu celular.
```

**Google Play tam açıklama**
```
Os dados do seu ciclo ficam no seu celular.

A maioria dos apps de menstruação leva os dias que você registra, seus sintomas e suas anotações para os próprios servidores. O Nilu não. Tudo fica criptografado no seu aparelho. Você não precisa criar conta; o backup na nuvem é opcional e só com seu consentimento explícito.

O QUE ELE FAZ

• Calendário — marque a menstruação; veja a próxima como um intervalo, com a explicação do cálculo, e o período fértil estimado
• Registro diário — fluxo, dor, humor, sintomas e anotações
• Histórico — todos os seus ciclos, sua média, seu ciclo mais curto e o mais longo
• Pergunte aos seus dados — respostas para perguntas como “Quantos dias faltam para meu período?”, calculadas a partir dos seus próprios registros. Não é um chatbot; suas perguntas não saem do seu celular
• Biblioteca de saúde — artigos com fontes sobre hormônios, alimentação, TPM e humor
• Movimento — ioga leve e alongamentos de acordo com a fase do ciclo
• Lembretes — você escolhe quantos dias antes e em que horário; as notificações são criadas no seu aparelho e o conteúdo não vai para lugar nenhum

GRAVIDEZ E DEPOIS DO PARTO

• Modo gravidez — semanas e dias, mês e trimestre; data provável do parto pela última menstruação ou pela data que seu médico informou
• Adicione suas consultas e exames e receba lembretes
• Sinais de alerta — quando procurar atendimento sem esperar
• Registro de pressão e peso; um resumo para mostrar na consulta
• Pós-parto — os 42 dias depois do parto e a evolução do sangramento
• Quando a gravidez termina, você volta a acompanhar o ciclo; as gestações anteriores ficam guardadas

AQUI A PRIVACIDADE NÃO É UM RECURSO, É A ESTRUTURA

• Os dados do seu ciclo não saem do aparelho, a menos que você ative o backup na nuvem
• Backup opcional na nuvem ao entrar na sua conta: seus registros vão junto para o celular novo, e desativá-lo apaga a cópia na nuvem
• Os anúncios não são personalizados
• Seus dados de saúde nunca são usados para segmentar anúncios
• O bloqueio do app é gratuito — com digital, desbloqueio facial ou o bloqueio de tela
• Você pode exportar um backup e uma cópia legível por máquina quando quiser, criptografado com senha se preferir, de graça
• Um ícone simples na tela inicial e notificações discretas — ninguém vê o que você acompanha
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

---

## Google Play notları

**Android projesi hazır** (`android/`, kurulum: SETUP_KEYS.md §10) ama
henüz bir cihazda denenmedi. Metin, Android sürümünün iOS'la aynı
özelliklere sahip olduğunu söylüyor; şu farklar dışında:

- **Apple Sağlık ve ana ekran widget'ı çıkarıldı.** İkisi de yalnızca
  iOS'ta var; Android'de Health Connect ve Glance widget'ı yazılmadıkça
  vaat edilmemeli.
- **"Reklam kimliğin kullanılmıyor" yazılmadı.** Manifest reklam kimliği
  iznini kaldırıyor, ama AdMob SDK'sı kişiselleştirilmemiş reklamda da
  başka cihaz tanımlayıcıları (App Set ID) okuyabiliyor; Data safety
  formunda "Cihaz ya da diğer kimlikler" beyan ediliyor. Metin bu yüzden
  yalnızca "kişiselleştirilmiyor" diyor.
- **Giriş sağlayıcısı adı verilmedi** ("hesabınla giriş"): Android'de
  Apple ile giriş ayrıca bir Services ID istiyor (SETUP_KEYS.md §10.3).
- **Ekran kilidi** Face ID yerine parmak izi / yüz tanıma / ekran kilidi.

Android derlemesi çıktığında bu maddeler uygulamayla yeniden
karşılaştırılmalı.
