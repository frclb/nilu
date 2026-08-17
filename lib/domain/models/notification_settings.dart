/// Kullanıcının kendi bildirim tercihleri (Profil → Genel Bildirimler).
class GeneralNotificationSettings {
  final bool periodReminders;
  final bool fertileWindow;
  final bool dailyLogs;
  final bool partnerUpdates;

  const GeneralNotificationSettings({
    this.periodReminders = true,
    this.fertileWindow = true,
    this.dailyLogs = false,
    this.partnerUpdates = true,
  });

  GeneralNotificationSettings copyWith({
    bool? periodReminders,
    bool? fertileWindow,
    bool? dailyLogs,
    bool? partnerUpdates,
  }) {
    return GeneralNotificationSettings(
      periodReminders: periodReminders ?? this.periodReminders,
      fertileWindow: fertileWindow ?? this.fertileWindow,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      partnerUpdates: partnerUpdates ?? this.partnerUpdates,
    );
  }
}

/// Partner tarafının bildirim tercihleri (Partner → Bildirim Ayarları).
///
/// `*Value` alanları ekrandaki açılır listelerin seçili değerleridir
/// (ör. kaç gün önce hatırlatılacağı).
class PartnerNotificationSettings {
  final bool periodStartEnabled;
  final bool ovulationEnabled;
  final bool symptomsEnabled;
  final bool dailySupportEnabled;

  final String periodStartValue;
  final String ovulationValue;
  final String symptomsValue;
  final String dailySupportValue;

  const PartnerNotificationSettings({
    this.periodStartEnabled = true,
    this.ovulationEnabled = false,
    this.symptomsEnabled = true,
    this.dailySupportEnabled = true,
    this.periodStartValue = '1',
    this.ovulationValue = 'same_day',
    this.symptomsValue = '1',
    this.dailySupportValue = '0900',
  });
}
