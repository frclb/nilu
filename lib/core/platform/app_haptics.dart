import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bir işin sonucunu bildiren titreşimler: başarı, uyarı, hata.
///
/// Apple'ın yönergeleri sonucu yalnızca renk ve yazıyla değil titreşimle de
/// bildirmeyi öneriyor: telefon sessizdeyken, ekrana bakılmıyorken ya da
/// VoiceOver açıkken de ulaşsın. Flutter'ın `HapticFeedback`'i yalnızca darbe
/// ve seçim titreşimlerini veriyor; bunlar yerel kanaldan
/// (`AppDelegate.swift`, `MainActivity.kt`). İki sistem de kullanıcının
/// titreşim ayarına uyuyor.
///
/// Az kullanılıyor: önemli bir işin bittiğini ya da yapılamadığını söyleyen
/// bildirimlerde ([AppSnack]). Her dokunuşta titreşim anlamını yitiriyor.
abstract final class AppHaptics {
  static const MethodChannel _channel = MethodChannel('nilu/haptics');

  /// Önemli bir iş tamamlandı (kayıt, içe aktarma, eşleşme).
  static Future<void> success() => _notify('success');

  /// İş yapıldı ama dikkat gereken bir sonuçla.
  static Future<void> warning() => _notify('warning');

  /// İş yapılamadı.
  static Future<void> error() => _notify('error');

  static Future<void> _notify(String kind) async {
    try {
      await _channel.invokeMethod<void>('notify', kind);
    } on MissingPluginException {
      // Testte ve kanalı olmayan platformlarda sessiz.
    } on PlatformException catch (e) {
      debugPrint('Haptic failed: $e');
    }
  }
}
