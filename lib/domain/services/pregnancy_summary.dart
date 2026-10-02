import '../models/care_event.dart';
import '../models/daily_log.dart';
import '../models/life_stage.dart';
import '../models/log_vocabulary.dart';
import '../models/pregnancy.dart';
import '../models/vitals.dart';

/// Tek tansiyon ölçümü.
class BloodPressureReading {
  final DateTime date;
  final int systolic;
  final int diastolic;

  const BloodPressureReading(this.date, this.systolic, this.diastolic);

  BloodPressureLevel get level => Vitals.classify(systolic, diastolic);
}

/// Tek kilo ölçümü.
class WeightReading {
  final DateTime date;
  final double kg;

  const WeightReading(this.date, this.kg);
}

/// Akış kaydedilmiş gün (gebelikte kanama, lohusalıkta lohia).
class FlowDay {
  final DateTime date;
  final String flow;

  const FlowDay(this.date, this.flow);
}

/// Bir belirtinin kaç gün kaydedildiği.
class SymptomCount {
  final String code;
  final int days;

  const SymptomCount(this.code, this.days);
}

/// Randevuya götürülecek özet — gebelik ya da lohusalık.
///
/// `ClinicalSummary`'nin gebelik karşılığı: muayenede hekimin sorduğu şey
/// toplu. Gebelikte kaç kez kanama oldu, tansiyon ne seyretti, kilo ne
/// kadar değişti, son iki haftada ne şikâyet edildi, hangi kontroller
/// yapıldı, hekime ne sorulacak.
///
/// Saf hesap: hiçbir sayı uydurulmuyor, kayıt yoksa liste boş kalıyor.
/// Teşhis yok; değerler kullanıcının kendi girdileri.
class PregnancySummary {
  final Pregnancy pregnancy;
  final LifeStage stage;
  final DateTime today;

  /// En yeniden eskiye, en çok [maxReadings] tane.
  final List<BloodPressureReading> bloodPressures;

  /// Dönemdeki bütün ölçümler ve 140/90 ve üstü olanlar.
  final int bloodPressureCount;
  final int highBloodPressureCount;

  final WeightReading? firstWeight;
  final WeightReading? lastWeight;

  /// Gebelikte kanama, lohusalıkta lohia — en yeniden eskiye.
  final List<FlowDay> flowDays;

  /// Son [symptomWindowDays] günde en sık kaydedilen belirtiler.
  final List<SymptomCount> recentSymptoms;

  final List<CareEvent> doneCare;
  final List<CareEvent> upcomingCare;

  /// Notu olan kalemler: "hekime soracaklarım" burada.
  final List<CareEvent> notedCare;

  static const int maxReadings = 10;
  static const int symptomWindowDays = 14;
  static const int maxSymptoms = 6;
  static const int maxUpcoming = 3;

  const PregnancySummary._({
    required this.pregnancy,
    required this.stage,
    required this.today,
    required this.bloodPressures,
    required this.bloodPressureCount,
    required this.highBloodPressureCount,
    required this.firstWeight,
    required this.lastWeight,
    required this.flowDays,
    required this.recentSymptoms,
    required this.doneCare,
    required this.upcomingCare,
    required this.notedCare,
  });

  /// Lohusalıkta doğumdan bu yana geçen gün.
  int? get daysSinceBirth {
    final dogum = pregnancy.endedAt;
    if (dogum == null) return null;
    return _day(today).difference(_day(dogum)).inDays;
  }

  /// Gebelikte bugünkü gebelik haftası.
  GestationalAge? get gestation => pregnancy.gestationOn(today);

  /// Kilo değişimi (son − ilk); iki ölçüm yoksa `null`.
  double? get weightChange {
    final ilk = firstWeight;
    final son = lastWeight;
    if (ilk == null || son == null || identical(ilk, son)) return null;
    return son.kg - ilk.kg;
  }

