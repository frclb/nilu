import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_platform.dart';

/// Uygulamayı bir sistem ekranından açan eylemler (yalnız Android).
///
/// Health Connect'in izin ekranında uygulamanın gizlilik politikasına giden
/// bir bağlantı var; dokununca Health Connect uygulamayı bir "gerekçe"
/// eylemiyle açıyor. Google incelemesi o anda politikanın gösterilmesini
/// istiyor — ana ekranın açılması yetmiyor.
///
/// Uygulama kapalıyken açıldıysa eylem `MainActivity`'de bekliyor
/// (`takeAction`); açıkken geldiyse kanal kendisi haber veriyor (`action`).
abstract final class LaunchActions {
  /// Gizlilik politikasını aç.
  static const String privacyPolicy = 'privacy_policy';

  static const MethodChannel _channel = MethodChannel('nilu/launch');

  /// Eylemin ekranı kapandı. Pencere yalnızca o eylem için açıldıysa
  /// kapanıyor ve kullanıcı geldiği yere (Health Connect izin ekranına)
  /// dönüyor.
  static Future<void> done() async {
    if (!AppPlatform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('done');
    } on Exception catch (e) {
      debugPrint('Launch action done failed: $e');
    }
  }

  /// [onAction]'ı bekleyen ve gelecek eylemlere bağlar.
  static Future<void> attach(void Function(String action) onAction) async {
    if (!AppPlatform.isAndroid) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'action' && call.arguments is String) {
        onAction(call.arguments as String);
      }
    });
    try {
      final pending = await _channel.invokeMethod<String>('takeAction');
      if (pending != null) onAction(pending);
    } on Exception catch (e) {
      debugPrint('Launch action unavailable: $e');
    }
  }
}
