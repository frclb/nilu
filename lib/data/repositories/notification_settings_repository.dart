import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/notification_settings.dart';

/// Bildirim tercihlerini yerel depolamada tutan repository.
///
/// Bu ekranlar eskiden yalnızca `setState` ile çalışıyordu: kullanıcı
/// ayarları değiştirip "Kaydet"e bastığında başarı mesajı görüyor ama hiçbir
/// şey kalıcı olmuyordu.
class NotificationSettingsRepository {
  // ─── Genel ───
  static const String _periodRemindersKey = 'notif_period_reminders';
  static const String _fertileWindowKey = 'notif_fertile_window';
  static const String _dailyLogsKey = 'notif_daily_logs';
  static const String _careRemindersKey = 'notif_care_reminders';
  static const String _discreetKey = 'notif_discreet';
  static const String _leadDaysKey = 'notif_period_lead_days';
  static const String _reminderMinuteKey = 'notif_reminder_minute';
  static const String _dailyLogMinuteKey = 'notif_daily_log_minute';
  static const String _lateReminderKey = 'notif_late_reminder';

  Future<GeneralNotificationSettings> getGeneralSettings() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = GeneralNotificationSettings();

    return GeneralNotificationSettings(
      periodReminders:
          prefs.getBool(_periodRemindersKey) ?? defaults.periodReminders,
      fertileWindow: prefs.getBool(_fertileWindowKey) ?? defaults.fertileWindow,
      dailyLogs: prefs.getBool(_dailyLogsKey) ?? defaults.dailyLogs,
      careReminders: prefs.getBool(_careRemindersKey) ?? defaults.careReminders,
      discreet: prefs.getBool(_discreetKey) ?? defaults.discreet,
      periodLeadDays: GeneralNotificationSettings.clampLeadDays(
        prefs.getInt(_leadDaysKey) ?? defaults.periodLeadDays,
      ),
      reminderMinuteOfDay: GeneralNotificationSettings.clampMinuteOfDay(
        prefs.getInt(_reminderMinuteKey) ?? defaults.reminderMinuteOfDay,
      ),
      dailyLogMinuteOfDay: GeneralNotificationSettings.clampMinuteOfDay(
        prefs.getInt(_dailyLogMinuteKey) ?? defaults.dailyLogMinuteOfDay,
      ),
      lateReminder: prefs.getBool(_lateReminderKey) ?? defaults.lateReminder,
    );
  }

  Future<void> saveGeneralSettings(GeneralNotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_periodRemindersKey, settings.periodReminders);
    await prefs.setBool(_fertileWindowKey, settings.fertileWindow);
    await prefs.setBool(_dailyLogsKey, settings.dailyLogs);
    await prefs.setBool(_careRemindersKey, settings.careReminders);
    await prefs.setBool(_discreetKey, settings.discreet);
    await prefs.setInt(_leadDaysKey, settings.periodLeadDays);
    await prefs.setInt(_reminderMinuteKey, settings.reminderMinuteOfDay);
    await prefs.setInt(_dailyLogMinuteKey, settings.dailyLogMinuteOfDay);
    await prefs.setBool(_lateReminderKey, settings.lateReminder);
  }
}
