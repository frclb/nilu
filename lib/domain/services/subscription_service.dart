import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // RevenueCat API keys
  static const _appleApiKey =
      'appl_api_key_placeholder'; // TODO: Gerçek Apple API anahtarınızı girin

  static final Completer<void> _readyCompleter = Completer<void>();

  /// `Purchases.configure` başarıyla tamamlandı mı?
  ///
  /// Yapılandırılmamış SDK'ya sormak **yakalanabilir bir hata değil**:
  /// PurchasesHybridCommon Swift tarafında `fatalError` atıyor ve süreç
  /// çöküyor. Dart'taki `try/catch` buna dokunamıyor — açılışta SDK'lar
  /// ilk kareden sonraya alınınca uygulama tam da böyle çöktü:
  ///
  ///     PurchasesHybridCommon/CommonFunctionality.swift:21: Fatal error:
  ///     Purchases has not been configured.
  ///
  /// Bu yüzden koruma çağıranda değil burada: her giriş noktası önce buna
  /// bakıyor. Sıralamayı bilmek servisin işi, ekranların değil.
  static bool _configured = false;

  /// SDK kullanılabilir durumda mı.
  static bool get isConfigured => _configured;

  /// Yapılandırma denemesi bittiğinde tamamlanır (başarılı olmasa da).
  ///
  /// Açılış artık bu SDK'yı beklemiyor; ilk kare hemen çiziliyor. Abonelik
  /// durumunu okuyan taraf burayı bekliyor, yoksa yapılandırma bitmeden
  /// sorup "premium değil" cevabını alıyordu.
  static Future<void> get ready => _readyCompleter.future;

  static Future<void> init() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);

      late StoreConfig storeConfig;
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        storeConfig = StoreConfig(store: Store.appStore, apiKey: _appleApiKey);
      } else {
        // Android için eklenebilir
        return;
      }

      final configuration = PurchasesConfiguration(storeConfig.apiKey);
      await Purchases.configure(configuration);
      _configured = true;
    } catch (e) {
      debugPrint("RevenueCat init error: $e");
    } finally {
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    }
  }

  static Future<void> login(String uid) async {
    if (!_configured) return;
    try {
      await Purchases.logIn(uid);
    } catch (e) {
      debugPrint("RevenueCat login error: $e");
    }
  }

  static Future<void> logout() async {
    if (!_configured) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      debugPrint("RevenueCat logout error: $e");
    }
  }

  static Future<Offerings?> getOfferings() async {
    if (!_configured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint("RevenueCat getOfferings error: $e");
      return null;
    }
  }

  static Future<bool> isPremium() async {
    if (!_configured) return false;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      // 'premium' adlı entitlement kontrol ediliyor. RevenueCat panelinden 'premium' entitlement oluşturulmalı.
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      debugPrint("RevenueCat check premium error: $e");
      return false;
    }
  }

  static Future<bool> purchasePackage(Package package) async {
    if (!_configured) return false;
    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      return purchaseResult
              .customerInfo
              .entitlements
              .all['premium']
              ?.isActive ??
          false;
    } catch (e) {
      debugPrint("RevenueCat purchase error: $e");
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    if (!_configured) return false;
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      debugPrint("RevenueCat restore error: $e");
      return false;
    }
  }
}

class StoreConfig {
  final Store store;
  final String apiKey;

  StoreConfig({required this.store, required this.apiKey});
}
