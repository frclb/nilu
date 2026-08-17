import 'dart:convert';

/// Kullanıcının regl dönemini temsil eden model.
class PeriodLog {
  /// Bitişi girilmemiş (devam eden) bir dönem için varsayılan projeksiyon
  /// uzunluğu. Kullanıcının kendi ayarı varsa çağıran taraf onu geçmelidir.
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
    return endDate!.difference(startDate).inDays + 1;
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

  /// [date] bu döneme dahil mi?
  ///
  /// Dönem devam ediyorsa bitişi bilinmediği için [ongoingLength] günlük bir
  /// projeksiyon kullanılır; çağıran taraf kullanıcının ayarladığı regl
  /// süresini geçmelidir.
  bool contains(DateTime date, {int ongoingLength = defaultOngoingLength}) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    final cleanStart = DateTime(startDate.year, startDate.month, startDate.day);

    final DateTime cleanEnd;
    if (isOngoing) {
      final days = ongoingLength < 1 ? 1 : ongoingLength;
      cleanEnd = cleanStart.add(Duration(days: days - 1));
    } else {
      cleanEnd = DateTime(endDate!.year, endDate!.month, endDate!.day);
    }

    return !cleanDate.isBefore(cleanStart) && !cleanDate.isAfter(cleanEnd);
  }
}
