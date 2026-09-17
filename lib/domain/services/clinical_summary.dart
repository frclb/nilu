import '../models/daily_log.dart';
import '../models/period_log.dart';
import 'cycle_alert.dart';
import 'insights_service.dart';

/// Muayenede tek bakışta okunabilecek toplu özet.
///
/// Uygulamanın dışa aktarması her kayıtlı günü tek tek döküyordu. Altmış
/// satırlık bir günlük, muayenede kimsenin okuyacağı bir şey değil. Hekimin
/// sorduğu şey toplu: kaç döngü gözlenmiş, ortalama ne, en kısa ve en uzun
/// hangisi, ağrı kaç gün aktiviteyi engellemiş.
///
/// Saf hesap: hiçbir sayı uydurulmuyor, veri yoksa alan `null` kalıyor.
class ClinicalSummary {
  /// Gözlenmiş döngü sayısı (tahmin değil, iki kayıtlı regl arası).
  final int observedCycles;

  final int? averageCycleDays;
  final int? shortestCycleDays;
  final int? longestCycleDays;

  /// En kısa ve en uzun arasındaki gün farkı.
  final int? variationDays;

  /// Sağlık kurumlarının eşiklerine göre üretilen uyarılar.
  final Set<CycleAlert> alerts;

  /// Tamamlanmış dönemlerin ortalama uzunluğu.
  final int? averagePeriodDays;

  /// Tamamlanmış en uzun dönem.
  final int? longestPeriodDays;

  /// Ağrı kaydedilen gün sayısı.
  final int painDays;

  /// Şiddetli ağrı kaydedilen gün sayısı.
  final int severePainDays;

  /// Ağrının olağan etkinlikleri engellediği gün sayısı.
  ///
  /// Endometriozis değerlendirmesinde ayırt edici olan sayı bu.
  final int painLimitedDays;

  /// Akışın "yoğun" işaretlendiği gün sayısı.
  final int heavyFlowDays;

  /// Regl dönemlerinin dışında kalan kanama atağı sayısı.
  ///
  /// Hekimin "regl aranda kanaman oluyor mu, kaç kez?" sorusunun cevabı.
  /// Arka arkaya gelen günler tek atak sayılıyor.
  final int intermenstrualBleedingEpisodes;

  /// En sık kaydedilen belirtiler (en çoktan aza, en fazla üç tane).
  final List<SymptomFrequency> topSymptoms;

  /// Kayıt girilen ilk ve son gün.
  final DateTime? firstLoggedDay;
  final DateTime? lastLoggedDay;

  const ClinicalSummary({
    required this.observedCycles,
    required this.alerts,
    required this.painDays,
    required this.severePainDays,
    required this.painLimitedDays,
    required this.heavyFlowDays,
    required this.intermenstrualBleedingEpisodes,
    required this.topSymptoms,
    this.averageCycleDays,
    this.shortestCycleDays,
    this.longestCycleDays,
    this.variationDays,
    this.averagePeriodDays,
    this.longestPeriodDays,
    this.firstLoggedDay,
    this.lastLoggedDay,
  });

  /// Özette gösterilecek bir şey var mı?
  bool get hasData => observedCycles > 0 || firstLoggedDay != null;

  static ClinicalSummary build({
    required List<PeriodLog> periodLogs,
    required List<DailyLog> dailyLogs,
    int cycleLimit = 12,
  }) {
    final cycles = InsightsService.cycleLengths(periodLogs, limit: cycleLimit);
    final bleedingEpisodes = CycleAlertService.intermenstrualEpisodes(
      dailyLogs: dailyLogs,
      periodLogs: periodLogs,
    );
    final lengths = cycles.map((c) => c.lengthInDays).toList()..sort();

    // Yalnızca tamamlanmış dönemler: devam eden bir dönemin gerçek uzunluğu
    // henüz bilinmiyor, onu ortalamaya katmak sayıyı saptırır.
    final periodDays =
        periodLogs.map((l) => l.completedLength).whereType<int>().toList()
          ..sort();

    final withContent = dailyLogs.where(_hasContent).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return ClinicalSummary(
      observedCycles: cycles.length,
      averageCycleDays: InsightsService.averageLength(cycles),
      shortestCycleDays: lengths.isEmpty ? null : lengths.first,
      longestCycleDays: lengths.isEmpty ? null : lengths.last,
      variationDays: InsightsService.variation(cycles),
      alerts: CycleAlertService.evaluate(
        cycles,
        dailyLogs: dailyLogs,
        periodLogs: periodLogs,
      ),
      averagePeriodDays: periodDays.isEmpty
          ? null
          : (periodDays.reduce((a, b) => a + b) / periodDays.length).round(),
      longestPeriodDays: periodDays.isEmpty ? null : periodDays.last,
      painDays: dailyLogs.where((l) => l.painLevel != null).length,
      severePainDays: dailyLogs.where((l) => l.painLevel == 'severe').length,
      painLimitedDays: dailyLogs.where((l) => l.painLimitedActivity).length,
      heavyFlowDays: dailyLogs.where((l) => l.flowIntensity == 'heavy').length,
      intermenstrualBleedingEpisodes: bleedingEpisodes.length,
      topSymptoms: InsightsService.symptomFrequencies(
        dailyLogs,
      ).take(3).toList(),
      firstLoggedDay: withContent.isEmpty ? null : withContent.first.date,
      lastLoggedDay: withContent.isEmpty ? null : withContent.last.date,
    );
  }

  static bool _hasContent(DailyLog log) =>
      log.symptoms.isNotEmpty ||
      log.moods.isNotEmpty ||
      log.flowIntensity != null ||
      log.painLevel != null ||
      (log.notes?.isNotEmpty ?? false);
}
