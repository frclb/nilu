import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../local/secure_store.dart';
import 'period_repository.dart';

/// Gizlilik ekranının tercihleri ve veri yönetimi işlemleri.
class PrivacySettingsRepository {
  static const String _biometricKey = 'privacy_biometric_enabled';
  static const String _pinKey = 'privacy_pin_enabled';

  final SecureStore _store;
  final PeriodRepository _periodRepository;

  const PrivacySettingsRepository({
    SecureStore store = const SecureStore(),
    PeriodRepository periodRepository = const PeriodRepository(),
  }) : _store = store,
       _periodRepository = periodRepository;

  // ─── Tercihler ───
  // Bunlar hassas veri değil, yalnızca aç/kapa tercihi.

  Future<bool> getBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricKey, value);
  }

  Future<bool> getPinEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinKey) ?? false;
  }

  Future<void> setPinEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinKey, value);
  }

  // ─── Veri yönetimi ───

  /// Kullanıcının tüm sağlık verisini okunabilir JSON olarak döndürür.
  /// Ekran bunu panoya kopyalar; harici bir servise gönderilmez.
  Future<String> exportDataAsJson() async {
    final periodLogs = await _periodRepository.getPeriodLogs();
    final dailyLogs = await _periodRepository.getDailyLogs();

    return const JsonEncoder.withIndent('  ').convert({
      'exportedAt': DateTime.now().toIso8601String(),
      'periodLogs': periodLogs.map((l) => l.toMap()).toList(),
      'dailyLogs': dailyLogs.map((l) => l.toMap()).toList(),
    });
  }

  /// Cihazdaki tüm kullanıcı verisini kalıcı olarak siler:
  /// şifreli depodaki sağlık verisi + yerel tercihler.
  ///
  /// Geri alınamaz. Uzak (Firestore) veriyi silmez — o, hesap silme akışının
  /// backend tarafına aittir.
  Future<void> deleteAllLocalData() async {
    await _store.clearSensitiveData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
