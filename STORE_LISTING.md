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

Uygulamanın ana ekranda görünen adı (`CFBundleDisplayName`) hâlâ
"Period Tracker" — karar kesinleşince o da değişmeli. Mağaza adı ile
cihazdaki ad birebir aynı olmak zorunda değil ama birbirinden uzak
düşmemeli.

### Ada eklenen açıklama dilden dile değişir

App Store adı **her dil için ayrı** giriliyor. Marka kısmı sabit, arkasına
gelen açıklama o pazarın aradığı kelime oluyor:

| Dil | Ad |
|---|---|
| Türkçe | Nilu · Regl Takibi |
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

Hangi terimin daha çok arandığını ölçemiyorum. Bedava bir sinyal var:
App Store'un arama kutusuna "regl" ve "adet" yazıp otomatik tamamlamaya
bak — öneriler popülerliğe göre sıralı geliyor. Sıralama beklediğinden
farklıysa addaki kelimeyi değiştirmek tek satır.

---

## Türkçe

**Ad**
```
Nilu · Regl Takibi
```

**Alt başlık**
```
Döngün sende kalır
```

**Tanıtım metni**
```
Bedenini tanımak için sakin bir yer. İşaretlediğin her şey telefonunda kalıyor — hesap yok, takip yok, kimseye gitmiyor.
```

**Açıklama**
```
Yazdıkların sende kalıyor. Gerçekten.

Regl uygulamalarının çoğu işaretlediğin günleri, belirtilerini ve notlarını kendi sunucularına taşır. Nilu taşımıyor. Hepsi telefonunda, şifreli duruyor. Hesap açman bile gerekmiyor.

Çünkü bunlar senin. Kimsenin okumasına, saklamasına ya da satmasına gerek yok.

GÜNLÜK HAYATINDA

• Takvim — reglini işaretle, bir sonrakini ve doğurgan dönemini gör
• Günlük — akış, ağrı, ruh hâli, uyku. Canın isterse iki kelime not
• Analiz — döngün nasıl değişiyor, belirtilerin hangi evrede toplanıyor
• Kütüphane — hormonlar, beslenme, PMS ve ruh hâli üzerine kaynak gösterilen yazılar
• Hareket — dönemine göre yoga akışları, esneme ve nefes egzersizleri
• Apple Sağlık — kayıtlarını içeri al, işaretlediğin günleri geri yaz
• Hatırlatıcılar — bildirimler telefonunda hazırlanır, içerikleri hiçbir yere gitmez

GİZLİLİK SONRADAN EKLENMEDİ

Bir özellik listesine sıkıştırılmış bir madde değil; uygulama baştan böyle kuruldu.

• Döngü verin telefonundan çıkmıyor
• Reklamlar kişiselleştirilmiyor. Reklam kimliğin kullanılmıyor, izleme izni istenmiyor
• Sağlık verin hiçbir koşulda reklam için kullanılmıyor
• Ekran kilidi ücretsiz — Face ID ya da telefonunun şifresiyle
• Yedeğini ve verinin okunabilir bir kopyasını istediğin an alabilirsin, ücretsiz
• Hesabını ve her şeyini uygulamadan silebilirsin

İSTERSEN PARTNERİNLE

Partnerine yalnızca paylaşmayı seçtiğin yakınlık durumu gider. Döngü tarihlerin, belirtilerin, notların gitmez. Fikrin değişirse erişimi geri alırsın; verdiğin kodu iptal edebilirsin.

Bazı günler anlatmak zor geliyor. Bu, anlatmanın sessiz bir yolu.

PREMIUM

• Tüm döngü geçmişin — ücretsiz sürüm son 3 döngüyü gösterir
• Belirti–evre analizi — belirtilerin döngünün hangi evresinde yoğunlaşıyor
• Hekime götürebileceğin özet ve tablo
• Özel temalar
• Reklamsız kullanım

Ekran kilidi ve yedek alma premium'da değil. İkisi de herkese açık, öyle kalacak.

BİLMEN GEREKENLER

Nilu tıbbi teşhis koymaz, tedavi önermez ve bir doğum kontrol yöntemi değildir. Tahminler geçmiş kayıtlarından hesaplanır, yani yaklaşıktır. Bedeninle ilgili bir endişen varsa bir hekime danış — uygulama onun yerini tutmaz.
```

