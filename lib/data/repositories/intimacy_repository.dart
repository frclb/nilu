import '../local/secure_store.dart';

/// Kullanıcının yakınlık/duygusal durum seçimlerini ve paylaşım ayarlarını
/// **şifreli** yerel depolamada tutan repository.
///
/// Cinsel istek ve sevgi ihtiyacı seçimleri son derece hassas kişisel veridir;
/// düz metin olarak saklanmaz (bkz. [SecureStore]).
class IntimacyRepository {
  static const String _sexualDesireKey = 'intimacy_sexual_desire';
  static const String _affectionNeedsKey = 'intimacy_affection_needs';
  static const String _autoShareKey = 'intimacy_auto_share';
  static const String _lastSharedAtKey = 'intimacy_last_shared_at';
  static const String _dailyShareCountKey = 'intimacy_daily_share_count';
  static const String _dailyShareDateKey = 'intimacy_daily_share_date';
  static const String _offlineQueueKey = 'intimacy_offline_queue';

  final SecureStore _store;

  const IntimacyRepository({SecureStore store = const SecureStore()})
    : _store = store;

  // ─── Seçim Kayıt / Yükleme ───

  /// Son seçilen cinsel istek değerini kaydeder.
  Future<void> saveSexualDesire(String value) =>
      _store.setString(_sexualDesireKey, value);

  /// Son seçilen cinsel istek değerini döndürür.
  Future<String?> getSexualDesire() => _store.getString(_sexualDesireKey);

  /// Seçilen sevgi ihtiyaçlarını kaydeder.
  Future<void> saveAffectionNeeds(List<String> needs) =>
      _store.setStringList(_affectionNeedsKey, needs);

  /// Seçilen sevgi ihtiyaçlarını döndürür.
  Future<List<String>> getAffectionNeeds() async =>
      await _store.getStringList(_affectionNeedsKey) ?? [];

  // ─── Paylaşım Ayarları ───

  /// Otomatik paylaşım ayarını kaydeder.
  Future<void> saveAutoShareEnabled(bool enabled) =>
      _store.setBool(_autoShareKey, enabled);

  /// Otomatik paylaşım ayarını döndürür.
  Future<bool> getAutoShareEnabled() async =>
      await _store.getBool(_autoShareKey) ?? false;

  /// Son paylaşım zamanını kaydeder.
  Future<void> saveLastSharedAt(DateTime dateTime) =>
      _store.setString(_lastSharedAtKey, dateTime.toIso8601String());

  /// Son paylaşım zamanını döndürür.
  Future<DateTime?> getLastSharedAt() async {
    final dateStr = await _store.getString(_lastSharedAtKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  // ─── Rate Limiting ───

  /// Günlük paylaşım sayacını günceller.
  Future<void> incrementDailyShareCount() async {
    final today = _todayKey();
    final savedDate = await _store.getString(_dailyShareDateKey);

    if (savedDate != today) {
      // Yeni gün, sayaç sıfırla
      await _store.setString(_dailyShareDateKey, today);
      await _store.setInt(_dailyShareCountKey, 1);
    } else {
      final count = await _store.getInt(_dailyShareCountKey) ?? 0;
      await _store.setInt(_dailyShareCountKey, count + 1);
    }
  }

  /// Günlük paylaşım sayısını döndürür.
  Future<int> getDailyShareCount() async {
    final savedDate = await _store.getString(_dailyShareDateKey);
    if (savedDate != _todayKey()) return 0;
    return await _store.getInt(_dailyShareCountKey) ?? 0;
  }

  static String _todayKey() =>
      DateTime.now().toIso8601String().substring(0, 10);

  // ─── Offline Queue ───

  /// Çevrimdışı kuyruğa veri ekler.
  Future<void> saveOfflineQueue(String jsonData) =>
      _store.setString(_offlineQueueKey, jsonData);

  /// Çevrimdışı kuyruk verisini döndürür.
  Future<String?> getOfflineQueue() => _store.getString(_offlineQueueKey);

  /// Çevrimdışı kuyruğu temizler.
  Future<void> clearOfflineQueue() => _store.remove(_offlineQueueKey);
}
