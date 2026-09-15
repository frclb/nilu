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
  static const String _partnerUpdatesKey = 'notif_partner_updates';

  // ─── Partner ───
  static const String _pPeriodStartKey = 'notif_partner_period_start';
  static const String _pOvulationKey = 'notif_partner_ovulation';
  static const String _pSymptomsKey = 'notif_partner_symptoms';
  static const String _pDailySupportKey = 'notif_partner_daily_support';
  static const String _pPeriodStartValueKey =
      'notif_partner_period_start_value';
  static const String _pOvulationValueKey = 'notif_partner_ovulation_value';
  static const String _pSymptomsValueKey = 'notif_partner_symptoms_value';
  static const String _pDailySupportValueKey =
      'notif_partner_daily_support_value';

  Future<GeneralNotificationSettings> getGeneralSettings() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = GeneralNotificationSettings();

    return GeneralNotificationSettings(
      periodReminders:
          prefs.getBool(_periodRemindersKey) ?? defaults.periodReminders,
      fertileWindow: prefs.getBool(_fertileWindowKey) ?? defaults.fertileWindow,
      dailyLogs: prefs.getBool(_dailyLogsKey) ?? defaults.dailyLogs,
      partnerUpdates:
          prefs.getBool(_partnerUpdatesKey) ?? defaults.partnerUpdates,
    );
  }

  Future<void> saveGeneralSettings(GeneralNotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_periodRemindersKey, settings.periodReminders);
    await prefs.setBool(_fertileWindowKey, settings.fertileWindow);
    await prefs.setBool(_dailyLogsKey, settings.dailyLogs);
    await prefs.setBool(_partnerUpdatesKey, settings.partnerUpdates);
  }

  Future<PartnerNotificationSettings> getPartnerSettings() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = PartnerNotificationSettings();

    return PartnerNotificationSettings(
      periodStartEnabled:
          prefs.getBool(_pPeriodStartKey) ?? defaults.periodStartEnabled,
      ovulationEnabled:
          prefs.getBool(_pOvulationKey) ?? defaults.ovulationEnabled,
      symptomsEnabled: prefs.getBool(_pSymptomsKey) ?? defaults.symptomsEnabled,
      dailySupportEnabled:
          prefs.getBool(_pDailySupportKey) ?? defaults.dailySupportEnabled,
      // Tanınmayan bir değer depoda kalmışsa varsayılana düşülür. Doğrudan
      // geçirilseydi `DropdownButton` onu listede bulamayıp assert atacak ve
      // ekran açılmayacaktı — eski sürümün yazdığı bir değer, kullanıcının
      // açamadığı bir ekrana dönüşürdü.
      periodStartValue: _oneOf(
        prefs.getString(_pPeriodStartValueKey),
        PartnerNotificationSettings.periodStartValues,
        defaults.periodStartValue,
      ),
      ovulationValue: _oneOf(
        prefs.getString(_pOvulationValueKey),
        PartnerNotificationSettings.ovulationValues,
        defaults.ovulationValue,
      ),
      symptomsValue: _oneOf(
        prefs.getString(_pSymptomsValueKey),
        PartnerNotificationSettings.symptomsValues,
        defaults.symptomsValue,
      ),
      dailySupportValue: _oneOf(
        prefs.getString(_pDailySupportValueKey),
        PartnerNotificationSettings.dailySupportValues,
        defaults.dailySupportValue,
      ),
    );
  }

  static String _oneOf(String? stored, Set<String> allowed, String fallback) =>
      allowed.contains(stored) ? stored! : fallback;

  Future<void> savePartnerSettings(PartnerNotificationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pPeriodStartKey, settings.periodStartEnabled);
    await prefs.setBool(_pOvulationKey, settings.ovulationEnabled);
    await prefs.setBool(_pSymptomsKey, settings.symptomsEnabled);
    await prefs.setBool(_pDailySupportKey, settings.dailySupportEnabled);
    await prefs.setString(_pPeriodStartValueKey, settings.periodStartValue);
    await prefs.setString(_pOvulationValueKey, settings.ovulationValue);
    await prefs.setString(_pSymptomsValueKey, settings.symptomsValue);
    await prefs.setString(_pDailySupportValueKey, settings.dailySupportValue);
  }
}
