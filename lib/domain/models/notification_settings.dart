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

  const GeneralNotificationSettings({
    this.periodReminders = true,
    this.fertileWindow = true,
    this.dailyLogs = false,
    this.careReminders = true,
    this.discreet = false,
  });

  GeneralNotificationSettings copyWith({
    bool? periodReminders,
    bool? fertileWindow,
    bool? dailyLogs,
    bool? careReminders,
    bool? discreet,
  }) {
    return GeneralNotificationSettings(
      periodReminders: periodReminders ?? this.periodReminders,
      fertileWindow: fertileWindow ?? this.fertileWindow,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      careReminders: careReminders ?? this.careReminders,
      discreet: discreet ?? this.discreet,
    );
  }
}
