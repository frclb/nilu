import '../../domain/models/calendar_day.dart';
import '../../domain/models/care_event.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/models/pregnancy.dart';

/// Bir bakım kaleminin listedeki yeri.
enum CareGroup { now, upcoming, past }

/// Randevu listesinin gruplaması.
class CareGrouping {
  const CareGrouping._();

  /// "Şimdi" penceresi: randevusu önümüzdeki bu kadar gün içinde olanlar da
  /// şimdi sayılıyor — yarınki randevu "yaklaşan" listesinde kaybolmasın.
  static const int soonDays = 14;

  static CareGroup of(CareEvent e, Pregnancy p, DateTime today) {
    final gun = DateTime(today.year, today.month, today.day);
    if (e.done) return CareGroup.past;

    final randevu = e.scheduledAt;
    if (randevu != null) {
      final r = DateTime(randevu.year, randevu.month, randevu.day);
      if (r.isBefore(gun)) return CareGroup.past;
      return r.daysSince(gun) <= soonDays ? CareGroup.now : CareGroup.upcoming;
    }

    // Tarihi olmayan kendi kalemi: kullanıcı onu hatırlamak için ekledi,
    // görünür kalsın.
    if (e.isCustom) return CareGroup.now;

    final bas = e.windowStart(p);
    final son = e.windowEnd(p);
    if (bas == null || son == null) return CareGroup.upcoming;
    if (son.isBefore(gun)) return CareGroup.past;
    if (bas.isAfter(gun)) return CareGroup.upcoming;
    return CareGroup.now;
  }

  /// Bu evrede listede gösterilecek kalemler.
  ///
  /// Lohusalıkta gebelik taramaları geçmişte kaldı; listeyi kalabalıklaştırıp
  /// sıradaki lohusa izlemini gömmesinler.
  static List<CareEvent> visible(List<CareEvent> events, LifeStage stage) =>
      stage == LifeStage.postpartum
      ? events
            .where((e) => e.isCustom || e.anchor == CareAnchor.postpartum)
            .toList()
      : events;
}
