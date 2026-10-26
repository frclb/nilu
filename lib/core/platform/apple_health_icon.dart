import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_platform.dart';

/// Apple Sağlık'ın resmî simgesi (yalnızca iOS).
///
/// Apple'ın yönergeleri Sağlık'la çalışan uygulamanın bunu göstermek için
/// yalnızca Apple'ın simgesini kullanmasını istiyor; benzerini çizmek
/// yasak. Simgenin lisansı onu yalnızca iOS'ta çalışan yazılımda kullanmaya
/// izin veriyor: Flutter varlıkları Android paketine de girdiği için simge
/// iOS paketinde (Assets.xcassets → `AppleHealthIcon`) duruyor ve yerel
/// kanaldan PNG olarak alınıyor.
///
/// Kurallar: yanında "Apple Sağlık" adı yazıyor, maske/gölge/kenar yok,
/// çevresinde yüksekliğinin onda biri boşluk var, düğme olarak
/// kullanılmıyor.
abstract final class AppleHealthIcon {
  static const MethodChannel _channel = MethodChannel('nilu/apple_artwork');

  static Future<Uint8List?>? _cache;

  /// Mağaza görsellerinde simge (iOS ekranları testte çiziliyor).
  @visibleForTesting
  static Uint8List? debugBytes;

  /// Simgenin PNG'si; Android'de ve kanal yoksa `null`.
  static Future<Uint8List?> load() {
    if (debugBytes case final bytes?) return SynchronousFuture(bytes);
    if (AppPlatform.isAndroid) return SynchronousFuture(null);
    return _cache ??= _fetch();
  }

  static Future<Uint8List?> _fetch() async {
    try {
      return await _channel.invokeMethod<Uint8List>('healthIcon');
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('Apple Health icon unavailable: $e');
      return null;
    }
  }
}
