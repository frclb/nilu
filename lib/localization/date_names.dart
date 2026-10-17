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

  /// İki gün arası: aynı ayda "20–23 Ekim", ay değişiyorsa kısa adlarla
  /// "30 Eyl – 2 Eki". Aynı günse tek tarih.
  String dayRange(DateTime a, DateTime b) {
    if (a.year == b.year && a.month == b.month) {
      if (a.day == b.day) return '${a.day} ${monthName(a.month)}';
      return '${a.day}–${b.day} ${monthName(a.month)}';
    }
    return '${a.day} ${shortMonthName(a.month)} – '
        '${b.day} ${shortMonthName(b.month)}';
  }

  /// [DateTime.weekday] (1 = Pazartesi) için gün adı.
  String weekdayName(int weekday) {
    final names = weekdayNames;
    if (weekday < 1 || weekday > names.length) return '$weekday';
    return names[weekday - 1];
  }
}
