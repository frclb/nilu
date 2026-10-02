import 'life_stage.dart';

/// Günlük log alanlarının **kanonik kelime dağarcığı**.
///
/// Neden var: semptom, ruh hali, akış yoğunluğu ve cinsel aktivite değerleri
/// eskiden ekranda görünen *çevrilmiş etiketle* saklanıyordu. Bunun iki sonucu
/// vardı:
///
/// 1. Kullanıcı dili değiştirdiğinde kayıtlı seçimleri eşleşmiyor, seçimler
///    kaybolmuş gibi görünüyordu.
/// 2. Takvim ve log-giriş ekranları birbirinden farklı etiket listeleri
///    kullandığı için aynı alan iki ayrı kelime dağarcığıyla yazılıyordu
///    (ör. "Karın Ağrısı" ve "Kramp" aynı şeyi kastediyor ama eşleşmiyordu).
///
/// Artık **dilden bağımsız kodlar** saklanır; ekranda gösterilecek metin
/// lokalizasyondan gelir. [normalize] eski kayıtları okurken kodlara çevirir,
/// böylece mevcut kullanıcı verisi kaybolmaz.
class LogVocabulary {
  const LogVocabulary._();

  static const List<String> symptoms = [
    'cramp',
    'headache',
    'bloating',
    'fatigue',
    'tender',
    'acne',
    'appetite',
    'backache',
  ];

  /// Gebeliğe özgü belirtiler (PREGNANCY_MODE.md, Faz 2).
  ///
  /// Ayrı liste: döngüde anlamsızlar ve listeyi kalabalıklaştırırlar.
  /// Gebelikte genel belirtilerin önünde gösteriliyor.
  static const List<String> pregnancySymptoms = [
    'nausea',
    'vomiting',
    'heartburn',
    'swelling',
    'itching',
    'braxton_hicks',
    'constipation',
    'frequent_urination',
    'leg_cramps',
  ];

  /// Kayıtlarda geçerli sayılan bütün belirti kodları.
  ///
  /// Okurken bu listeyle süzülüyor (bkz. `DailyLog.fromMap`). Yalnızca döngü
  /// listesiyle süzülseydi gebelikte girilen "bulantı" bir sonraki açılışta
  /// sessizce silinirdi.
  static const List<String> allSymptoms = [...symptoms, ...pregnancySymptoms];

  /// Evrede seçilebilecek belirtiler.
  static List<String> symptomsFor(LifeStage stage) =>
      stage == LifeStage.pregnancy
      ? const [...pregnancySymptoms, ...symptoms]
      : symptoms;

  /// Gebelikte tehlike işaretleri listesindeki bir maddeye karşılık gelen
  /// belirtiler (Bakanlık Doğum Öncesi Bakım Yönetim Rehberi, 2018):
  /// şiddetli baş ağrısı; yüz, el ve bacaklarda şişme; şiddetli bulantı ve
  /// kusma; nedeni açıklanamayan kaşıntı. Belirtinin kendisi tehlike değil
  /// — şiddeti ya da aniden başlaması öyle. Kayıt ekranı bu yüzden teşhis
  /// koymuyor, yalnızca neye dikkat edileceğini söylüyor.
  static const Set<String> pregnancyWarningSymptoms = {
    'headache',
    'swelling',
    'vomiting',
    'itching',
  };

  /// Yüksek tansiyonla birlikte preeklampsi belirtisi sayılanlar
  /// (NICE NG133; NHS): şiddetli baş ağrısı, ani şişlik, kusma. Tansiyon
  /// 140/90 ve üstüyken bunlardan biri de varsa uyarı "aynı gün" değil
  /// "beklemeden" oluyor. Kaşıntı burada yok: kolestaz işareti, tansiyonla
  /// ilgisi yok.
  static const Set<String> preeclampsiaSymptoms = {
    'headache',
    'swelling',
    'vomiting',
  };

  static const List<String> moods = [
    'happy',
    'calm',
    'sad',
    'anxious',
    'sensitive',
    'irritable',
    'tired',
  ];

  /// Lekelenme kodu.
  ///
  /// Regl değil: kanama var ama döngü başlatmıyor. Regl dışı (ara) kanama
  /// NHS ve ACOG'un "hekime danış" dediği ayrı bir bulgu. Regl günü
  /// sayılırsa iki şey birden bozulur — döngü uzunluğu yanlış hesaplanır ve
  /// kısa döngü uyarısı haksız yere tetiklenebilir.
  static const String spotting = 'spotting';

  /// Akış yoğunluğu kademeleri, artan sırayla.
  ///
  /// Ekranda soldan sağa bu sırayla çiziliyor.
  static const List<String> flowIntensities = [
    'none',
    spotting,
    'light',
    'medium',
    'heavy',
  ];

  /// Regl günü sayılan kademeler.
  static const List<String> periodFlowIntensities = [
    'light',
    'medium',
    'heavy',
  ];

  /// [code] bir regl gününü başlatır mı?
  ///
  /// Kayıt ekranı "akış girildiyse kanama var demektir" deyip **herhangi**
  /// bir değerde dönemi başlatıyordu: "Yok" seçen kullanıcı da regl
  /// başlatıyordu.
  static bool startsPeriod(String? code) =>
      code != null && periodFlowIntensities.contains(code);

  /// [code] kanama bildiriyor mu? Lekelenme dâhil.
  static bool isBleeding(String? code) =>
      startsPeriod(code) || code == spotting;

