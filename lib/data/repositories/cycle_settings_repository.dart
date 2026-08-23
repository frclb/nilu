import '../local/secure_store.dart';

/// Kullanıcının döngü ayarlarını (döngü süresi, kanama süresi) **şifreli**
/// yerel depolamada tutan repository — bunlar da sağlık verisidir.
///
/// `settingsUpdatedAt` alanı, ayar değişikliklerinin yalnızca ileriye dönük
/// uygulanmasını sağlar.
class CycleSettingsRepository {
  static const String _cycleLengthKey = 'user_cycle_length';
  static const String _periodLengthKey = 'user_period_length';
  static const String _settingsUpdatedAtKey = 'settings_updated_at';
  static const String _hormonalContraceptionKey = 'hormonal_contraception';

  static const int defaultCycleLength = 28;
  static const int defaultPeriodLength = 5;

  final SecureStore _store;

  const CycleSettingsRepository({SecureStore store = const SecureStore()})
    : _store = store;

  /// Döngü ve kanama süresi ayarlarını kaydeder.
  /// `settingsUpdatedAt` otomatik olarak şu anki tarih olarak ayarlanır.
  Future<void> saveCycleSettings({
    required int cycleLength,
    required int periodLength,
  }) async {
    await _store.setInt(_cycleLengthKey, cycleLength);
    await _store.setInt(_periodLengthKey, periodLength);
    await _store.setString(
      _settingsUpdatedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// İlk kurulumda (onboarding) ayarları kaydeder.
  /// `settingsUpdatedAt` alanı çok eski bir tarihe ayarlanır,
  /// böylece tüm gelecek tahminler bu ayarlarla hesaplanır.
  Future<void> saveInitialSettings({
    required int cycleLength,
    required int periodLength,
  }) async {
    await _store.setInt(_cycleLengthKey, cycleLength);
    await _store.setInt(_periodLengthKey, periodLength);
    // Onboarding'de tüm tahminler bu değerlerle olmalı,
    // bu yüzden çok eski bir tarih set ediyoruz.
    await _store.setString(
      _settingsUpdatedAtKey,
      DateTime(2000, 1, 1).toIso8601String(),
    );
  }

  /// Kayıtlı döngü uzunluğunu döndürür (varsayılan: 28).
  Future<int> getCycleLength() async {
    return await _store.getInt(_cycleLengthKey) ?? defaultCycleLength;
  }

  /// Kayıtlı kanama süresini döndürür (varsayılan: 5).
  Future<int> getPeriodLength() async {
    return await _store.getInt(_periodLengthKey) ?? defaultPeriodLength;
  }

  /// Hormonal doğum kontrolü kullanılıyor mu?
  ///
  /// Açıkken yumurtlama ve doğurganlık penceresi tahmini üretilmez.
  Future<bool> getHormonalContraception() async {
    return await _store.getBool(_hormonalContraceptionKey) ?? false;
  }

  Future<void> setHormonalContraception(bool value) async {
    await _store.setBool(_hormonalContraceptionKey, value);
    await _store.setString(
      _settingsUpdatedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// Ayarların en son değiştirildiği tarihi döndürür.
  Future<DateTime?> getSettingsUpdatedAt() async {
    final dateStr = await _store.getString(_settingsUpdatedAtKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }
}
