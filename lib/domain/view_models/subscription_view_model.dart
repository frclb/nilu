import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/subscription_pricing.dart';
import '../services/subscription_service.dart';

class SubscriptionViewModel extends ChangeNotifier {
  bool _isPremium = false;
  bool _isLoading = true;
  Offerings? _offerings;

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  Offerings? get offerings => _offerings;

  /// Mağazadan gelen planlar.
  ///
  /// Ekran eskiden üç sabit kart çiziyordu ve fiyatları lokalizasyon
  /// dosyalarından okuyordu. RevenueCat'te hangi paketler tanımlıysa artık
  /// onlar gösteriliyor.
  List<SubscriptionPlan> get plans {
    final packages = _offerings?.current?.availablePackages ?? const [];
    return SubscriptionPricing.sorted(
      packages.map(_toPlan).whereType<SubscriptionPlan>().toList(),
    );
  }

  Package? packageFor(String id) => _offerings?.current?.availablePackages
      .where((p) => p.identifier == id)
      .firstOrNull;

  static SubscriptionPlan? _toPlan(Package package) {
    final period = _periodOf(package.packageType);
    if (period == null) return null;

    final product = package.storeProduct;
    return SubscriptionPlan(
      id: package.identifier,
      period: period,
      // Mağazadan gelen biçimlendirilmiş metin: doğru para birimi, doğru
      // ondalık ayracı, varsa bölgesel fiyat.
      priceString: product.priceString,
      price: product.price,
      introOffer: product.introductoryPrice?.periodNumberOfUnits != null
          ? product.introductoryPrice?.priceString
          : null,
    );
  }

  static PlanPeriod? _periodOf(PackageType type) => switch (type) {
    PackageType.weekly => PlanPeriod.weekly,
    PackageType.monthly => PlanPeriod.monthly,
    PackageType.twoMonth => PlanPeriod.twoMonth,
    PackageType.threeMonth => PlanPeriod.threeMonth,
    PackageType.sixMonth => PlanPeriod.sixMonth,
    PackageType.annual => PlanPeriod.annual,
    // Ömür boyu, özel ve bilinmeyen paketler abonelik ekranına ait değil.
    _ => null,
  };

  SubscriptionViewModel() {
    _init();
  }

  Future<void> _init() async {
    await checkPremiumStatus();
    await fetchOfferings();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> checkPremiumStatus() async {
    _isPremium = await SubscriptionService.isPremium();
    notifyListeners();
  }

  Future<void> fetchOfferings() async {
    _offerings = await SubscriptionService.getOfferings();
    notifyListeners();
  }

  Future<bool> purchasePackage(Package package) async {
    _isLoading = true;
    notifyListeners();

    final success = await SubscriptionService.purchasePackage(package);
    if (success) {
      _isPremium = true;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    notifyListeners();

    final success = await SubscriptionService.restorePurchases();
    if (success) {
      _isPremium = true;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
