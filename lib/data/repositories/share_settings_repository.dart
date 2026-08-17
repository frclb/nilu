import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/share_settings.dart';

/// Partner paylaşım tercihlerini saklayan repository.
///
/// Bu ekrandaki anahtarlar eskiden yalnızca `setState` ile çalışıyordu:
/// kullanıcı "Semptom Detayları"nı kapatıyor, ekrandan çıkınca ayar geri
/// geliyordu ve veri paylaşılmaya devam ediyordu.
class ShareSettingsRepository {
  static const String phaseInfoKey = 'share_phase_info';
  static const String symptomDetailsKey = 'share_symptom_details';
  static const String moodKey = 'share_mood';
  static const String predictionsKey = 'share_predictions';

  const ShareSettingsRepository();

  Future<ShareSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = ShareSettings();

    return ShareSettings(
      phaseInfo: prefs.getBool(phaseInfoKey) ?? defaults.phaseInfo,
      symptomDetails:
          prefs.getBool(symptomDetailsKey) ?? defaults.symptomDetails,
      mood: prefs.getBool(moodKey) ?? defaults.mood,
      predictions: prefs.getBool(predictionsKey) ?? defaults.predictions,
    );
  }

  Future<void> save(ShareSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(phaseInfoKey, settings.phaseInfo);
    await prefs.setBool(symptomDetailsKey, settings.symptomDetails);
    await prefs.setBool(moodKey, settings.mood);
    await prefs.setBool(predictionsKey, settings.predictions);
  }
}
