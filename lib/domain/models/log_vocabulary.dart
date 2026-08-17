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

  static const List<String> moods = [
    'happy',
    'calm',
    'sad',
    'anxious',
    'sensitive',
    'irritable',
    'tired',
  ];

  static const List<String> flowIntensities = [
    'none',
    'light',
    'medium',
    'heavy',
  ];

  static const List<String> sexualActivities = [
    'none',
    'protected',
    'unprotected',
  ];

  // ─── Lokalizasyon anahtarları ───

  static String symptomKey(String code) => 'log_symptom_$code';
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
