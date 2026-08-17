import '../models/intimacy_status.dart';

/// Partner'a yönelik akıllı öneri motoru.
///
/// Domain katmanı **dile bağlı metin üretmez**: her öneri bir lokalizasyon
/// anahtarı taşır, metne çevirme işi View'a aittir (`context.tr(...)`).
class PartnerSuggestionEngine {
  static const int maxSuggestions = 3;

  /// Veriye göre öneri listesi döndürür (en fazla [maxSuggestions] adet).
  static List<PartnerSuggestion> generate(IntimacyStatus? status) {
    if (status == null) return [];

    final suggestions = <PartnerSuggestion>[];

    // ── Cinsel İstek Önerisi ──
    final desireSuggestion = _desireSuggestions[status.sexualDesire];
    if (desireSuggestion != null) suggestions.add(desireSuggestion);

    // ── Sevgi İhtiyaçlarına Göre Öneriler ──
    for (final need in status.affectionNeeds) {
      if (suggestions.length >= maxSuggestions) break;
      final needSuggestion = _needSuggestions[need];
      if (needSuggestion != null) suggestions.add(needSuggestion);
    }

    return suggestions.take(maxSuggestions).toList();
  }

  /// Cinsel istek değerinin partner tarafındaki lokalizasyon anahtarı.
  /// Bilinmeyen değerde null döner.
  static String? getDesireKey(String? desire) {
    if (desire == null || desire.isEmpty) return null;
    const keys = {
      'no_interest': 'pv_desire_no_interest',
      'slight_closeness': 'pv_desire_slight_closeness',
      'feel_closer': 'pv_desire_feel_closer',
      'passionate': 'pv_desire_passionate',
    };
    return keys[desire];
  }

  /// Sevgi ihtiyacının partner tarafındaki lokalizasyon anahtarı.
  /// Bilinmeyen değerde null döner.
  static String? getNeedKey(String need) {
    const keys = {
      'hug': 'pv_need_hug',
      'kiss': 'pv_need_kiss',
      'be_together': 'pv_need_be_together',
      'hear_voice': 'pv_need_hear_voice',
      'text': 'pv_need_text',
      'spend_time': 'pv_need_spend_time',
      'attention': 'pv_need_attention',
      'alone_time': 'pv_need_alone_time',
    };
    return keys[need];
  }

  static const Map<String, PartnerSuggestion> _desireSuggestions = {
    'no_interest': PartnerSuggestion(emoji: '🌿', key: 'pv_sug_distance'),
    'slight_closeness': PartnerSuggestion(
      emoji: '☕',
      key: 'pv_sug_sit_together',
    ),
    'feel_closer': PartnerSuggestion(emoji: '💕', key: 'pv_sug_tell_important'),
    'passionate': PartnerSuggestion(emoji: '🌹', key: 'pv_sug_romantic'),
  };

  static const Map<String, PartnerSuggestion> _needSuggestions = {
    'hug': PartnerSuggestion(emoji: '🤗', key: 'pv_sug_hug'),
    'kiss': PartnerSuggestion(emoji: '😘', key: 'pv_sug_kiss'),
    'hear_voice': PartnerSuggestion(emoji: '📞', key: 'pv_sug_call'),
    'text': PartnerSuggestion(emoji: '💬', key: 'pv_sug_text'),
    'spend_time': PartnerSuggestion(emoji: '🎬', key: 'pv_sug_movie'),
    'be_together': PartnerSuggestion(emoji: '🏠', key: 'pv_sug_be_near'),
    'attention': PartnerSuggestion(emoji: '💖', key: 'pv_sug_attention'),
    'alone_time': PartnerSuggestion(emoji: '🌙', key: 'pv_sug_space'),
  };
}

/// Tek bir öneri modeli. [key] lokalizasyon anahtarıdır.
class PartnerSuggestion {
  final String emoji;
  final String key;

  const PartnerSuggestion({required this.emoji, required this.key});
}
