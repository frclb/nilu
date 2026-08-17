import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Ay ve gün adları.
///
/// Adlar `calendar_months`, `calendar_months_short` ve `calendar_weekdays`
/// anahtarlarında virgülle ayrılmış tek satır olarak tutulur. Bu uzantı,
/// ayrıştırma ve sınır kontrolünü tek yerde toplar — daha önce her ekran
/// kendi `split(',')` + fallback mantığını tekrarlıyordu.
extension DateNames on BuildContext {
  List<String> _names(String key, int expected) {
    final raw = tr(key);
    final parts = raw.split(',').map((s) => s.trim()).toList();
    return parts.length == expected ? parts : const [];
  }

  List<String> get monthNames => _names('calendar_months', 12);
  List<String> get shortMonthNames => _names('calendar_months_short', 12);
  List<String> get weekdayNames => _names('calendar_weekdays', 7);

  /// 1-12 arası ay numarası için tam ad. Çeviri eksikse ay numarası döner.
  String monthName(int month) {
    final names = monthNames;
    if (month < 1 || month > names.length) return '$month';
    return names[month - 1];
  }

  /// 1-12 arası ay numarası için kısaltma. Çeviri eksikse tam ada düşer.
  String shortMonthName(int month) {
    final names = shortMonthNames;
    if (month < 1 || month > names.length) return monthName(month);
    return names[month - 1];
  }

  /// [DateTime.weekday] (1 = Pazartesi) için gün adı.
  String weekdayName(int weekday) {
    final names = weekdayNames;
    if (weekday < 1 || weekday > names.length) return '$weekday';
    return names[weekday - 1];
  }
}
