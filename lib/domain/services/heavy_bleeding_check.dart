/// Yoğun regl kanaması için NHS'in listelediği işaretler.
///
/// Kaynak: https://www.nhs.uk/conditions/heavy-periods/
///
/// Her biri kullanıcının kendi gözlemi; hiçbiri tek başına teşhis değil.
enum HeavyBleedingSign {
  /// Pedi/tamponu 1–2 saatte bir değiştirmek, ya da kabı önerilenden
  /// daha sık boşaltmak.
  frequentChanges,

  /// Aynı anda birden fazla ürün kullanmak (ör. ped + tampon).
  doubleProtection,

  /// Kanamanın 7 günden uzun sürmesi.
  longerThanSevenDays,

  /// Yaklaşık 2,5 cm'den büyük pıhtı.
  largeClots,

  /// Giysiye ya da yatağa taşması.
  floodingThrough,

  /// Kanama yüzünden günlük etkinlikleri bırakmak ya da işe gidememek.
  limitsDailyLife,

  /// Yorgunluk ya da nefes darlığı eşlik etmesi.
  tirednessOrBreathlessness,
}

/// Yoğun kanama değerlendirmesinin sonucu.
class HeavyBleedingResult {
  /// Kullanıcının işaretlediği belirtiler.
  final Set<HeavyBleedingSign> signs;

  const HeavyBleedingResult(this.signs);

  bool get isEmpty => signs.isEmpty;

  /// Hekime danışılması önerilir mi?
  ///
  /// NHS "bunlardan herhangi biri varsa yoğun kanaman olabilir" diyor;
  /// bir eşik sayısı vermiyor. Bu yüzden tek işaret bile yönlendirme için
  /// yeterli sayılıyor — sayı uydurup "üç taneden fazlaysa" demek, kaynağın
  /// söylemediği bir kesinlik iddia etmek olurdu.
  bool get shouldSeeClinician => signs.isNotEmpty;

  /// Demir eksikliği açısından ayrıca dikkat çeken kombinasyon.
  ///
  /// Yoğun kanama demir eksikliği anemisinin en yaygın nedenlerinden biri;
  /// yorgunluk ya da nefes darlığı eşlik ediyorsa bu bağlantı kullanıcıya
  /// gösterilmeye değer.
  bool get suggestsIronCheck =>
      signs.contains(HeavyBleedingSign.tirednessOrBreathlessness) &&
      signs.length > 1;

  /// Belirtinin açıklama metninin çeviri anahtarı.
  static String signKey(HeavyBleedingSign sign) => switch (sign) {
    HeavyBleedingSign.frequentChanges => 'bleeding_sign_frequent_changes',
    HeavyBleedingSign.doubleProtection => 'bleeding_sign_double_protection',
    HeavyBleedingSign.longerThanSevenDays => 'bleeding_sign_longer_than_seven',
    HeavyBleedingSign.largeClots => 'bleeding_sign_large_clots',
    HeavyBleedingSign.floodingThrough => 'bleeding_sign_flooding',
    HeavyBleedingSign.limitsDailyLife => 'bleeding_sign_limits_life',
    HeavyBleedingSign.tirednessOrBreathlessness => 'bleeding_sign_tiredness',
  };
}

/// Kullanıcının işaretlediklerini değerlendirir.
///
/// Uygulama zaten akış yoğunluğunu ("hafif/orta/ağır") soruyordu ama bu tek
/// başına hiçbir şey söylemiyor: "ağır" herkes için farklı bir şey. NHS'in
/// somut ölçütleri kullanıcının kendi deneyimini karşılaştırabileceği bir
/// zemin veriyor.
class HeavyBleedingCheck {
  const HeavyBleedingCheck._();

  static const List<HeavyBleedingSign> allSigns = HeavyBleedingSign.values;

  static HeavyBleedingResult evaluate(Iterable<HeavyBleedingSign> selected) =>
      HeavyBleedingResult(selected.toSet());
}
