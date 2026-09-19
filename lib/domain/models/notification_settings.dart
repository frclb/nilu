/// Kullanıcının kendi bildirim tercihleri (Profil → Genel Bildirimler).
class GeneralNotificationSettings {
  final bool periodReminders;
  final bool fertileWindow;
  final bool dailyLogs;

  const GeneralNotificationSettings({
    this.periodReminders = true,
    this.fertileWindow = true,
    this.dailyLogs = false,
  });

  GeneralNotificationSettings copyWith({
    bool? periodReminders,
    bool? fertileWindow,
    bool? dailyLogs,
  }) {
    return GeneralNotificationSettings(
      periodReminders: periodReminders ?? this.periodReminders,
      fertileWindow: fertileWindow ?? this.fertileWindow,
      dailyLogs: dailyLogs ?? this.dailyLogs,
    );
  }
}