  /// Ağrı şiddeti. Sayısal bir ölçek yerine üç kademe: kullanıcıdan 0–10
  /// arası bir sayı istemek kaydı zorlaştırıyor ve kişiden kişiye
  /// karşılaştırılabilir olmuyor.
  static const List<String> painLevels = ['mild', 'moderate', 'severe'];

  /// Ağrının nerede hissedildiği.
  ///
  /// Şiddet tek başına bir örüntü vermiyor. Hekimin sorduğu ve tanıyı
  /// yönlendiren şey ağrının **yeri**: her ay alt karnı ağrıyan biriyle
  /// ağrısı bele ve bacaklara vuran biri aynı tabloda değil.
  static const List<String> painLocations = [
    'abdomen',
    'lower_back',
    'pelvis',
    'legs',
  ];

  /// Ağrının hangi durumda ortaya çıktığı.
  ///
  /// Üçü de NICE NG73'ün endometriozisten şüphelenmek için saydığı
  /// bulgular: ilişkide derin ağrı, ağrılı büyük abdest ve döngüyle
  /// ilişkili idrar yolu ağrısı. Kullanıcı çoğu zaman bunların regliyle
  /// bağlantılı olabileceğini bilmiyor, hekim de sormadıkça duymuyor —
  /// tanının ortalama yıllarca gecikmesinin sebeplerinden biri bu.
  static const List<String> painContexts = [
    'intercourse',
    'bowel',
    'urination',
  ];

  static const List<String> sexualActivities = [
    'none',
    'protected',
    'unprotected',
  ];

  // ─── Lokalizasyon anahtarları ───

  static String symptomKey(String code) => 'log_symptom_$code';

  static String painLevelKey(String code) => 'log_pain_$code';
  static String painLocationKey(String code) => 'log_pain_loc_$code';
  static String painContextKey(String code) => 'log_pain_when_$code';
  static String moodKey(String code) => 'log_mood_$code';
  static String flowKey(String code) => 'log_flow_$code';
  static String sexualActivityKey(String code) => 'log_sex_$code';

  // ─── Geriye dönük uyumluluk ───

  /// Eskiden kaydedilmiş görünür etiketleri kanonik koda çevirir.
  /// Değer zaten bir kodsa aynen döner; tanınmayan değer için null döner.
  static String? normalize(String raw, List<String> validCodes) {
    final value = raw.trim();
    if (validCodes.contains(value)) return value;

    final code = _legacyLabels[_fold(value)];
    if (code != null && validCodes.contains(code)) return code;

    return null;
  }

  /// Bir listeyi normalize eder; tanınmayan değerler düşer.
  static List<String> normalizeAll(
    Iterable<String> raw,
    List<String> validCodes,
  ) {
    final result = <String>[];
    for (final item in raw) {
      final code = normalize(item, validCodes);
      if (code != null && !result.contains(code)) result.add(code);
    }
    return result;
  }

  /// Büyük/küçük harf ve Türkçe karakter farklarını törpüler.
  static String _fold(String value) {
    const map = {
      'ı': 'i',
      'İ': 'i',
      'ğ': 'g',
      'Ğ': 'g',
      'ü': 'u',
      'Ü': 'u',
      'ş': 's',
      'Ş': 's',
      'ö': 'o',
      'Ö': 'o',
      'ç': 'c',
      'Ç': 'c',
    };
    final buffer = StringBuffer();
    for (final char in value.split('')) {
      buffer.write(map[char] ?? char);
    }
    return buffer.toString().toLowerCase();
  }

  /// Eski görünür etiket -> kanonik kod. Hem Türkçe hem İngilizce değerler
  /// kapsanır; anahtarlar [_fold] uygulanmış hâlleriyle yazılmıştır.
  static final Map<String, String> _legacyLabels = {
    // Semptomlar
    'kramp': 'cramp',
    'karin agrisi': 'cramp',
    'cramps': 'cramp',
    'bas agrisi': 'headache',
    'headache': 'headache',
    'siskinlik': 'bloating',
    'bloating': 'bloating',
    'yorgunluk': 'fatigue',
    'fatigue': 'fatigue',
    'hassasiyet': 'tender',
    'tenderness': 'tender',
    'akne': 'acne',
    'sivilce': 'acne',
    'acne': 'acne',
    'istah artisi': 'appetite',
    'increased appetite': 'appetite',
    'bel agrisi': 'backache',
    'back pain': 'backache',

    // Ruh hâli
    'mutlu': 'happy',
    'happy': 'happy',
    'sakin': 'calm',
    'calm': 'calm',
    'uzgun': 'sad',
    'sad': 'sad',
    'gergin': 'anxious',
    'anxious': 'anxious',
    'hassas': 'sensitive',
    'sensitive': 'sensitive',
    'sinirli': 'irritable',
    'irritable': 'irritable',
    'yorgun': 'tired',
    'tired': 'tired',

    // Akış yoğunluğu
    'yok': 'none',
    'hafif': 'light',
    'light': 'light',
    'orta': 'medium',
    'medium': 'medium',
    'yogun': 'heavy',
    'heavy': 'heavy',

    // Cinsel aktivite
    'korunmali': 'protected',
    'protected': 'protected',
    'korunmasiz': 'unprotected',
    'unprotected': 'unprotected',
  };
}
