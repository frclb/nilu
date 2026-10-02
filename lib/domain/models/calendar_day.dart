/// Takvim günüyle hesap: saat diliminden ve yaz saatinden bağımsız.
///
/// `Duration(days: n)` 24 × n saat demek; yaz saatine geçilen gün 23, geri
/// dönülen gün 25 saat sürüyor. Gün eklemek ya da gün farkı saymak saatle
/// yapılınca yaz saati uygulanan saat dilimlerinde (Avrupa, ABD) tarih bir
/// gün kayıyordu: Berlin'de 1 Mayıs son adet tarihinin tahmini doğumu
/// 5 Şubat yerine 4 Şubat kaydediliyordu; 1 Mart'tan 1 Nisan'a 30 gün
/// sayılıyordu. Türkiye'de yaz saati olmadığı için ne cihazda ne testlerde
/// görünüyordu (bkz. `test/domain/dst_dates_test.dart`).
extension CalendarDay on DateTime {
  /// [n] takvim günü sonrası (yerel gece yarısı); eksi değer öncesi.
  DateTime plusDays(int n) => DateTime(year, month, day + n);

  /// [other] gününden bu güne kaç takvim günü; saatler yok sayılıyor.
  ///
  /// UTC'de yaz saati yok: iki gece yarısı arası her zaman 24 saatin katı.
  int daysSince(DateTime other) => DateTime.utc(
    year,
    month,
    day,
  ).difference(DateTime.utc(other.year, other.month, other.day)).inDays;
}
