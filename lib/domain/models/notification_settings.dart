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
  /// Her açılır listenin kabul ettiği değerler.
  ///
  /// Ekrandaki `DropdownMenuItem` listeleriyle **birebir** aynı olmalı:
  /// `DropdownButton`, değeri öğeler arasında bulamazsa çizim sırasında
  /// assert atıp ekranı kırmızı hata sayfasına çeviriyor.
  ///
  /// Regresyon: `ovulationValue` varsayılanı `'same_day'`'di ama listede
  /// `'0'/'1'/'2'` vardı. Hiç kayıt yapmamış her kullanıcıda Partner →
  /// Bildirim Ayarları ekranı ilk açılışta çöküyordu.
  static const Set<String> periodStartValues = {'1', '2', '3', '7'};
  static const Set<String> ovulationValues = {'0', '1', '2'};
  static const Set<String> symptomsValues = {'1', '2', '3'};
  static const Set<String> dailySupportValues = {'0900', '1200', '1900'};

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
    this.ovulationValue = '0',
    this.symptomsValue = '1',
    this.dailySupportValue = '0900',
  });
}
