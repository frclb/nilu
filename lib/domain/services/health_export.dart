import '../models/calendar_day.dart';
import '../models/daily_log.dart';
import '../models/log_vocabulary.dart';
import '../models/period_log.dart';

/// Apple Sağlık'a yazılacak bir regl günü.
class HealthPeriodDay {
  final DateTime date;

  /// Kullanıcının o gün girdiği akış (`light`, `medium`, `heavy`).
  ///
  /// Girmediyse `null` ve Sağlık'a "belirtilmemiş" yazılıyor. Önceden her
  /// güne "orta" yazılıyordu: kullanıcının söylemediği bir yoğunluk başka
  /// uygulamalarda onun verisi gibi görünecekti.
  final String? flow;

  /// Dönemin ilk günü mü (Sağlık döngü başlangıcını bununla işaretliyor).
  final bool isStartOfCycle;

  const HealthPeriodDay(this.date, {this.flow, required this.isStartOfCycle});
}

/// Uygulamadaki regl kayıtlarından Sağlık'a yazılacak günler.
///
/// Saf hesap; platform çağrısı `HealthDatasource.mirrorPeriods`'ta.
class HealthExport {
  const HealthExport._();

  static List<HealthPeriodDay> periodDays({
    required List<PeriodLog> periods,
    required List<DailyLog> dailyLogs,
    required DateTime today,
  }) {
    String anahtar(DateTime d) => '${d.year}-${d.month}-${d.day}';
    final akis = <String, String>{
      for (final l in dailyLogs)
        if (LogVocabulary.startsPeriod(l.flowIntensity))
          anahtar(l.date): l.flowIntensity!,
    };

    final sirali = [...periods]
      ..sort((a, b) => a.firstDay.compareTo(b.firstDay));
    final gunler = <String, HealthPeriodDay>{};
    for (final p in sirali) {
      final son = p.lastRecordedDay(today: today);
      for (var d = p.firstDay; !d.isAfter(son); d = d.plusDays(1)) {
        gunler.putIfAbsent(
          anahtar(d),
          () => HealthPeriodDay(
            d,
            flow: akis[anahtar(d)],
            isStartOfCycle: d == p.firstDay,
          ),
        );
      }
    }
    return gunler.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }
}
