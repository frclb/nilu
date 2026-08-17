import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/subscription_service.dart';

class SubscriptionViewModel extends ChangeNotifier {
  bool _isPremium = false;
  bool _isLoading = true;
  Offerings? _offerings;

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  Offerings? get offerings => _offerings;

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
