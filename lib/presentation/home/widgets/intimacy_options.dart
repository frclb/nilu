import 'package:flutter/material.dart';

/// Yakınlık durumunun seçenekleri: kayıtta tutulan değer, etiket anahtarı
/// ve simge.
///
/// Ana ekrandaki kartlar ve partner onay sayfası aynı listeyi gösteriyor;
/// iki ayrı kopya ilk değişiklikte ayrışırdı.
class IntimacyOption {
  const IntimacyOption(this.value, this.labelKey, this.icon);

  /// Sunucuya giden değer (`IntimacyStatus`).
  final String value;
  final String labelKey;
  final IconData icon;
}

/// Cinsel istek: tek seçim.
const List<IntimacyOption> desireOptions = [
  IntimacyOption(
    'no_interest',
    'intimacy_desire_no_interest',
    Icons.do_not_disturb_on_outlined,
  ),
  IntimacyOption(
    'slight_closeness',
    'intimacy_desire_slight',
    Icons.sentiment_neutral_outlined,
  ),
  IntimacyOption(
    'feel_closer',
    'intimacy_desire_closer',
    Icons.favorite_border_rounded,
  ),
  IntimacyOption(
    'passionate',
    'intimacy_desire_passionate',
    Icons.local_fire_department_rounded,
  ),
];

/// Sevgi ihtiyaçları: çoklu seçim.
const List<IntimacyOption> affectionNeedOptions = [
  IntimacyOption('hug', 'intimacy_need_hug', Icons.accessibility_new_rounded),
  IntimacyOption('kiss', 'intimacy_need_kiss', Icons.emoji_emotions_outlined),
  IntimacyOption(
    'be_together',
    'intimacy_need_together',
    Icons.people_outline_rounded,
  ),
  IntimacyOption(
    'hear_voice',
    'intimacy_need_voice',
    Icons.phone_in_talk_outlined,
  ),
  IntimacyOption(
    'text',
    'intimacy_need_text',
    Icons.chat_bubble_outline_rounded,
  ),
  IntimacyOption(
    'spend_time',
    'intimacy_need_spend_time',
    Icons.coffee_outlined,
  ),
  IntimacyOption(
    'attention',
    'intimacy_need_attention',
    Icons.visibility_outlined,
  ),
  IntimacyOption(
    'alone_time',
    'intimacy_need_alone',
    Icons.self_improvement_rounded,
  ),
];

/// Değerin seçeneği; bilinmeyen değerde `null`.
IntimacyOption? intimacyOptionOf(String? value) {
  for (final o in [...desireOptions, ...affectionNeedOptions]) {
    if (o.value == value) return o;
  }
  return null;
}