**Anahtar kelimeler**
```
adet,döngü,takvim,ovulasyon,yumurtlama,doğurganlık,pms,semptom,kadın,periyot,gizlilik,günlük
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
• Daily log — flow, pain, mood, sleep, notes
• Insights — how your cycle length changes, which phase your symptoms cluster in
• Health library — sourced articles on hormones, nutrition, PMS and mood
• Movement — yoga flows, stretches and breathing exercises matched to your phase
• Apple Health — import your period records, write the days you mark back
• Reminders — notifications are built on your device and their contents go nowhere

PRIVACY ISN'T A FEATURE HERE, IT'S THE ARCHITECTURE

• Your cycle data never leaves the device
• Ads are not personalised; no advertising identifier, no tracking prompt
• Your health data is never used for ad targeting
• App lock is free — Face ID or your device passcode
• You can export a backup and a machine-readable copy of your data at any time, free
• You can delete your account and all your data from inside the app

PARTNER SHARING — IF YOU WANT IT

Only the closeness status you choose to share reaches your partner. Your cycle dates, symptoms and notes do not. You can revoke access whenever you like; the code you shared can be cancelled.

PREMIUM

• Your full cycle history — the free version shows the last 3 cycles
• Symptom–phase analysis — which phase your symptoms concentrate in
• A summary and table you can take to your doctor
• Custom themes
• No ads

App lock and backups are not behind the paywall. Both are free for everyone.

WHAT YOU SHOULD KNOW

Nilu does not diagnose, does not prescribe treatment, and is not a contraceptive method. Predictions are calculated from your past entries and are approximate. If you're worried about your health, talk to a doctor.
```

**Keywords**
```
menstrual,ovulation,fertility,pms,symptom,calendar,privacy,women,diary,mood,cramps,log
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
• Tägliches Protokoll — Blutung, Schmerzen, Stimmung, Schlaf, Notizen
• Auswertung — wie sich deine Zykluslänge verändert, in welcher Phase sich Symptome häufen
• Gesundheitsbibliothek — belegte Artikel zu Hormonen, Ernährung, PMS und Stimmung
• Bewegung — Yoga, Dehnung und Atemübungen passend zur Zyklusphase
• Apple Health — Periodendaten importieren und eingetragene Tage zurückschreiben
• Erinnerungen — Mitteilungen entstehen auf deinem Gerät, ihre Inhalte gehen nirgendwohin

DATENSCHUTZ IST HIER KEIN FEATURE, SONDERN DIE BAUWEISE

• Deine Zyklusdaten verlassen das Gerät nicht
• Werbung wird nicht personalisiert; keine Werbe-ID, keine Tracking-Abfrage
• Deine Gesundheitsdaten werden nie für Werbung genutzt
• App-Sperre ist kostenlos — Face ID oder Gerätecode
• Du kannst jederzeit ein Backup und eine maschinenlesbare Kopie deiner Daten exportieren, kostenlos
• Du kannst Konto und Daten vollständig in der App löschen

PARTNER-FREIGABE — WENN DU WILLST

Bei deinem Partner kommt nur der Nähe-Status an, den du teilst. Zyklusdaten, Symptome und Notizen nicht. Du kannst den Zugriff jederzeit entziehen; der geteilte Code lässt sich widerrufen.

PREMIUM

• Deine gesamte Zyklushistorie — die kostenlose Version zeigt die letzten 3 Zyklen
• Symptom-Phasen-Analyse
• Zusammenfassung und Tabelle für den Arztbesuch
• Eigene Designs
• Keine Werbung

App-Sperre und Backup stehen nicht hinter der Bezahlschranke. Beides ist für alle kostenlos.

WAS DU WISSEN SOLLTEST

Nilu stellt keine Diagnose, empfiehlt keine Behandlung und ist kein Verhütungsmittel. Vorhersagen werden aus deinen früheren Einträgen berechnet und sind ungefähr. Bei gesundheitlichen Sorgen wende dich an eine Ärztin oder einen Arzt.
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
• Registro diario — flujo, dolor, ánimo, sueño y notas
• Análisis — cómo cambia la duración de tu ciclo y en qué fase se concentran tus síntomas
• Biblioteca de salud — artículos con fuentes sobre hormonas, alimentación, SPM y ánimo
• Movimiento — yoga, estiramientos y respiración según la fase del ciclo
• Apple Salud — importa tus registros y devuelve los días que marcas
• Recordatorios — las notificaciones se crean en tu dispositivo y su contenido no va a ninguna parte

AQUÍ LA PRIVACIDAD NO ES UNA FUNCIÓN, ES LA ESTRUCTURA

• Los datos de tu ciclo no salen del dispositivo
• Los anuncios no se personalizan; sin identificador publicitario ni permiso de rastreo
• Tus datos de salud nunca se usan para segmentar anuncios
• El bloqueo de la app es gratis — con Face ID o el código del dispositivo
• Puedes exportar una copia de seguridad y una copia legible por máquina cuando quieras, gratis
• Puedes borrar tu cuenta y tus datos desde la propia app

COMPARTIR CON TU PAREJA — SI QUIERES

A tu pareja solo le llega el estado de cercanía que decides compartir. Ni las fechas de tu ciclo, ni tus síntomas, ni tus notas. Puedes retirar el acceso cuando quieras; el código compartido se puede anular.

PREMIUM

• Todo tu historial de ciclos — la versión gratuita muestra los 3 últimos
• Análisis de síntomas por fase
• Resumen y tabla para llevar al médico
• Temas propios
• Sin anuncios

El bloqueo de la app y las copias de seguridad no están detrás del muro de pago. Son gratis para todo el mundo.

LO QUE DEBES SABER

Nilu no diagnostica, no recomienda tratamientos y no es un método anticonceptivo. Las previsiones se calculan a partir de tus registros anteriores y son aproximadas. Si te preocupa tu salud, consulta a un profesional médico.
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
• Journal quotidien — flux, douleurs, humeur, sommeil, notes
• Analyses — comment la durée de ton cycle évolue, à quelle phase tes symptômes se concentrent
• Bibliothèque santé — des articles sourcés sur les hormones, l'alimentation, le SPM et l'humeur
• Mouvement — yoga, étirements et respiration adaptés à ta phase
• Apple Santé — importe tes règles et réécris les jours que tu notes
• Rappels — les notifications sont créées sur ton appareil et leur contenu ne part nulle part

ICI LA CONFIDENTIALITÉ N'EST PAS UNE OPTION, C'EST L'ARCHITECTURE

• Les données de ton cycle ne quittent pas l'appareil
• Les publicités ne sont pas personnalisées ; aucun identifiant publicitaire, aucune demande de pistage
• Tes données de santé ne servent jamais au ciblage publicitaire
• Le verrouillage de l'app est gratuit — Face ID ou code de l'appareil
• Tu peux exporter une sauvegarde et une copie lisible par machine quand tu veux, gratuitement
• Tu peux supprimer ton compte et tes données depuis l'app

PARTAGE AVEC UN PARTENAIRE — SI TU VEUX

Seul l'état de proximité que tu choisis de partager lui parvient. Ni tes dates de cycle, ni tes symptômes, ni tes notes. Tu peux retirer l'accès quand tu veux ; le code partagé est révocable.

PREMIUM

• Tout ton historique de cycles — la version gratuite affiche les 3 derniers
• Analyse symptômes–phase
• Un résumé et un tableau à emporter chez le médecin
• Thèmes personnalisés
• Sans publicité

Le verrouillage et les sauvegardes ne sont pas derrière le paywall. Les deux sont gratuits pour tout le monde.

CE QU'IL FAUT SAVOIR

Nilu ne pose pas de diagnostic, ne prescrit aucun traitement et n'est pas un moyen de contraception. Les prévisions sont calculées à partir de tes saisies passées et restent approximatives. En cas d'inquiétude, consulte un médecin.
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
O teu ciclo fica no telemóvel
```