  factory PregnancySummary.build({
    required Pregnancy pregnancy,
    required LifeStage stage,
    required List<CareEvent> events,
    required List<DailyLog> logs,
    required DateTime today,
  }) {
    final gun = _day(today);
    // Dönem: gebelikte gebeliğin başından, lohusalıkta doğumdan bugüne.
    // Lohusalık özeti gebelik tansiyonlarını tekrar listelemiyor; hekim
    // doğum sonrası seyri soruyor.
    final dogum = pregnancy.endedAt;
    final bas = stage == LifeStage.postpartum && dogum != null
        ? _day(dogum)
        : _day(pregnancy.gestationStart);

    final donem = logs.where((l) {
      final d = _day(l.date);
      return !d.isBefore(bas) && !d.isAfter(gun);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    final tansiyon = [
      for (final l in donem)
        if (l.systolic != null && l.diastolic != null)
          BloodPressureReading(_day(l.date), l.systolic!, l.diastolic!),
    ];

    final kilolar = [
      for (final l in donem)
        if (l.weightKg != null) WeightReading(_day(l.date), l.weightKg!),
    ];

    // Gebelikte her kanama, lekelenme dahil, hekime söylenmeli. Lohusalıkta
    // lohianın seyri ("azaldı mı?") soruluyor; doğum günü hariç.
    final akis = [
      for (final l in donem)
        if (stage == LifeStage.pregnancy
            ? LogVocabulary.isBleeding(l.flowIntensity)
            : (l.flowIntensity != null && _day(l.date).isAfter(bas)))
          FlowDay(_day(l.date), l.flowIntensity!),
    ];

    final pencereBas = gun.subtract(
      const Duration(days: symptomWindowDays - 1),
    );
    final sayac = <String, int>{};
    for (final l in donem) {
      if (_day(l.date).isBefore(pencereBas)) continue;
      for (final b in l.symptoms.toSet()) {
        sayac[b] = (sayac[b] ?? 0) + 1;
      }
    }
    final belirtiler =
        sayac.entries.map((e) => SymptomCount(e.key, e.value)).toList()
          ..sort((a, b) {
            final f = b.days.compareTo(a.days);
            // Eşitlikte sözlük sırası: aynı veri her seferinde aynı özet.
            return f != 0
                ? f
                : LogVocabulary.allSymptoms
                      .indexOf(a.code)
                      .compareTo(LogVocabulary.allSymptoms.indexOf(b.code));
          });

    // Tarih sırası: randevusu olanın randevusu, olmayanın penceresi
    // (`PregnancyViewModel.currentEvents` ile aynı anahtar).
    DateTime anahtar(CareEvent e) =>
        e.scheduledAt ?? e.windowStart(pregnancy) ?? pregnancy.estimatedDueDate;
    final kalemler = events.where((e) => e.pregnancyId == pregnancy.id).toList()
      ..sort((a, b) => anahtar(a).compareTo(anahtar(b)));
    // Lohusalıkta gebelik kalemleri listeyi kalabalıklaştırmasın; notu
    // olanlar yine görünüyor (soru hâlâ sorulacak olabilir).
    bool donemde(CareEvent e) =>
        stage != LifeStage.postpartum ||
        e.isCustom ||
        e.anchor == CareAnchor.postpartum;

    return PregnancySummary._(
      pregnancy: pregnancy,
      stage: stage,
      today: gun,
      bloodPressures: tansiyon.take(maxReadings).toList(),
      bloodPressureCount: tansiyon.length,
      highBloodPressureCount: tansiyon
          .where((r) => r.level != BloodPressureLevel.normal)
          .length,
      firstWeight: kilolar.isEmpty ? null : kilolar.last,
      lastWeight: kilolar.isEmpty ? null : kilolar.first,
      flowDays: akis,
      recentSymptoms: belirtiler.take(maxSymptoms).toList(),
      doneCare: kalemler.where((e) => e.done && donemde(e)).toList(),
      upcomingCare: kalemler
          .where((e) => donemde(e) && e.isPendingOn(pregnancy, gun))
          .take(maxUpcoming)
          .toList(),
      notedCare: kalemler
          .where((e) => (e.note?.trim().isNotEmpty ?? false))
          .toList(),
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
