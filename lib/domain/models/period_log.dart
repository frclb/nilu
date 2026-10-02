import 'calendar_day.dart';
import 'dart:convert';

/// Kullanıcının regl dönemini temsil eden model.
class PeriodLog {
  /// Devam eden bir dönemin kaç gün süreceği beklentisi. Kullanıcının kendi
  /// ayarı varsa çağıran taraf onu geçmelidir.
  static const int defaultOngoingLength = 5;

  final String id;
  DateTime startDate;
  DateTime? endDate;

  PeriodLog({required this.id, required this.startDate, this.endDate});

  bool get isOngoing => endDate == null;

  /// Tamamlanmış dönemin gün sayısı. Dönem hâlâ devam ediyorsa null döner —
  /// böylece ortalama hesapları uydurma bir sabitle sapmaz.
  int? get completedLength {
    if (isOngoing) return null;
    return endDate!.daysSince(startDate) + 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }

  factory PeriodLog.fromMap(Map<String, dynamic> map) {
    return PeriodLog(
      id: map['id'],
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PeriodLog.fromJson(String source) =>
      PeriodLog.fromMap(json.decode(source));

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Dönemin ilk günü, saat bilgisi olmadan.
  DateTime get firstDay => _day(startDate);

  /// Kayıt düşülmüş son gün.
  ///
  /// Dönem devam ediyorsa bugün: yarın kanama olup olmayacağı henüz veri
  /// değil. Önceden burada kullanıcının regl süresi kadar ileri bir
  /// projeksiyon vardı ve takvim o günleri de gerçek kayıtmış gibi koyu
  /// boyuyordu — kullanıcının girmediği bir şeyi iddia ediyordu.
  DateTime lastRecordedDay({DateTime? today}) {
    final end = endDate;
    if (end != null) return _day(end);
    final reference = _day(today ?? DateTime.now());
    return reference.isBefore(firstDay) ? firstDay : reference;
  }

  /// [date] bu döneme **kayıtlı** bir gün olarak dahil mi?
  bool containsRecorded(DateTime date, {DateTime? today}) {
    final cleanDate = _day(date);
    return !cleanDate.isBefore(firstDay) &&
        !cleanDate.isAfter(lastRecordedDay(today: today));
  }

  /// [date], devam eden bu dönemin bugünden sonraki **beklenen** günü mü?
  ///
  /// Takvim bu günleri tahmin olarak gösteriyor: kanamanın süreceği tahmin
  /// ediliyor ama henüz yaşanmadı.
  bool isExpectedContinuation(
    DateTime date, {
    DateTime? today,
    int expectedLength = defaultOngoingLength,
  }) {
    if (!isOngoing) return false;
    final cleanDate = _day(date);
    final last = lastRecordedDay(today: today);
    if (!cleanDate.isAfter(last)) return false;
    final days = expectedLength < 1 ? 1 : expectedLength;
    return !cleanDate.isAfter(firstDay.plusDays(days - 1));
  }

  /// Bugüne kadar kaç gün kayıt düşülmüş.
  int recordedLength({DateTime? today}) =>
      lastRecordedDay(today: today).daysSince(firstDay) + 1;
}