**Texto promocional**
```
Regista a menstruação e entende o teu ciclo. Os dados ficam no teu dispositivo, não num servidor — sem conta e sem rastreio.
```

**Descrição**
```
Os dados do teu ciclo não saem do telemóvel.

A maioria das apps de menstruação leva os dias que registas, os sintomas e as notas para os seus próprios servidores. Nilu não. Fica tudo cifrado no teu dispositivo. Não precisas de criar conta.

O QUE FAZ

• Calendário — marca a menstruação e vê as previsões e o período fértil
• Registo diário — fluxo, dores, humor, sono e notas
• Análises — como muda a duração do teu ciclo e em que fase se concentram os sintomas
• Biblioteca de saúde — artigos com fontes sobre hormonas, alimentação, TPM e humor
• Movimento — ioga, alongamentos e respiração conforme a fase do ciclo
• Apple Saúde — importa os teus registos e devolve os dias que marcas
• Lembretes — as notificações são criadas no teu dispositivo e o conteúdo não vai a lado nenhum

AQUI A PRIVACIDADE NÃO É UMA FUNCIONALIDADE, É A ESTRUTURA

• Os dados do teu ciclo não saem do dispositivo
• Os anúncios não são personalizados; sem identificador de publicidade nem pedido de rastreio
• Os teus dados de saúde nunca são usados para segmentar anúncios
• O bloqueio da app é gratuito — Face ID ou código do dispositivo
• Podes exportar uma cópia de segurança e uma cópia legível por máquina quando quiseres, grátis
• Podes apagar a conta e os dados dentro da própria app

PARTILHA COM O PARCEIRO — SE QUISERES

Ao teu parceiro chega apenas o estado de proximidade que escolhes partilhar. As datas do ciclo, os sintomas e as notas não. Podes retirar o acesso quando quiseres; o código partilhado é anulável.

PREMIUM

• Todo o teu histórico de ciclos — a versão gratuita mostra os últimos 3
• Análise sintoma–fase
• Um resumo e uma tabela para levar ao médico
• Temas próprios
• Sem anúncios

O bloqueio da app e as cópias de segurança não estão atrás da barreira de pagamento. Ambos são gratuitos para toda a gente.

O QUE DEVES SABER

Nilu não diagnostica, não receita tratamentos e não é um método contracetivo. As previsões são calculadas a partir dos teus registos anteriores e são aproximadas. Se estiveres preocupada com a tua saúde, fala com um médico.
```

**Palavras-chave**
```
menstruacao,periodo,ovulacao,fertilidade,tpm,sintomas,calendario,mulher,saude,privacidade,diario
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
ödediğini bulamaz. Kaynak: `premium_feature_*` anahtarları.

**Tıbbi uyarı her dilde var.** İnceleme sağlık iddialarına bakıyor ve
uygulama zaten Şartlar'da teşhis koymadığını söylüyor; mağaza metni de
aynı şeyi söylemeli.
