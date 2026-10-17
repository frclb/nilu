import 'dart:convert';

import 'log_vocabulary.dart';
import 'vitals.dart';

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

  /// Ev gebelik testi sonucu kodu (bkz. `LogVocabulary.pregnancyTests`).
  final String? pregnancyTest;

  /// Evde ölçülen kilo (kg). Gebelik ve lohusalıkta, isteğe bağlı.
  final double? weightKg;

  /// Evde ölçülen tansiyon (mmHg). İkisi birlikte var ya da ikisi de yok.
  final int? systolic;
  final int? diastolic;

  DailyLog({
    required this.date,
    this.symptoms = const [],
    this.notes,
    this.flowIntensity,
    this.moods = const [],
    this.sexualActivity,
    this.pregnancyTest,
    this.painLevel,
    this.painLimitedActivity = false,
    this.painLocations = const [],
    this.painContexts = const [],
    this.weightKg,
    this.systolic,
    this.diastolic,
  });

  /// Değiştirilmeyen her alan aynen kalan kopya — sonradan eklenen alanlar
  /// da.
  ///
  /// Kayıt önceden dört ayrı yerde alan alan yeniden kuruluyordu (kayıt
  /// ekranı, gün ayrıntısının iki yolu, lohusa panosu). Modele bir alan
  /// eklendiğinde biri unutulursa o alan o yoldan her kayıtta sessizce
  /// siliniyordu.
  ///
  /// `clear…` bayrakları: `null` "dokunma" demek; bir alanı boşaltmanın
  /// yolu bayrak. Ağrı kaldırılınca yeri ve bağlamı da düşüyor — "ağrım
  /// yok ama ilişkide ağrıyor" diye bir kayıt kalmamalı.
  DailyLog copyWith({
    List<String>? symptoms,
    String? notes,
    bool clearNotes = false,
    String? flowIntensity,
    bool clearFlow = false,
    List<String>? moods,
    String? sexualActivity,
    bool clearSexualActivity = false,
    String? pregnancyTest,
    bool clearPregnancyTest = false,
    String? painLevel,
    bool clearPain = false,
    bool? painLimitedActivity,
    List<String>? painLocations,
    List<String>? painContexts,
    double? weightKg,
    bool clearWeight = false,
    int? systolic,
    int? diastolic,
    bool clearBloodPressure = false,
  }) => DailyLog(
    date: date,
    symptoms: symptoms ?? this.symptoms,
    notes: clearNotes ? null : (notes ?? this.notes),
    flowIntensity: clearFlow ? null : (flowIntensity ?? this.flowIntensity),
    moods: moods ?? this.moods,
    sexualActivity: clearSexualActivity
        ? null
        : (sexualActivity ?? this.sexualActivity),
    pregnancyTest: clearPregnancyTest
        ? null
        : (pregnancyTest ?? this.pregnancyTest),
    painLevel: clearPain ? null : (painLevel ?? this.painLevel),
    painLimitedActivity: clearPain
        ? false
        : (painLimitedActivity ?? this.painLimitedActivity),
    painLocations: clearPain ? const [] : (painLocations ?? this.painLocations),
    painContexts: clearPain ? const [] : (painContexts ?? this.painContexts),
    weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
    systolic: clearBloodPressure ? null : (systolic ?? this.systolic),
    diastolic: clearBloodPressure ? null : (diastolic ?? this.diastolic),
  );

  /// Yalnızca akışı değiştirilmiş kopya.
  ///
  /// `CalendarViewModel.updateDailyLog` günün kaydının **tamamını**
  /// değiştiriyor. Lohusa panosundaki tek dokunuşluk "bugünkü kanama"
  /// seçimi yeni bir `DailyLog` kursaydı o günün semptomları, ruh hali ve
  /// notu silinirdi.
  DailyLog withFlowIntensity(String? flow) =>
      copyWith(flowIntensity: flow, clearFlow: flow == null);

  /// Bu günde kullanıcının girdiği bir şey var mı?
  ///
  /// Tek kaynak: dışa aktarma ile klinik özet bunu ayrı ayrı tanımlıyordu
  /// ve tanımlar ayrışmıştı. Özet ağrıyı sayıyor, dışa aktarma saymıyordu;
  /// sonuç, "şu tarihten şu tarihe kayıt var" deyip o günleri listelemeyen
  /// bir belgeydi. Üstelik yalnızca ağrı girilmiş bir gün — klinik olarak
  /// en ağır kayıt — hekime giden belgeden tamamen düşüyordu.
  bool get hasContent =>
      symptoms.isNotEmpty ||
      moods.isNotEmpty ||
      flowIntensity != null ||
      sexualActivity != null ||
      pregnancyTest != null ||
      painLevel != null ||
      painLimitedActivity ||
      painLocations.isNotEmpty ||
      painContexts.isNotEmpty ||
      weightKg != null ||
      systolic != null ||
      (notes?.isNotEmpty ?? false);

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'symptoms': symptoms,
      'notes': notes,
      'flowIntensity': flowIntensity,
      'moods': moods,
      'sexualActivity': sexualActivity,
      'pregnancyTest': pregnancyTest,
      'painLevel': painLevel,
      'painLimitedActivity': painLimitedActivity,
      'painLocations': painLocations,
      'painContexts': painContexts,
      'weightKg': weightKg,
      'systolic': systolic,
      'diastolic': diastolic,
    };
  }

  /// Okurken eski kayıtlar kanonik kodlara normalize edilir; böylece
  /// çevrilmiş etiketle saklanmış veriler kaybolmaz.
  factory DailyLog.fromMap(Map<String, dynamic> map) {
    final rawFlow = map['flowIntensity'] as String?;
    final rawSexualActivity = map['sexualActivity'] as String?;
    final rawPregnancyTest = map['pregnancyTest'] as String?;

    // Ölçümler aralık dışındaysa düşüyor: bozuk bir yedek ya da elle
    // düzenlenmiş bir dosya hekime giden özete "1205 mmHg" koymasın.
    final kilo = (map['weightKg'] as num?)?.toDouble();
    final buyuk = (map['systolic'] as num?)?.toInt();
    final kucuk = (map['diastolic'] as num?)?.toInt();
    final tansiyonGecerli =
        buyuk != null &&
        kucuk != null &&
        Vitals.isPlausibleBloodPressure(buyuk, kucuk);

    return DailyLog(
      date: DateTime.parse(map['date']),
      symptoms: LogVocabulary.normalizeAll(
        List<String>.from(map['symptoms'] ?? []),
        LogVocabulary.allSymptoms,
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
      // Tanınmayan değer düşüyor: bozuk bir yedek "pozitif" diye okunup
      // gebelik önerisi göstermesin.
      pregnancyTest: rawPregnancyTest == null
          ? null
          : LogVocabulary.normalize(
              rawPregnancyTest,
              LogVocabulary.pregnancyTests,
            ),
      weightKg: kilo != null && Vitals.isPlausibleWeight(kilo) ? kilo : null,
      systolic: tansiyonGecerli ? buyuk : null,
      diastolic: tansiyonGecerli ? kucuk : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory DailyLog.fromJson(String source) =>
      DailyLog.fromMap(json.decode(source));
}
