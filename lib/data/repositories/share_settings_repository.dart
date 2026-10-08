import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/share_settings.dart';

/// Partner paylaşım tercihini ve açık rızayı saklayan repository.
///
/// Paylaşım ancak rıza kaydı varken açık sayılıyor. Önceki sürümler
/// paylaşımı varsayılan olarak açık kaydediyordu; rıza alınmadan açık
/// kalmış bir ayar, yükseltmeden sonra kapalı okunuyor.
class ShareSettingsRepository {
  static const String intimacyKey = 'share_intimacy_status';

  /// Açık rızanın verildiği an (ISO-8601). Rıza geri alınınca siliniyor.
  static const String consentKey = 'share_intimacy_consent_at';

  /// Eski dört anahtar. Yalnızca göç için okunuyor.
  static const String legacyPhaseInfoKey = 'share_phase_info';
  static const String legacySymptomDetailsKey = 'share_symptom_details';
  static const String legacyMoodKey = 'share_mood';
  static const String legacyPredictionsKey = 'share_predictions';

  const ShareSettingsRepository();

  Future<ShareSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(consentKey) == null) return ShareSettings.none;
    return ShareSettings(intimacyStatus: prefs.getBool(intimacyKey) ?? false);
  }

  /// Rızanın verildiği an; verilmediyse `null`.
  Future<DateTime?> consentedAt() async {
    final prefs = await SharedPreferences.getInstance();
    return DateTime.tryParse(prefs.getString(consentKey) ?? '');
  }

  /// Açık rızayla paylaşımı açar.
  Future<void> grantConsent({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      consentKey,
      (now ?? DateTime.now()).toIso8601String(),
    );
    await prefs.setBool(intimacyKey, true);
  }

  /// Paylaşımı kapatır ve rızayı geri alır. Sunucudaki paylaşılmış durumu
  /// silmek çağıranın işi (bkz. `IntimacyViewModel.stopSharing`).
  Future<void> withdrawConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(consentKey);
    await prefs.setBool(intimacyKey, false);
    for (final k in [
      legacyPhaseInfoKey,
      legacySymptomDetailsKey,
      legacyMoodKey,
      legacyPredictionsKey,
    ]) {
      await prefs.remove(k);
    }
  }
}
