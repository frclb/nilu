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

  /// Kullanıcının seçebileceği sınırlar.
  ///
  /// Tek kaynak olmak zorunda. Onboarding çarkı 21–45 arası döngü
  /// seçtiriyordu, ayarlardaki kaydırıcı ise 21–35 kabul ediyordu: 36 gün
  /// ya da üstünü seçen kullanıcı Döngü Ayarları'nı açtığında ekran
  /// `Slider`'ın 'value >= min && value <= max' iddiasıyla çöküyordu.
  /// Uzun döngü tıbben olağandışı değil (PCOS, düzensiz döngüler), yani
  /// onboarding'in aralığı doğru olandı; kaydırıcı ona uyduruldu.
  static const int minCycleLength = 21;
  static const int maxCycleLength = 45;
  static const int minPeriodLength = 2;
  static const int maxPeriodLength = 10;

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
  ///
  /// Bu değerler bir **başlangıç tahmini**: kayıt yokken kullanılıyor,
  /// kayıtlar biriktikçe yerini kullanıcının gerçek döngülerine bırakıyor.
  ///
  /// Önceden `settingsUpdatedAt` 2000 yılına yazılıyordu: "her döngü bu
  /// ayardan sonra başladı" demek. Sonuç, tahminin kayıtlardan hiç
  /// öğrenmemesiydi — kurulumda tekerleğe dokunmadan geçen kullanıcının
  /// varsayılan değeri yıllarca "senin döngün" diye kullanılıyordu, geçmiş
  /// reglleri toplu girmek de hiçbir şeyi değiştirmiyordu. Tarih artık
  /// yazılmıyor (önceden kalmışsa siliniyor).
  Future<void> saveInitialSettings({
    required int cycleLength,
    required int periodLength,
  }) async {
    await _store.setInt(_cycleLengthKey, cycleLength);
    await _store.setInt(_periodLengthKey, periodLength);
    await _store.remove(_settingsUpdatedAtKey);
  }

  /// Kayıtlı döngü uzunluğunu döndürür (varsayılan: 28).
  Future<int> getCycleLength() async {
    return await _store.getInt(_cycleLengthKey) ?? defaultCycleLength;
  }

  /// Kullanıcı bir döngü uzunluğu kaydetti mi (kurulumda ya da ayarlarda)?
  ///
  /// [getCycleLength] kayıt yokken de 28 döndürüyor; o sayının kullanıcıdan
  /// mı varsayılandan mı geldiğini yalnızca bu söylüyor.
  Future<bool> hasCycleLength() async =>
      await _store.getInt(_cycleLengthKey) != null;

  /// Kullanıcı bir kanama süresi kaydetti mi?
  Future<bool> hasPeriodLength() async =>
      await _store.getInt(_periodLengthKey) != null;

  /// Başka bir cihazdan gelen ayarları olduğu gibi yazar (bulut eşitleme).
  ///
  /// [saveCycleSettings] tarihi "şimdi" yapıyor; burada öbür cihazın tarihi
  /// korunmalı, yoksa iki cihaz birbirinin tahmin kuralını değiştirirdi.
  /// Girilmemiş süre silinir: varsayılanla doldurulursa kullanıcının
  /// söylemediği bir sayı onunmuş gibi görünür.
  Future<void> restore({
    int? cycleLength,
    int? periodLength,
    DateTime? updatedAt,
    required bool hormonalContraception,
  }) async {
    cycleLength == null
        ? await _store.remove(_cycleLengthKey)
        : await _store.setInt(_cycleLengthKey, cycleLength);
    periodLength == null
        ? await _store.remove(_periodLengthKey)
        : await _store.setInt(_periodLengthKey, periodLength);
    updatedAt == null
        ? await _store.remove(_settingsUpdatedAtKey)
        : await _store.setString(
            _settingsUpdatedAtKey,
            updatedAt.toIso8601String(),
          );
    await _store.setBool(_hormonalContraceptionKey, hormonalContraception);
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
  ///
  /// Eski sürümlerin kurulumda yazdığı 2000 yılı bir tarih değil, "kurulum
  /// değeri her şeyi ezsin" işaretiydi (bkz. [saveInitialSettings]); yok
  /// sayılıyor.
  Future<DateTime?> getSettingsUpdatedAt() async {
    final dateStr = await _store.getString(_settingsUpdatedAtKey);
    if (dateStr == null) return null;
    final date = DateTime.tryParse(dateStr);
    if (date == null || date.year <= _legacyInitialYear) return null;
    return date;
  }

  /// Eski kurulum işaretinin yılı.
  static const int _legacyInitialYear = 2000;
}
