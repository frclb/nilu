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

  DailyLog({
    required this.date,
    this.symptoms = const [],
    this.notes,
    this.flowIntensity,
    this.moods = const [],
    this.sexualActivity,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'symptoms': symptoms,
      'notes': notes,
      'flowIntensity': flowIntensity,
      'moods': moods,
      'sexualActivity': sexualActivity,
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
