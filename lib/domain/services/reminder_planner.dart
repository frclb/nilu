import '../models/cycle_info.dart';
import '../models/notification_settings.dart';

/// Planlanabilecek hatırlatıcı türleri.
enum ReminderType { periodApproaching, fertileWindow, dailyLog }

/// Belirli bir anda gösterilecek hatırlatıcı.
class ScheduledReminder {
  /// Platform tarafında bildirimi tekilleştiren kimlik.
  /// Aynı kimlik yeniden planlandığında eskisinin üzerine yazılır.
  final int id;
  final ReminderType type;
  final DateTime when;
  final String titleKey;
  final String bodyKey;

  const ScheduledReminder({
    required this.id,
    required this.type,
    required this.when,
    required this.titleKey,
    required this.bodyKey,
  });

  @override
  String toString() => '$type @ $when (#$id)';
}

/// Döngü tahminlerinden hatırlatıcı planı üretir.
///
/// Saf fonksiyondur: platform eklentisine dokunmaz, bu yüzden tüm kuralları
/// (ayar kapalıysa planlama, geçmişe planlama, kaç gün önce vb.) doğrudan
/// test edilebilir. Planı cihaza yazma işi [ReminderScheduler]'a aittir.
class ReminderPlanner {
  const ReminderPlanner._();

  /// Regl hatırlatıcısı kaç gün önce gönderilsin.
  static const int periodLeadDays = 2;

  /// Sabah hatırlatıcılarının saati.
  static const int morningHour = 9;

  /// Günlük kayıt hatırlatıcısının saati.
  static const int dailyLogHour = 20;

  /// En fazla kaç döngü ileriye planlanır.
  ///
  /// iOS aynı anda 64 bekleyen bildirimle sınırlıdır; sınırsız planlama
  /// eski hatırlatıcıların sessizce düşmesine yol açar.
  static const int maxCycles = 3;

  // Kimlik aralıkları — türler çakışmasın diye ayrıldı.
  static const int _periodIdBase = 1000;
  static const int _fertileIdBase = 2000;
  static const int _dailyLogId = 3000;

  /// [now] anından sonraki hatırlatıcıları döndürür (zamana göre sıralı).
  static List<ScheduledReminder> plan({
    required CycleInfo cycleInfo,
    required GeneralNotificationSettings settings,
    required DateTime now,
  }) {
    final reminders = <ScheduledReminder>[];

    if (settings.periodReminders) {
      final starts = _periodStarts(cycleInfo);
      for (var i = 0; i < starts.length; i++) {
        final when = _at(
          starts[i].subtract(const Duration(days: periodLeadDays)),
          morningHour,
        );
        if (when.isAfter(now)) {
          reminders.add(
            ScheduledReminder(
              id: _periodIdBase + i,
              type: ReminderType.periodApproaching,
              when: when,
              titleKey: 'notif_period_reminders',
              bodyKey: 'notif_period_body',
            ),
          );
        }
      }
    }

    if (settings.fertileWindow) {
      final windows = _fertileStarts(cycleInfo);
      for (var i = 0; i < windows.length; i++) {
        final when = _at(windows[i], morningHour);
        if (when.isAfter(now)) {
          reminders.add(
            ScheduledReminder(
              id: _fertileIdBase + i,
              type: ReminderType.fertileWindow,
              when: when,
              titleKey: 'notif_fertile_window',
              bodyKey: 'notif_fertile_body',
            ),
          );
        }
      }
    }

    if (settings.dailyLogs) {
      reminders.add(
        ScheduledReminder(
          id: _dailyLogId,
          type: ReminderType.dailyLog,
          when: _nextDailyLogTime(now),
          titleKey: 'notif_daily_logs',
          bodyKey: 'notif_daily_log_body',
        ),
      );
    }

    reminders.sort((a, b) => a.when.compareTo(b.when));
    return reminders;
  }

  /// Tahmin edilen regl başlangıçları (en fazla [maxCycles] adet).
  static List<DateTime> _periodStarts(CycleInfo info) {
    final next = info.predictedNextPeriod;
    if (next == null) return const [];

    return [
      next,
      ...info.futurePredictions.map((p) => p.startDate),
    ].take(maxCycles).toList();
  }

  /// Tahmin edilen doğurganlık penceresi başlangıçları.
  static List<DateTime> _fertileStarts(CycleInfo info) {
    final current = info.fertileWindowStart;
    return [
      ?current,
      ...info.futurePredictions
          .map((p) => p.fertileStart)
          .whereType<DateTime>(),
    ].take(maxCycles).toList();
  }

  /// Günün belirli saatine sabitler.
  static DateTime _at(DateTime day, int hour) =>
      DateTime(day.year, day.month, day.day, hour);

  /// Bugünün saati geçtiyse yarına planlar.
  static DateTime _nextDailyLogTime(DateTime now) {
    final todayAt = _at(now, dailyLogHour);
    return todayAt.isAfter(now)
        ? todayAt
        : todayAt.add(const Duration(days: 1));
  }
}
