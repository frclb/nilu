/// Kullanıcının sorabildiği şeyler.
///
/// Kapalı bir küme: uygulama yalnızca **kendi verisinden** hesaplayabildiği
/// soruları cevaplar. Bir dil modeline bağlanmadı — regl verisi GDPR'da özel
/// nitelikli veri ve uygulamanın en güçlü tarafı verinin cihazdan çıkmaması.
/// Ayrıca "bu normal mi?" türü sorulara uyduran bir model, sağlık
/// uygulamasında en kötü hata türü olurdu.
enum AssistantIntent {
  nextPeriod,
  currentPhase,
  fertileWindow,
  cycleLength,
  periodLength,
  regularity,
  symptomFrequency,
  lastSymptom,

  /// Anlaşılmadı — ne sorulabileceği gösterilir.
  unknown,
}

/// Ayrıştırılmış soru.
class AssistantQuery {
  final AssistantIntent intent;

  /// Belirti soruları için `LogVocabulary` kodu.
  final String? symptomCode;

  const AssistantQuery(this.intent, {this.symptomCode});
}

/// Serbest metni bir niyete eşler.
///
/// Anahtar kelimeler lokalizasyon dosyalarından gelir; her dil kendi
/// ifadelerini tanımlar. Biçim: alternatifler virgülle, bir alternatifin
/// **hepsi bulunmalı** olan parçaları artıyla ayrılır.
///
///     "sonraki+regl, regl+ne zaman, adet+ne zaman"
///
/// Türkçe eklemeli bir dil: "regl" kalıbı "reglim", "reglimin", "regle"
/// içinde de bulunur. Bu yüzden tam kelime değil **alt dize** aranıyor.
class AssistantParser {
  const AssistantParser._();

  static AssistantQuery parse(
    String input, {

    /// Niyet → anahtar kelime kalıbı.
    required Map<AssistantIntent, String> patterns,

    /// Çevrilmiş belirti adı → `LogVocabulary` kodu.
    required Map<String, String> symptomLabels,
  }) {
    final text = normalize(input);
    if (text.isEmpty) return const AssistantQuery(AssistantIntent.unknown);

    final symptom = _findSymptom(text, symptomLabels);

    // Belirti içeren sorular önce denenir: "kramplarım ne zaman oluyor"
    // hem belirti hem zaman kalıbı taşıyor, doğru cevap belirtiye ait olan.
    if (symptom != null) {
      if (_matches(text, patterns[AssistantIntent.lastSymptom])) {
        return AssistantQuery(
          AssistantIntent.lastSymptom,
          symptomCode: symptom,
        );
      }
      return AssistantQuery(
        AssistantIntent.symptomFrequency,
        symptomCode: symptom,
      );
    }

    // Belirtisiz niyetler. Sıra önemli: daha özgül kalıp önce denenmeli,
    // yoksa "regl" geçen her soru `nextPeriod`'a düşer.
    const order = [
      AssistantIntent.regularity,
      AssistantIntent.periodLength,
      AssistantIntent.cycleLength,
      AssistantIntent.fertileWindow,
      AssistantIntent.currentPhase,
      AssistantIntent.nextPeriod,
    ];

    for (final intent in order) {
      if (_matches(text, patterns[intent])) return AssistantQuery(intent);
    }

    return const AssistantQuery(AssistantIntent.unknown);
  }

  static bool _matches(String text, String? pattern) {
    if (pattern == null || pattern.isEmpty) return false;

    for (final alternative in pattern.split(',')) {
      final parts = alternative
          .split('+')
          .map(normalize)
          .where((p) => p.isNotEmpty);
      if (parts.isEmpty) continue;
      if (parts.every(text.contains)) return true;
    }
    return false;
  }

  static String? _findSymptom(String text, Map<String, String> labels) {
    // En uzun etiket önce: "bas agrisi" ararken yalnız "agri" ile eşleşip
    // yanlış belirtiyi seçmeyelim.
    final entries = labels.entries.toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length));

    for (final entry in entries) {
      if (_labelMatches(text, entry.key)) return entry.value;
    }
    return null;
  }

  /// Etiketin kullanıcı metninde geçip geçmediği.
  ///
  /// Tam dize araması yetmiyor: etiket "Baş Ağrısı" ama kullanıcı "baş
  /// ağrım" yazıyor. Hem etiketin kendi eki hem kullanıcının eki farklı.
  /// Her kelimenin **kökü** aranıyor: uzun kelimelerden son iki harf
  /// atılıyor, kısa kelimeler olduğu gibi kalıyor.
  static bool _labelMatches(String text, String label) {
    final words = normalize(label).split(' ').where((w) => w.isNotEmpty);
    if (words.isEmpty) return false;
    return words.every((word) => text.contains(_stem(word)));
  }

  /// Kelime kökü. Beş harften uzunsa son iki harf atılır.
  ///
  /// "agrisi" → "agri", "yorgunluk" → "yorgunlu", "kramp" → "kramp".
  /// Daha agresif kırpmak yanlış eşleşme üretir.
  static String _stem(String word) =>
      word.length > 5 ? word.substring(0, word.length - 2) : word;

  /// Karşılaştırma için metni sadeleştirir.
  ///
  /// Türkçe karakterler ASCII karşılıklarına indirilir: kullanıcı "ağrı"
  /// yerine "agri" yazdığında da eşleşsin.
  static String normalize(String input) {
    // Tablo **eksiksiz** olmalı: Dart'ın `\w` sınıfı yalnızca ASCII, yani
    // burada karşılığı olmayan her aksanlı harf aşağıdaki temizlikte boşluğa
    // dönüşüp kelimeyi sessizce ikiye böler. `í` eksik olduğu için "días"
    // → "d as" oluyordu ve İspanyolca/Portekizce sorular hiç eşleşmiyordu.
    const folding = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'æ': 'ae',
      'ç': 'c',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'ğ': 'g',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ı': 'i',
      'ñ': 'n',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ø': 'o',
      'œ': 'oe',
      'ş': 's',
      'ß': 'ss',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'Á': 'a',
      'À': 'a',
      'Â': 'a',
      'Ä': 'a',
      'Ã': 'a',
      'Å': 'a',
      'Æ': 'ae',
      'Ç': 'c',
      'É': 'e',
      'È': 'e',
      'Ê': 'e',
      'Ë': 'e',
      'Ğ': 'g',
      'Í': 'i',
      'Ì': 'i',
      'Î': 'i',
      'Ï': 'i',
      'İ': 'i',
      'Ñ': 'n',
      'Ó': 'o',
      'Ò': 'o',
      'Ô': 'o',
      'Ö': 'o',
      'Õ': 'o',
      'Ø': 'o',
      'Œ': 'oe',
      'Ş': 's',
      'Ú': 'u',
      'Ù': 'u',
      'Û': 'u',
      'Ü': 'u',
      'Ý': 'y',
    };

    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(folding[ch] ?? ch);
    }

    return buffer
        .toString()
        .toLowerCase()
        // Noktalama ve fazla boşluk eşleşmeyi bozmasın.
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
