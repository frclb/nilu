/// Kullanıcının kendi bildirim tercihleri (Profil → Genel Bildirimler).
class GeneralNotificationSettings {
  final bool periodReminders;
  final bool fertileWindow;
  final bool dailyLogs;

  /// Gebelik ve lohusalık takibi hatırlatıcıları (izlem, tarama, destek).
  final bool careReminders;

  /// Kilit ekranında içerik gösterme.
  ///
  /// Açıkken bütün bildirimler aynı genel metinle çıkıyor: "Nilu — bugün
  /// için bir hatırlatman var". Önceden kilit ekranında "Reglin yaklaşıyor"
  /// ve "Doğurganlık pencerene giriyorsun" yazıyordu; gebelik ve lohusalıkla
  /// bu çok daha hassas ("18–22. hafta: anomali taraması"). Paylaşılan
  /// telefonların yaygın olduğu bir pazarda gerçek bir ihtiyaç.
  final bool discreet;

  /// Regl hatırlatıcısı beklenen günden kaç gün önce gelsin
  /// ([minPeriodLeadDays]–[maxPeriodLeadDays]).
  ///
  /// Önceden sabit iki gündü. Ped/tampon almak için bir gün yeten de var,
  /// seyahat planı için beş gün isteyen de.
  final int periodLeadDays;

  /// Gün içindeki hatırlatıcıların saati, gece yarısından itibaren dakika.
  ///
  /// Regl, doğurganlık, gecikme ve bakım hatırlatıcıları bu saatte geliyor.
  /// Önceden sabah dokuzdu; gece vardiyasında çalışan biri için uykunun
  /// ortası.
  final int reminderMinuteOfDay;

  /// Günlük kayıt hatırlatıcısının saati (dakika).
  final int dailyLogMinuteOfDay;

  /// Beklenen gün geçince bir kez, nazikçe sorulsun mu?
  final bool lateReminder;

  static const int minPeriodLeadDays = 1;
  static const int maxPeriodLeadDays = 5;
  static const int defaultPeriodLeadDays = 2;
  static const int defaultReminderMinuteOfDay = 9 * 60;
  static const int defaultDailyLogMinuteOfDay = 20 * 60;

  const GeneralNotificationSettings({
    this.periodReminders = true,
    this.fertileWindow = true,
    this.dailyLogs = false,
    this.careReminders = true,
    this.discreet = false,
    this.periodLeadDays = defaultPeriodLeadDays,
    this.reminderMinuteOfDay = defaultReminderMinuteOfDay,
    this.dailyLogMinuteOfDay = defaultDailyLogMinuteOfDay,
    this.lateReminder = true,
  });

  GeneralNotificationSettings copyWith({
    bool? periodReminders,
    bool? fertileWindow,
    bool? dailyLogs,
    bool? careReminders,
    bool? discreet,
    int? periodLeadDays,
    int? reminderMinuteOfDay,
    int? dailyLogMinuteOfDay,
    bool? lateReminder,
  }) {
    return GeneralNotificationSettings(
      periodReminders: periodReminders ?? this.periodReminders,
      fertileWindow: fertileWindow ?? this.fertileWindow,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      careReminders: careReminders ?? this.careReminders,
      discreet: discreet ?? this.discreet,
      periodLeadDays: periodLeadDays ?? this.periodLeadDays,
      reminderMinuteOfDay: reminderMinuteOfDay ?? this.reminderMinuteOfDay,
      dailyLogMinuteOfDay: dailyLogMinuteOfDay ?? this.dailyLogMinuteOfDay,
      lateReminder: lateReminder ?? this.lateReminder,
    );
  }

  /// Kayıttan okunan değeri geçerli aralığa çeker. Bozuk ya da eski bir
  /// değer hatırlatıcıyı geçmişe ya da ertesi güne kaydırmasın.
  static int clampLeadDays(int value) =>
      value.clamp(minPeriodLeadDays, maxPeriodLeadDays);

  static int clampMinuteOfDay(int value) => value.clamp(0, 24 * 60 - 1);
}
