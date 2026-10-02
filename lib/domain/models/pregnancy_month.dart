import 'pregnancy.dart';

/// Gebeliğin bir ayı.
///
/// Hekimler hafta kullanıyor; "kaç aylık hamilesin?" ise günlük dilde ve
/// kullanıcı süreci aylarla düşünüyor. Ayların hafta karşılığı kaynaktan
/// kaynağa değişiyor; burada trimesterlere oturacak biçimde bölündü (ACOG:
/// 1. trimester 13+6'ya, 2. trimester 27+6'ya kadar): 1–3. ay birinci, 4–6.
/// ay ikinci, 7–9. ay üçüncü trimester. Böylece panoda "6. ay · 2.
/// trimester" hiçbir hafta çelişmiyor.
///
/// Haftalar uygulamanın geri kalanı gibi **tamamlanan hafta**: 6. ay
/// "23–27. hafta" = 23+0 ile 27+6 arası; panodaki "24+1" bu aralıkta.
class PregnancyMonth {
  /// 1–9.
  final int number;

  /// Tamamlanan hafta, ikisi de dahil.
  final int fromWeek;
  final int toWeek;

  const PregnancyMonth._(this.number, this.fromWeek, this.toWeek);

  static const List<PregnancyMonth> all = [
    PregnancyMonth._(1, 0, 3),
    PregnancyMonth._(2, 4, 7),
    PregnancyMonth._(3, 8, 13),
    PregnancyMonth._(4, 14, 17),
    PregnancyMonth._(5, 18, 22),
    PregnancyMonth._(6, 23, 27),
    PregnancyMonth._(7, 28, 31),
    PregnancyMonth._(8, 32, 35),
    PregnancyMonth._(9, 36, 40),
  ];

  /// [ga] hangi ayda? 40. haftadan sonrası (gecikmiş doğum) 9. ay.
  static PregnancyMonth of(GestationalAge ga) =>
      all.lastWhere((m) => ga.weeks >= m.fromWeek);

  Trimester get trimester => number <= 3
      ? Trimester.first
      : number <= 6
      ? Trimester.second
      : Trimester.third;

  /// Ayın ilk günü.
  DateTime startIn(Pregnancy p) => _gun(p.gestationStart, fromWeek * 7);

  /// Ayın son günü (dahil).
  DateTime endIn(Pregnancy p) => _gun(p.gestationStart, toWeek * 7 + 6);

  /// [date] bu aya mı düşüyor?
  bool contains(Pregnancy p, DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return !d.isBefore(startIn(p)) && !d.isAfter(endIn(p));
  }

  /// Gün ekleme takvim üzerinden: `Duration` yaz saati geçişinde gece
  /// yarısını bir saat kaydırıp tarihi bir gün geri atabiliyordu.
  static DateTime _gun(DateTime d, int ek) =>
      DateTime(d.year, d.month, d.day + ek);
}
