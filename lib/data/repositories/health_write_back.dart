import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/calendar_day.dart';
import '../../domain/models/daily_log.dart';
import '../../domain/models/period_log.dart';
import '../../domain/services/health_export.dart';
import '../datasources/health_datasource.dart';

/// Regl günlerini Apple Sağlık'a / Health Connect'e yazma; isteğe bağlı,
/// varsayılan kapalı.
///
/// Açıkken her regl değişikliğinden sonra son [windowYears] yıl ayna olarak
/// yeniden yazılıyor (bkz. `HealthDatasource.mirrorPeriods`). Veri cihazın
/// Sağlık deposuna gidiyor; uygulamanın kendi sunucusu yok.
class HealthWriteBack {
  HealthWriteBack({HealthDatasource? datasource})
    : _ds = datasource ?? HealthDatasource();

  static const String _key = 'health_write_back';

  /// Aynanın kapsadığı geçmiş. Daha eskisi Sağlık'ta olduğu gibi kalıyor.
  static const int windowYears = 3;

  final HealthDatasource _ds;

  /// Yazımlar sırayla: art arda iki değişiklikte ikinci ayna, birincinin
  /// silip yeniden yazmasını yarıda kesmesin.
  Future<void> _sira = Future.value();

  Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (e) {
      debugPrint('Health write-back setting unreadable: $e');
      return false;
    }
  }

  Future<void> setEnabled(bool on) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, on);
  }

  /// Ayar açıksa yazar; kapalıysa hiçbir şey yapmadan `null` döner.
  ///
  /// Yazılacak günler çağrı anında hesaplanıyor: dönem kayıtları değişebilir
  /// nesneler ve yazım beklerken ekran onları güncelleyebilir.
  Future<bool?> syncIfEnabled({
    required List<PeriodLog> periods,
    required List<DailyLog> dailyLogs,
    DateTime? now,
  }) => _sirala(_plan(periods, dailyLogs, now), sadeceAciksa: true);

  /// Ayar açılırken: ayara bakmadan hemen yazar.
  Future<bool> syncNow({
    required List<PeriodLog> periods,
    required List<DailyLog> dailyLogs,
    DateTime? now,
  }) async =>
      await _sirala(_plan(periods, dailyLogs, now), sadeceAciksa: false) ??
      false;

  ({List<HealthPeriodDay> days, DateTime from, DateTime to}) _plan(
    List<PeriodLog> periods,
    List<DailyLog> dailyLogs,
    DateTime? now,
  ) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final from = DateTime(today.year - windowYears, today.month, today.day);
    final days = HealthExport.periodDays(
      periods: periods,
      dailyLogs: dailyLogs,
      today: today,
    ).where((d) => !d.date.isBefore(from)).toList();
    return (days: days, from: from, to: today.plusDays(1));
  }

  Future<bool?> _sirala(
    ({List<HealthPeriodDay> days, DateTime from, DateTime to}) plan, {
    required bool sadeceAciksa,
  }) {
    final sonuc = _sira.then((_) async {
      if (sadeceAciksa && !await isEnabled()) return null;
      return _ds.mirrorPeriods(plan.days, from: plan.from, to: plan.to);
    });
    _sira = sonuc.then((_) {}, onError: (_) {});
    return sonuc;
  }
}
