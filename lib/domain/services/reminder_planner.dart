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

  /// Planı etkileyen girdilerin özeti.
  ///
  /// Hatırlatıcılar tahminlere bağlı; kullanıcı takvimde bir gün işaretlediğinde
  /// tahminler kayar ve planın yenilenmesi gerekir. Her yeniden hesapta bekleyen
  /// tüm bildirimleri iptal edip yeniden yazmak pahalı ve gereksiz — bu imza
  /// değişmediyse plan da değişmez.
  static String signature({
    required CycleInfo cycleInfo,
    required GeneralNotificationSettings settings,
    required DateTime now,
  }) {
    String d(DateTime? value) =>
        value == null ? '-' : '${value.year}-${value.month}-${value.day}';

    return [
      // Gecikme imzaya giriyor.
      //
      // İmza yalnızca tahmin edilen tarihleri içeriyordu ve o tarihler
      // günler geçtikçe değişmiyor. Kullanıcı gecikmeye düştüğünde imza
      // aynı kaldığı için plan yenilenmiyor, daha önce yazılmış yanlış
      // bildirimler öylece duruyordu.
      //
      // Gün sayısı değil yalnızca "gecikmiş mi": her gün değişen bir değer
      // koysaydık plan her açılışta baştan yazılırdı.
      cycleInfo.daysLateAt(now) > 0,
      settings.periodReminders,
      settings.fertileWindow,
      settings.dailyLogs,
      d(cycleInfo.predictedNextPeriod),
      d(cycleInfo.fertileWindowStart),
      ...cycleInfo.futurePredictions.map((p) => d(p.startDate)),
      ...cycleInfo.futurePredictions.map((p) => d(p.fertileStart)),
    ].join('|');
  }

  /// [now] anından sonraki hatırlatıcıları döndürür (zamana göre sıralı).
  static List<ScheduledReminder> plan({
    required CycleInfo cycleInfo,
    required GeneralNotificationSettings settings,
    required DateTime now,
  }) {
    final reminders = <ScheduledReminder>[];

    // Beklenen gün geçtiyse tahmin zinciri güvenilirliğini yitiriyor:
    // tamamı kaçırılmış bir başlangıca dayanıyor. Ekranda bunu boş bir
    // liste olarak göstermek yetiyordu; burada bedeli daha ağır, çünkü
    // kullanıcı gelmemiş bir döngünün penceresi için "Doğurganlık
    // pencerene giriyorsun" bildirimi alıyordu.
    //
    // Günlük kayıt hatırlatıcısı tahmine dayanmıyor, o susturulmuyor.
    final overdue = cycleInfo.daysLateAt(now) > 0;

    if (settings.periodReminders && !overdue) {
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

    if (settings.fertileWindow && !overdue) {
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

    // `predictedNextPeriod` ile `futurePredictions[0]` aynı tarih: ikisi de
    // `lastStart + döngüUzunluğu`. Tekilleştirilmediği için plana iki ayrı
    // kimlikle aynı an giriyordu ve kullanıcı sabah dokuzda birbirinin
    // kopyası iki "Reglin yaklaşıyor" bildirimi alıyordu. Üstelik kopya,
    // [maxCycles] penceresinden bir yer yediği için en uzaktaki döngü hiç
    // planlanmıyordu.
    return _distinctDays([
      next,
      ...info.futurePredictions.map((p) => p.startDate),
    ]).take(maxCycles).toList();
  }

  /// Tahmin edilen doğurganlık penceresi başlangıçları.
  static List<DateTime> _fertileStarts(CycleInfo info) {
    final current = info.fertileWindowStart;
    return _distinctDays([
      ?current,
      ...info.futurePredictions
          .map((p) => p.fertileStart)
          .whereType<DateTime>(),
    ]).take(maxCycles).toList();
  }

  /// Aynı güne düşen tarihleri teke indirir, sırayı korur.
  static List<DateTime> _distinctDays(List<DateTime> dates) {
    final seen = <String>{};
    final result = <DateTime>[];
    for (final date in dates) {
      if (seen.add('${date.year}-${date.month}-${date.day}')) {
        result.add(date);
      }
    }
    return result;
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
