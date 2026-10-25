import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Ay ve gün adları.
///
/// Adlar `calendar_months`, `calendar_months_short` ve `calendar_weekdays`
/// anahtarlarında virgülle ayrılmış tek satır olarak tutulur. Bu uzantı,
/// ayrıştırma ve sınır kontrolünü tek yerde toplar — daha önce her ekran
/// kendi `split(',')` + fallback mantığını tekrarlıyordu.
///
/// Fransızca, İspanyolca ve Portekizcede ay adı cümle içinde küçük harfle
/// yazılıyor ("25 octobre", "25 de octubre"); JSON'da da öyle duruyor. Ay
/// adı bir etiketin ilk kelimesiyse ("Octobre 2026") [capitalized] ya da
/// [monthYear] ilk harfi büyütüyor.
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

  /// Etkin dile göre ilk harfi büyük: ay adıyla başlayan etiketler için.
  String capitalized(String text) =>
      capitalizeFirst(AppLocalizations.of(this)?.locale.languageCode, text);

  /// Tek başına duran ay başlığı: "Ekim 2026", "Octobre 2026".
  String monthYear(DateTime date) => capitalized(
    tr(
      'calendar_month_year',
      params: {'month': monthName(date.month), 'year': '${date.year}'},
    ),
  );

  /// Gün ve ay: "25 Ekim", "25. Oktober", "25 de octubre".
  ///
  /// Sıra ve bağlaç dile göre `calendar_day_month` şablonunda: elle
  /// `'$gün $ay'` yazınca İspanyolca ve Portekizcede "de", Almancada gün
  /// sonundaki nokta düşüyordu.
  String dayMonth(DateTime date) => tr(
    'calendar_day_month',
    params: {'day': '${date.day}', 'month': monthName(date.month)},
  );

  /// Gün, ay ve yıl: "25 Ekim 2026", "25 de octubre de 2026".
  String dayMonthYear(DateTime date) => tr(
    'calendar_day_month_year',
    params: {
      'day': '${date.day}',
      'month': monthName(date.month),
      'year': '${date.year}',
    },
  );

  /// İki gün arası: aynı ayda "20–23 Ekim", ay değişiyorsa kısa adlarla
  /// "30 Eyl – 2 Eki". Aynı günse tek tarih.
  String dayRange(DateTime a, DateTime b) {
    if (a.year == b.year && a.month == b.month) {
      if (a.day == b.day) return dayMonth(a);
      return tr(
        'calendar_day_range',
        params: {
          'from': '${a.day}',
          'to': '${b.day}',
          'month': monthName(a.month),
        },
      );
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

/// [languageCode] diline göre ilk harfi büyük, gerisine dokunmadan.
///
/// "octobre 2026" → "Octobre 2026"; zaten büyükse ("Ekim 2026") aynı kalır.
/// Büyütme [upperFor] üzerinden: Türkçede "i" → "İ".
String capitalizeFirst(String? languageCode, String text) {
  if (text.isEmpty) return text;
  final first = text.characters.first;
  return upperFor(languageCode, first) + text.substring(first.length);
}
