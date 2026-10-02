import '../models/calendar_day.dart';
import '../models/period_log.dart';

/// Sağlık uygulamasından gelen tek bir regl günü.
///
/// Platform tipinden ayrı tutuldu: birleştirme mantığı `health` paketi
/// olmadan test edilebilsin.
class HealthFlowDay {
  final DateTime date;

  /// Akış şiddeti — `LogVocabulary` kodları.
  final String? intensity;

  const HealthFlowDay({required this.date, this.intensity});
}

/// Sağlık verisinin uygulamanın kayıtlarıyla birleştirilmesi.
///
/// Apple Watch ve diğer uygulamaların verisi HealthKit üzerinden geliyor;
/// ayrı bir giyilebilir cihaz entegrasyonu gerekmiyor.
class HealthImport {
  const HealthImport._();

  /// Ardışık günleri dönemlere toplar.
  ///
  /// Sağlık uygulaması regli **gün gün** tutuyor; bu uygulama ise başlangıç
  /// ve bitişi olan dönemler hâlinde. Aradaki bir günlük boşluklar aynı
  /// dönemin parçası sayılır — kullanıcı bir günü işaretlemeyi unutmuş
  /// olabilir ve o boşluk yüzünden tek dönemi ikiye bölmek, ortalama döngü
  /// uzunluğunu bozar.
  static const int gapToleranceDays = 1;

  static List<PeriodLog> toPeriods(
    List<HealthFlowDay> days, {
    required String Function() nextId,
  }) {
    if (days.isEmpty) return const [];

    final sorted = days.map((d) => _dateOnly(d.date)).toSet().toList()..sort();

    final periods = <PeriodLog>[];
    var start = sorted.first;
    var previous = sorted.first;

    for (final day in sorted.skip(1)) {
      final gap = day.daysSince(previous);
      if (gap > gapToleranceDays + 1) {
        periods.add(
          PeriodLog(id: nextId(), startDate: start, endDate: previous),
        );
        start = day;
      }
      previous = day;
    }
    periods.add(PeriodLog(id: nextId(), startDate: start, endDate: previous));

    return periods;
  }

  /// Sağlık'tan gelen dönemleri mevcut kayıtlarla birleştirir.
  ///
  /// Çakışanlar **kullanıcının kendi kaydı** lehine bırakılır: uygulamada
  /// elle işaretlenen bir dönemi dış veriyle ezmek, kullanıcının düzeltmesini
  /// geri almak olurdu.
  static List<PeriodLog> merge({
    required List<PeriodLog> existing,
    required List<PeriodLog> incoming,
  }) {
    final result = List<PeriodLog>.from(existing);

    for (final candidate in incoming) {
      final overlaps = result.any((e) => _overlaps(e, candidate));
      if (!overlaps) result.add(candidate);
    }

    result.sort((a, b) => a.startDate.compareTo(b.startDate));
    return result;
  }

  /// Yalnızca içeri aktarılacak (yeni) dönemler — ekran "kaç kayıt eklenecek"
  /// diyebilsin.
  static List<PeriodLog> newOnes({
    required List<PeriodLog> existing,
    required List<PeriodLog> incoming,
  }) => incoming.where((c) => !existing.any((e) => _overlaps(e, c))).toList();

  static bool _overlaps(PeriodLog a, PeriodLog b) {
    final aEnd = _dateOnly(a.endDate ?? a.startDate);
    final bEnd = _dateOnly(b.endDate ?? b.startDate);
    final aStart = _dateOnly(a.startDate);
    final bStart = _dateOnly(b.startDate);
    return !aEnd.isBefore(bStart) && !bEnd.isBefore(aStart);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
