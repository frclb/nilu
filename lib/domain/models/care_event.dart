import 'package:flutter/foundation.dart';

import 'pregnancy.dart';

/// Bakım kaleminin türü.
enum CareCategory { visit, screening, supplement, vaccine }

/// Pencerenin neye göre sayıldığı.
enum CareAnchor {
  /// Gebelik başlangıcından (EDD − 280). Hekim tarihi düzeltince kayar.
  gestation,

  /// Doğum gününden.
  postpartum,
}

/// Gebelik ya da lohusalıkta takip edilecek bir kalem: izlem, tarama,
/// destek ya da aşı.
///
/// Şablondan geliyorsa [code] dilden bağımsız bir kod (`tr_visit_2`) ve
/// ekrandaki metin lokalizasyondan çözülüyor — `LogVocabulary`'nin dersi:
/// çevrilmiş etiket saklanırsa dil değişince kayıt anlamını yitiriyor.
/// Kullanıcının kendi eklediği kalemde [code] yok, [title] var.
@immutable
class CareEvent {
  final String id;
  final String pregnancyId;

  final String? code;
  final String? title;

  final CareCategory category;
  final CareAnchor anchor;

  /// Pencere, çapadan itibaren gün olarak: `[fromDay, toDay]` (ikisi dahil).
  final int fromDay;
  final int toDay;

  /// Koşulluysa koşulun lokalizasyon anahtarı (ör. "Rh(−) iseniz").
  final String? conditionKey;

  /// Kullanıcının aldığı randevu — saatiyle.
  final DateTime? scheduledAt;
  final bool done;

  /// "Hekime soracaklarım" burada.
  final String? note;
  final bool reminderOn;

  const CareEvent({
    required this.id,
    required this.pregnancyId,
    required this.category,
    required this.anchor,
    required this.fromDay,
    required this.toDay,
    this.code,
    this.title,
    this.conditionKey,
    this.scheduledAt,
    this.done = false,
    this.note,
    this.reminderOn = true,
  });

  /// Şablon dışında, kullanıcının eklediği randevu.
  factory CareEvent.custom({
    required String pregnancyId,
    required String title,
    DateTime? scheduledAt,
    CareCategory category = CareCategory.visit,
    String? id,
  }) => CareEvent(
    id: id ?? 'care_custom_${DateTime.now().microsecondsSinceEpoch}',
    pregnancyId: pregnancyId,
    title: title,
    category: category,
    anchor: CareAnchor.gestation,
    fromDay: 0,
    toDay: 0,
    scheduledAt: scheduledAt,
  );

  bool get isCustom => code == null;

  /// Pencerenin ilk günü. Doğum sonu kalemi için doğum olmadan `null`:
  /// tarih bilinmeden pencere uydurulmuyor.
  DateTime? windowStart(Pregnancy p) {
    final cipa = _anchorDay(p);
    return cipa?.add(Duration(days: fromDay));
  }

  /// Pencerenin son günü (dahil).
  DateTime? windowEnd(Pregnancy p) {
    final cipa = _anchorDay(p);
    return cipa?.add(Duration(days: toDay));
  }

  /// [today] itibarıyla hâlâ yapılacak mı: yapılmamış ve randevusu ya da
  /// penceresi geçmemiş.
  ///
  /// Panodaki "sıradaki" kartı ve randevu özeti aynı kuralı kullanıyor;
  /// ayrı yazılsaydı ikisi farklı "sıradaki"yi gösterebilirdi.
  bool isPendingOn(Pregnancy p, DateTime today) {
    if (done) return false;
    final gun = DateTime(today.year, today.month, today.day);
    final randevu = scheduledAt;
    if (randevu != null) {
      return !DateTime(randevu.year, randevu.month, randevu.day).isBefore(gun);
    }
    final son = windowEnd(p);
    return son != null && !son.isBefore(gun);
  }

  DateTime? _anchorDay(Pregnancy p) => switch (anchor) {
    CareAnchor.gestation => p.gestationStart,
    CareAnchor.postpartum => p.endedAt,
  };

  CareEvent copyWith({
    DateTime? scheduledAt,
    bool clearScheduledAt = false,
    bool? done,
    String? note,
    bool? reminderOn,
    int? fromDay,
    int? toDay,
  }) => CareEvent(
    id: id,
    pregnancyId: pregnancyId,
    code: code,
    title: title,
    category: category,
    anchor: anchor,
    fromDay: fromDay ?? this.fromDay,
    toDay: toDay ?? this.toDay,
    conditionKey: conditionKey,
    scheduledAt: clearScheduledAt ? null : (scheduledAt ?? this.scheduledAt),
    done: done ?? this.done,
    note: note ?? this.note,
    reminderOn: reminderOn ?? this.reminderOn,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'pregnancyId': pregnancyId,
    if (code != null) 'code': code,
    if (title != null) 'title': title,
    'category': category.name,
    'anchor': anchor.name,
    'fromDay': fromDay,
    'toDay': toDay,
    if (conditionKey != null) 'conditionKey': conditionKey,
    // Saat de saklanıyor: randevunun kendisi saatli.
    if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
    'done': done,
    if (note != null) 'note': note,
    'reminderOn': reminderOn,
  };

  /// Tanınmayan değerler kaydı düşürmüyor: ileri sürümde yeni bir kategori
  /// eklenirse eski sürüm kullanıcının randevusunu silmemeli.
  factory CareEvent.fromMap(Map<String, dynamic> map) => CareEvent(
    id: map['id'] as String? ?? 'care_${DateTime.now().microsecondsSinceEpoch}',
    pregnancyId: map['pregnancyId'] as String? ?? '',
    code: map['code'] as String?,
    title: map['title'] as String?,
    category: _enum(CareCategory.values, map['category'], CareCategory.visit),
    anchor: _enum(CareAnchor.values, map['anchor'], CareAnchor.gestation),
    fromDay: (map['fromDay'] as num?)?.toInt() ?? 0,
    toDay: (map['toDay'] as num?)?.toInt() ?? 0,
    conditionKey: map['conditionKey'] as String?,
    scheduledAt: map['scheduledAt'] is String
        ? DateTime.tryParse(map['scheduledAt'] as String)
        : null,
    done: map['done'] as bool? ?? false,
    note: map['note'] as String?,
    reminderOn: map['reminderOn'] as bool? ?? true,
  );

  static T _enum<T extends Enum>(List<T> values, Object? raw, T fallback) {
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }
}
