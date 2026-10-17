import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hassas sağlık verileri için şifreli anahtar-değer deposu.
///
/// Adet döngüsü kayıtları, semptomlar ve yakınlık seçimleri hassas kişisel
/// sağlık verisidir; düz `SharedPreferences` bunları cihazda **şifresiz**
/// tutar. Bu sınıf aynı basit API'yi sunar ama veriyi platformun şifreli
/// deposuna yazar:
///
/// - **iOS/macOS:** Keychain (`first_unlock` erişilebilirliği — cihaz açılıştan
///   sonra bir kez kilidi açıldığında erişilebilir, şifreli yedeklerle taşınır)
/// - **Android:** AES/GCM ile şifrelenmiş depo (API 23+)
///
/// `SharedPreferences` yalnızca hassas olmayan tercihler için kullanılmaya
/// devam eder (onboarding bayrağı, bildirim aç/kapa).
class SecureStore {
  static const FlutterSecureStorage _defaultStorage = FlutterSecureStorage(
    aOptions: AndroidOptions.defaultOptions,
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Migration'ın tamamlandığını işaretleyen bayrak.
  static const String migrationFlagKey = 'secure_store_migrated_v1';

  final FlutterSecureStorage _storage;

  const SecureStore({FlutterSecureStorage storage = _defaultStorage})
    : _storage = storage;

  // ─── Okuma ───

  Future<String?> getString(String key) => _storage.read(key: key);

  Future<int?> getInt(String key) async {
    final raw = await _storage.read(key: key);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<bool?> getBool(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    return raw == 'true';
  }

  Future<List<String>?> getStringList(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.map((e) => e.toString()).toList();
    } on FormatException catch (e) {
      debugPrint('SecureStore: corrupt list at "$key" — $e');
      return null;
    }
  }

  // ─── Yazma ───

  Future<void> setString(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> setInt(String key, int value) =>
      _storage.write(key: key, value: value.toString());

  Future<void> setBool(String key, bool value) =>
      _storage.write(key: key, value: value.toString());

  Future<void> setStringList(String key, List<String> values) =>
      _storage.write(key: key, value: jsonEncode(values));

  Future<void> remove(String key) => _storage.delete(key: key);

  // ─── Yeniden kurulum ───

  /// Kurulumun işareti (SharedPreferences'ta). Uygulama silinince o da
  /// siliniyor; Anahtar Zinciri silinmiyor.
  static const String installMarkerKey = 'install_marker_v1';

  /// Uygulama silinip yeniden kurulduysa eski şifreli kayıtları siler.
  ///
  /// iOS'ta Anahtar Zinciri öğeleri uygulama silinince **silinmiyor**.
  /// Uygulamayı silen kullanıcı sağlık kayıtlarının da gittiğini
  /// düşünüyor; yeniden kurduğunda kurulum ekranından sonra eski regl ve
  /// gebelik kayıtları karşısına çıkıyordu — telefonu başkasına devrederken
  /// uygulamayı silen biri için bu bir mahremiyet açığı.
  ///
  /// Taze kurulum: işaret yok **ve** SharedPreferences tamamen boş. Önceki
  /// bir sürümden güncellenen kurulumda tercihler dolu olduğundan veri
  /// silinmiyor; cihazın yedekten geri yüklenmesinde de iki depo birlikte
  /// geri geliyor. `runApp`'ten ve [migrateFromSharedPreferences]'tan önce
  /// çağrılmalı. Silme yapıldıysa `true`.
  Future<bool> clearIfFreshInstall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(installMarkerKey)) return false;
      final fresh = prefs.getKeys().isEmpty;
      if (fresh) await _storage.deleteAll();
      await prefs.setBool(installMarkerKey, true);
      return fresh;
    } catch (e) {
      debugPrint('SecureStore: fresh-install check failed — $e');
      return false;
    }
  }

  // ─── Migration ───

  /// [keys] altındaki değerleri `SharedPreferences`'tan şifreli depoya taşır
  /// ve kaynaktan siler. Yalnızca bir kez çalışır.
  ///
  /// Mevcut kullanıcıların verisi kaybolmasın diye `runApp`'ten önce
  /// çağrılmalıdır.
  Future<void> migrateFromSharedPreferences(List<String> keys) async {
    try {
      if (await _storage.read(key: migrationFlagKey) != null) return;

      final prefs = await SharedPreferences.getInstance();

      for (final key in keys) {
        if (!prefs.containsKey(key)) continue;

        final value = prefs.get(key);
        if (value is String) {
          await setString(key, value);
        } else if (value is int) {
          await setInt(key, value);
        } else if (value is bool) {
          await setBool(key, value);
        } else if (value is List<String>) {
          await setStringList(key, value);
        } else if (value is double) {
          await setString(key, value.toString());
        } else {
          continue; // Bilinmeyen tip — kaynakta bırak.
        }

        await prefs.remove(key);
      }

      await _storage.write(key: migrationFlagKey, value: 'true');
      debugPrint(
        'SecureStore: migrated ${keys.length} key(s) from SharedPreferences.',
      );
    } catch (e) {
      // Migration başarısız olursa veri SharedPreferences'ta kalır ve
      // bir sonraki açılışta tekrar denenir — veri kaybı olmaz.
      debugPrint('SecureStore: migration failed — $e');
    }
  }

  /// Şifreli depoda tutulan tüm hassas anahtarlar.
  ///
  /// Migration ve "verilerimi sil" akışı bu listeyi kullanır; yeni bir hassas
  /// anahtar eklendiğinde buraya da eklenmelidir.
  static const List<String> sensitiveKeys = [
    // PeriodRepository
    'period_logs',
    'daily_logs',
    // CycleSettingsRepository
    'user_cycle_length',
    'user_period_length',
    'settings_updated_at',
    // IntimacyRepository
    'intimacy_sexual_desire',
    'intimacy_affection_needs',
    'intimacy_auto_share',
    'intimacy_last_shared_at',
    'intimacy_daily_share_count',
    'intimacy_daily_share_date',
    'intimacy_offline_queue',
    // ProfileRepository
    'profile_name',
    'profile_email',
    'profile_birth_date',
    // PregnancyRepository
    //
    // Gebelik durumu uygulamadaki en hassas veri: cihaz başkasının eline
    // geçtiğinde ya da yedek sızdığında sonucu en ağır olan bu. Düz metin
    // saklanamaz.
    'pregnancies',
    // CareRepository — randevu ve tarama listesi gebeliği ele veriyor
    // ("18–22. hafta: anomali taraması"); gebelik kaydı kadar hassas.
    'care_events',
    // ConceptionRepository — "gebe kalmaya çalışıyorum" üreme sağlığına dair
    // hassas bir bilgi.
    'conception_intent',
  ];

  /// Tüm hassas verileri siler (profil → "Verilerimi Sil").
  Future<void> clearSensitiveData() async {
    for (final key in sensitiveKeys) {
      await remove(key);
    }
  }
}
