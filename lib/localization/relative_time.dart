import 'package:flutter/widgets.dart';
import 'app_localizations.dart';

/// Göreli zaman ("az önce", "3 saat önce") biçimlendirmesi.
///
/// Bu bir **sunum** işidir: ViewModel'lar ham [Duration] yayınlar, metne
/// çevirme burada — aktif dile göre — yapılır.
extension RelativeTimeFormatting on BuildContext {
  String relativeTime(Duration? duration) {
    if (duration == null) return '';

    if (duration.inMinutes < 1) {
      return tr('time_just_now');
    }
    if (duration.inMinutes < 60) {
      return tr('time_minutes_ago', params: {'n': '${duration.inMinutes}'});
    }
    if (duration.inHours < 24) {
      return tr('time_hours_ago', params: {'n': '${duration.inHours}'});
    }
    return tr(
      duration.inDays == 1 ? 'time_days_ago_one' : 'time_days_ago',
      params: {'n': '${duration.inDays}'},
    );
  }
}
