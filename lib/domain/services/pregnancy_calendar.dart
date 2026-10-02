import '../models/care_event.dart';
import '../models/life_stage.dart';
import '../models/pregnancy.dart';

/// Takvimde bir günün gebelikle ilgili bilgisi.
class PregnancyDayInfo {
  /// O gün kaç haftalık (süren ya da doğumla biten gebelikte).
  final GestationalAge? gestation;

  /// Doğumdan sonraki gün (lohusalık aralığında; doğum günü 0).
  final int? postpartumDay;

  /// Süren gebeliğin tahmini doğum günü.
  final bool isDueDate;

  /// Doğumla biten gebeliğin doğum günü.
  final bool isBirthDay;

  /// O gün randevusu olan kalemler.
  final List<CareEvent> appointments;

  const PregnancyDayInfo({
    this.gestation,
    this.postpartumDay,
    this.isDueDate = false,
    this.isBirthDay = false,
    this.appointments = const [],
  });

  static const PregnancyDayInfo none = PregnancyDayInfo();
}

/// Gebeliğin takvimdeki izi.
///
/// Gebelik aylar sürüyor; takvimde her günün kaçıncı hafta olduğu,
/// randevuların kendi tarihlerinde ve tahmini doğum günü görünmeli.
///
/// Yalnızca süren ve **doğumla** biten gebelikler takvimde anılıyor. Kayıpla
/// (düşük, dış gebelik, ölü doğum, sonlandırma) ya da sonucu belirtilmeden
/// biten bir gebeliğin haftaları takvimde gezinirken önüne çıkmamalı;
/// geçmiş gebelikler ekranı onların bilinçli olarak açılan yeri.
class PregnancyCalendar {
  const PregnancyCalendar._();

  /// Süren gebelikte tahmini doğumdan sonra haftalar bu kadar gösteriliyor
  /// (42+0: geç doğumun sınırı); daha ötesi anlamsız bir "60+3" olurdu.
  static const int maxGestationDays = 42 * 7;

  static bool _shown(Pregnancy p) =>
      p.isActive || p.outcome == PregnancyOutcome.birth;

  static PregnancyDayInfo dayInfo({
    required Iterable<Pregnancy> pregnancies,
    required Iterable<CareEvent> events,
    required DateTime date,
  }) {
    final gun = _day(date);
    GestationalAge? hafta;
    int? lohusa;
    var dogumGunu = false;
    var tahmini = false;
    final gosterilen = <String>{};

    for (final p in pregnancies) {
      if (!_shown(p)) continue;
      gosterilen.add(p.id);

      final fark = gun.difference(_day(p.gestationStart)).inDays;
      final bitis = p.endedAt;
      if (fark >= 0 &&
          (bitis == null
              ? fark <= maxGestationDays
              : gun.isBefore(_day(bitis)))) {
        hafta = GestationalAge(fark ~/ 7, fark % 7);
      }
      if (p.isActive && gun == _day(p.estimatedDueDate)) tahmini = true;

      if (bitis != null) {
        final dogum = _day(bitis);
        final son = LifeStage.postpartumEndOf(p);
        if (!gun.isBefore(dogum) && son != null && gun.isBefore(son)) {
          lohusa = gun.difference(dogum).inDays;
        }
        if (gun == dogum) dogumGunu = true;
      }
    }

    final randevular = [
      for (final e in events)
        if (gosterilen.contains(e.pregnancyId) &&
            e.scheduledAt != null &&
            _day(e.scheduledAt!) == gun)
          e,
    ]..sort((a, b) => a.scheduledAt!.compareTo(b.scheduledAt!));

    if (hafta == null &&
        lohusa == null &&
        !tahmini &&
        !dogumGunu &&
        randevular.isEmpty) {
      return PregnancyDayInfo.none;
    }
    return PregnancyDayInfo(
      gestation: hafta,
      postpartumDay: lohusa,
      isDueDate: tahmini,
      isBirthDay: dogumGunu,
      appointments: randevular,
    );
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
