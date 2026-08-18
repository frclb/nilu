/// Bir abonelik planının süresi.
///
/// `purchases_flutter`'ın `PackageType`'ından bağımsız tutuldu: hesap saf
/// kalsın ve mağaza SDK'sı olmadan test edilebilsin.
enum PlanPeriod {
  weekly(labelKey: 'premium_period_weekly', months: 1 / 4.345),
  monthly(labelKey: 'premium_period_monthly', months: 1),
  twoMonth(labelKey: 'premium_period_two_month', months: 2),
  threeMonth(labelKey: 'premium_period_three_month', months: 3),
  sixMonth(labelKey: 'premium_period_six_month', months: 6),
  annual(labelKey: 'premium_period_annual', months: 12);

  const PlanPeriod({required this.labelKey, required this.months});

  final String labelKey;

  /// Kaç aya karşılık geldiği. Haftalık için 4.345 (yılın ortalama ay
  /// uzunluğu); 4 kullanmak yıllık karşılaştırmayı %8 saptırırdı.
  final double months;
}

/// Ekranda gösterilecek plan.
class SubscriptionPlan {
  final String id;
  final PlanPeriod period;

  /// Mağazadan gelen, kullanıcının para biriminde biçimlendirilmiş fiyat.
  ///
  /// Fiyat metinleri eskiden lokalizasyon dosyalarında sabitti: Türkçe
  /// `₺349,99`, Almanca ve Fransızca ise **dolar**. Mağazadaki fiyat
  /// değiştiğinde ekran eskisini göstermeye devam ediyordu ve bölgesel
  /// fiyatlar, tanıtım teklifleri hiç görünmüyordu.
  final String priceString;

  /// Ham fiyat — karşılaştırma için.
  final double price;

  /// Varsa deneme/tanıtım süresi açıklaması.
  final String? introOffer;

  const SubscriptionPlan({
    required this.id,
    required this.period,
    required this.priceString,
    required this.price,
    this.introOffer,
  });

  /// Aylığa indirgenmiş fiyat.
  double get monthlyEquivalent => price / period.months;
}

/// Plan listesi üzerindeki hesaplar.
class SubscriptionPricing {
  const SubscriptionPricing._();

  /// En pahalı aylık eşdeğere göre tasarruf yüzdesi.
  ///
  /// "%40 tasarruf" rozeti sabit yazılıydı; mağazadaki fiyat değişince
  /// yanlış bir vaat hâline geliyordu. Artık gerçek fiyatlardan hesaplanıyor.
  ///
  /// Referans plan (en pahalı) için ve fark %5'in altındaysa null döner —
  /// "%2 tasarruf" rozeti gürültüden ibaret.
  static int? savingPercent(SubscriptionPlan plan, List<SubscriptionPlan> all) {
    if (all.length < 2) return null;

    final dearest = all
        .map((p) => p.monthlyEquivalent)
        .reduce((a, b) => a > b ? a : b);
    if (dearest <= 0) return null;

    final saving = ((dearest - plan.monthlyEquivalent) / dearest) * 100;
    if (saving < 5) return null;
    return saving.round();
  }

  /// Önerilecek plan: aylık maliyeti en düşük olan.
  static SubscriptionPlan? best(List<SubscriptionPlan> all) {
    if (all.isEmpty) return null;
    return all.reduce(
      (a, b) => a.monthlyEquivalent <= b.monthlyEquivalent ? a : b,
    );
  }

  /// Uzundan kısaya sıralar — en iyi teklif üstte.
  static List<SubscriptionPlan> sorted(List<SubscriptionPlan> all) {
    final copy = List<SubscriptionPlan>.from(all)
      ..sort((a, b) => b.period.months.compareTo(a.period.months));
    return copy;
  }
}
