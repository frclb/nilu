import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/share_settings.dart';

/// Partner paylaşım tercihini saklayan repository.
///
/// Bu ekrandaki anahtarlar eskiden yalnızca `setState` ile çalışıyordu:
/// kullanıcı kapatıyor, ekrandan çıkınca ayar geri geliyordu.
class ShareSettingsRepository {
  static const String intimacyKey = 'share_intimacy_status';

  /// Eski dört anahtar. Yalnızca göç için okunuyor.
  static const String legacyPhaseInfoKey = 'share_phase_info';
  static const String legacySymptomDetailsKey = 'share_symptom_details';
  static const String legacyMoodKey = 'share_mood';
  static const String legacyPredictionsKey = 'share_predictions';

  const ShareSettingsRepository();

  Future<ShareSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    const defaults = ShareSettings();

    final stored = prefs.getBool(intimacyKey);
    if (stored != null) return ShareSettings(intimacyStatus: stored);

    // Göç: eski dört anahtarın **hiçbiri** tek başına bir şey kontrol
    // etmiyordu; paylaşımı durduran şey dördünün birden kapalı olmasıydı.
    // O yüzden yeni tek anahtar da o toplamı devralıyor — dördünü kapatmış
    // bir kullanıcının paylaşımı sessizce geri açılmamalı.
    final legacy = [
      legacyPhaseInfoKey,
      legacySymptomDetailsKey,
      legacyMoodKey,
      legacyPredictionsKey,
    ].map(prefs.getBool).toList();

    if (legacy.every((value) => value == null)) return defaults;
    return ShareSettings(intimacyStatus: legacy.any((value) => value == true));
  }

  Future<void> save(ShareSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(intimacyKey, settings.intimacyStatus);
  }
}
