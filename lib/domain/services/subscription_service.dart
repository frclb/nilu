import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../core/release_config.dart';

class SubscriptionService {
  /// Anahtar `ReleaseConfig`'te. Doldurulmamışsa SDK hiç başlatılmıyor:
  /// yer tutucu anahtarla yapılandırmak her açılışta ağ hatası üretiyor ve
  /// paywall'u boş bir teklif listesiyle bekletiyordu.
  static const _appleApiKey = ReleaseConfig.revenueCatAppleApiKey;
  static const _googleApiKey = ReleaseConfig.revenueCatGoogleApiKey;

  /// Bu platformun anahtarı; desteklenmeyen platformda `null`.
  static String? get _apiKey => switch (defaultTargetPlatform) {
    TargetPlatform.iOS => _appleApiKey,
    TargetPlatform.android => _googleApiKey,
    _ => null,
  };

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
    final apiKey = _apiKey;
    if (!ReleaseConfig.isSet(apiKey)) {
      debugPrint('RevenueCat key not set; subscriptions unavailable.');
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      return;
    }
    try {
      // Ayrıntılı günlük yalnızca geliştirirken: yayında konsola satın alma
      // ve kullanıcı kimliği ayrıntısı yazılmasın.
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

      // Anahtarın öneki mağazayı belirliyor (appl_ / goog_); SDK hangi
      // mağazaya bağlanacağını ondan biliyor.
      final configuration = PurchasesConfiguration(apiKey!);
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
      // Anonim kullanıcıda çıkış yapılamaz; RevenueCat bunu hata sayıp
      // günlüğe ERROR basıyordu:
      //
      //     LogOut was called but the current user is anonymous.
      //
      // Oysa yapılacak bir şey yok, kullanıcı zaten kimliksiz. Sahte
      // hatalar günlüğü kirletiyor ve gerçek olanları gizliyor.
      if (await Purchases.isAnonymous) return;
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
