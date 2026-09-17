import 'dart:convert';

import 'log_vocabulary.dart';

/// Bir güne özel semptom, not gibi detayları tutan model.
///
/// [symptoms], [moods], [flowIntensity] ve [sexualActivity] alanları
/// **dilden bağımsız kodlar** tutar (bkz. [LogVocabulary]); ekranda görünecek
/// metin lokalizasyondan çözülür.
class DailyLog {
  final DateTime date;
  final List<String> symptoms;
  final String? notes;
  final String? flowIntensity;
  final List<String> moods;
  final String? sexualActivity;

  /// Ağrı şiddeti kodu (bkz. `LogVocabulary.painLevels`).
  ///
  /// Önceden ağrı yalnızca "kramp var/yok" olarak tutuluyordu. Şiddet bilgisi
  /// olmadan bir örüntü çıkmıyor: her ay bir gün kramp giren kullanıcıyla her
  /// ay üç gün yatakta kalan kullanıcı aynı görünüyordu.
  final String? painLevel;

  /// Ağrı o gün olağan etkinlikleri engelledi mi?
  ///
  /// Endometriozis için ayırt edici olan, ağrının varlığı değil "normal
  /// aktiviteni durdurması". Bu bayrak hekime gösterilecek somut veri
  /// üretiyor; NHS tanının uzun sürdüğünü ve birden fazla test gerektiğini
  /// belirtiyor.
  final bool painLimitedActivity;

  /// Ağrının nerede hissedildiği (bkz. `LogVocabulary.painLocations`).
  final List<String> painLocations;

  /// Ağrının hangi durumda ortaya çıktığı (bkz.
  /// `LogVocabulary.painContexts`).
  ///
  /// İlişkide ağrı, ağrılı büyük abdest ve idrar yolu ağrısı NICE'ın
  /// endometriozisten şüphelenmek için saydığı bulgular. Şiddet alanı
  /// bunların hiçbirini yakalamıyordu.
  final List<String> painContexts;

  DailyLog({
    required this.date,
    this.symptoms = const [],
    this.notes,
    this.flowIntensity,
    this.moods = const [],
    this.sexualActivity,
    this.painLevel,
    this.painLimitedActivity = false,
    this.painLocations = const [],
    this.painContexts = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'symptoms': symptoms,
      'notes': notes,
      'flowIntensity': flowIntensity,
      'moods': moods,
      'sexualActivity': sexualActivity,
      'painLevel': painLevel,
      'painLimitedActivity': painLimitedActivity,
      'painLocations': painLocations,
      'painContexts': painContexts,
    };
  }

  /// Okurken eski kayıtlar kanonik kodlara normalize edilir; böylece
  /// çevrilmiş etiketle saklanmış veriler kaybolmaz.
  factory DailyLog.fromMap(Map<String, dynamic> map) {
    final rawFlow = map['flowIntensity'] as String?;
    final rawSexualActivity = map['sexualActivity'] as String?;

    return DailyLog(
      date: DateTime.parse(map['date']),
      symptoms: LogVocabulary.normalizeAll(
        List<String>.from(map['symptoms'] ?? []),
        LogVocabulary.symptoms,
      ),
      notes: map['notes'],
      flowIntensity: rawFlow == null
          ? null
          : LogVocabulary.normalize(rawFlow, LogVocabulary.flowIntensities),
      moods: LogVocabulary.normalizeAll(
        List<String>.from(map['moods'] ?? []),
        LogVocabulary.moods,
      ),
      painLevel: map['painLevel'] == null
          ? null
          : LogVocabulary.normalize(
              map['painLevel'] as String,
              LogVocabulary.painLevels,
            ),
      // Eski kayıtlarda bu alan yok; varsayılan false.
      painLimitedActivity: map['painLimitedActivity'] as bool? ?? false,
      painLocations: LogVocabulary.normalizeAll(
        List<String>.from(map['painLocations'] ?? []),
        LogVocabulary.painLocations,
      ),
      painContexts: LogVocabulary.normalizeAll(
        List<String>.from(map['painContexts'] ?? []),
        LogVocabulary.painContexts,
      ),
      sexualActivity: rawSexualActivity == null
          ? null
          : LogVocabulary.normalize(
              rawSexualActivity,
              LogVocabulary.sexualActivities,
            ),
    );
  }

  String toJson() => json.encode(toMap());

  factory DailyLog.fromJson(String source) =>
      DailyLog.fromMap(json.decode(source));
}
