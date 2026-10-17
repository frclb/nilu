import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Ana ekran simgesi.
enum AppIconChoice {
  /// Uygulamanın kendi simgesi.
  standard,

  /// Takip uygulaması olduğunu ele vermeyen sade bir not sayfası.
  ///
  /// Telefonu başkalarıyla paylaşan ya da ana ekranının görülmesinden
  /// çekinen kullanıcı için. Simgenin altındaki ad değişmiyor (iOS buna izin
  /// vermiyor); ekran bunu söylüyor.
  neutral,
}

/// Simge değiştirme sonucu.
enum AppIconResult {
  changed,

  /// iOS kısa aralıklarla yapılan değişiklikleri bir süre reddediyor; bir
  /// arıza değil, biraz sonra yeniden denenebilir.
  throttled,

  failed,
}

/// Ana ekran simgesini değiştirir (iOS alternatif simgeleri).
///
/// Yerel taraf `ios/Runner/AppDelegate.swift`, simge seti
/// `Assets.xcassets/AppIconNeutral.appiconset`. Kanal yoksa (test, başka
/// platform) özellik yok sayılıyor: ekran bölümü hiç çizmiyor.
class AppIconService {
  const AppIconService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const String channelName = 'nilu/app_icon';

  /// Asset kataloğundaki alternatif setin adı; derleme ayarındakiyle aynı.
  static const String neutralIconName = 'AppIconNeutral';

  final MethodChannel _channel;

  Future<bool> isSupported() async {
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (e) {
      debugPrint('App icon support check failed: $e');
      return false;
    }
  }

  Future<AppIconChoice> current() async {
    try {
      final name = await _channel.invokeMethod<String>('current');
      return name == neutralIconName
          ? AppIconChoice.neutral
          : AppIconChoice.standard;
    } on MissingPluginException {
      return AppIconChoice.standard;
    } on PlatformException catch (e) {
      debugPrint('App icon read failed: $e');
      return AppIconChoice.standard;
    }
  }

  /// Simgeyi değiştirir.
  Future<AppIconResult> set(AppIconChoice choice) async {
    try {
      final sonuc = await _channel.invokeMethod<Object>(
        'set',
        choice == AppIconChoice.neutral ? neutralIconName : null,
      );
      return switch (sonuc) {
        'ok' || true => AppIconResult.changed,
        'throttled' => AppIconResult.throttled,
        _ => AppIconResult.failed,
      };
    } on MissingPluginException {
      return AppIconResult.failed;
    } on PlatformException catch (e) {
      debugPrint('App icon change failed: $e');
      return AppIconResult.failed;
    }
  }
}
