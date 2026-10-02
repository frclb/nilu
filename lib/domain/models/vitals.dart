/// Evde ölçülen tansiyon ve kilo: kabul aralıkları ve gebelik eşikleri.
///
/// Eşikler NICE NG133 (Hypertension in pregnancy, 2019; 2023 güncellemesi)
/// ve ACOG Practice Bulletin 222'den (2020): gebelikte ve doğumdan sonra
/// 140/90 ve üstü hipertansiyon, 160/110 ve üstü ağır hipertansiyon. İkisi
/// de "bir değer yeterli" diyor — büyük ya da küçük tansiyondan biri
/// eşiği geçince.
///
/// Uygulama teşhis koymuyor: değerin hangi aralıkta olduğunu ve ne
/// yapılacağını söylüyor. Gebelik dışında eşikler farklı (NICE NG136'da
/// evde 135/85), bu yüzden ölçüm bölümü yalnızca gebelik ve lohusalıkta var.
enum BloodPressureLevel { normal, high, severe }

class Vitals {
  const Vitals._();

  // Kabul aralıkları. Bunların dışı yazım hatası ("1205", "8") ya da
  // yanlış birim; kaydedilip özete giderse hekimin önüne yanlış bir sayı
  // koyar.
  static const double minWeightKg = 30;
  static const double maxWeightKg = 250;
  static const int minSystolic = 70;
  static const int maxSystolic = 250;
  static const int minDiastolic = 40;
  static const int maxDiastolic = 150;

  static bool isPlausibleWeight(double kg) =>
      kg >= minWeightKg && kg <= maxWeightKg;

  /// Büyük tansiyon küçükten büyük olmalı: tersi alanların karıştığını
  /// gösterir ("80 / 120").
  static bool isPlausibleBloodPressure(int systolic, int diastolic) =>
      systolic >= minSystolic &&
      systolic <= maxSystolic &&
      diastolic >= minDiastolic &&
      diastolic <= maxDiastolic &&
      systolic > diastolic;

  static BloodPressureLevel classify(int systolic, int diastolic) {
    if (systolic >= 160 || diastolic >= 110) return BloodPressureLevel.severe;
    if (systolic >= 140 || diastolic >= 90) return BloodPressureLevel.high;
    return BloodPressureLevel.normal;
  }

  /// "64,5" ya da "64.5" → 64.5 (Türkçede ondalık ayırıcı virgül).
  /// Sayı değilse null.
  static double? parseDecimal(String input) =>
      double.tryParse(input.trim().replaceAll(',', '.'));
}
