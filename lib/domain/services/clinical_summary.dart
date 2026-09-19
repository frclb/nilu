import '../models/daily_log.dart';
import '../models/period_log.dart';
import '../models/log_vocabulary.dart';
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

  /// Ağrının hangi bölgede kaç gün kaydedildiği (koda göre, azalan).
  final List<SymptomFrequency> painLocationDays;

  /// Ağrının hangi durumda kaç gün kaydedildiği (koda göre, azalan).
  ///
  /// İlişkide ağrı, ağrılı büyük abdest ve idrar yolu ağrısı NICE'ın
  /// endometriozisten şüphelenmek için saydığı bulgular. Muayenede
  /// sorulan şey tam olarak bu; kullanıcının elinde kendi sayısı olsun.
  final List<SymptomFrequency> painContextDays;

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
    required this.painLocationDays,
    required this.painContextDays,
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

    final withContent = dailyLogs.where((l) => l.hasContent).toList()
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
      painLocationDays: _countCodes(
        dailyLogs.map((l) => l.painLocations),
        LogVocabulary.painLocations,
      ),
      painContextDays: _countCodes(
        dailyLogs.map((l) => l.painContexts),
        LogVocabulary.painContexts,
      ),
      topSymptoms: InsightsService.symptomFrequencies(
        dailyLogs,
      ).take(3).toList(),
      firstLoggedDay: withContent.isEmpty ? null : withContent.first.date,
      lastLoggedDay: withContent.isEmpty ? null : withContent.last.date,
    );
  }


  /// Kod listelerinden gün sayısı çıkarır; hiç kaydedilmemiş kodlar düşer.
  ///
  /// En çok kaydedilen önce; eşitlik [order] sırasıyla çözülüyor.
  static List<SymptomFrequency> _countCodes(
    Iterable<List<String>> entries,
    List<String> order,
  ) {
    final counts = <String, int>{};
    var total = 0;
    for (final codes in entries) {
      total++;
      for (final code in codes.toSet()) {
        counts[code] = (counts[code] ?? 0) + 1;
      }
    }

    return order
        .where(counts.containsKey)
        .map(
          (code) => SymptomFrequency(
            code: code,
            dayCount: counts[code]!,
            loggedDayCount: total,
          ),
        )
        .toList()
      // Eşit sayıdaki kodlar sözlükteki sıraya göre çözülüyor. `List.sort`
      // Dart'ta kararlı değil; eşitliği açıkça çözmezsek aynı veri iki
      // farklı sırada çıkabilir ve dışa aktarım hekime gösterilirken
      // güven kırar.
      ..sort((a, b) {
        final byCount = b.dayCount.compareTo(a.dayCount);
        if (byCount != 0) return byCount;
        return order.indexOf(a.code).compareTo(order.indexOf(b.code));
      });
  }
}
