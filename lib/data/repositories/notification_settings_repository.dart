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


  Future<GeneralNotificationSettings> getGeneralSettings() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = GeneralNotificationSettings();

    return GeneralNotificationSettings(
      periodReminders:
          prefs.getBool(_periodRemindersKey) ?? defaults.periodReminders,
      fertileWindow: prefs.getBool(_fertileWindowKey) ?? defaults.fertileWindow,
      dailyLogs: prefs.getBool(_dailyLogsKey) ?? defaults.dailyLogs,
    );
  }

  Future<void> saveGeneralSettings(GeneralNotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_periodRemindersKey, settings.periodReminders);
    await prefs.setBool(_fertileWindowKey, settings.fertileWindow);
    await prefs.setBool(_dailyLogsKey, settings.dailyLogs);
  }



}
