import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerAppIconChannel()
    registerArtworkChannel()
    registerHapticsChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Apple Sağlık simgesi (bkz. `lib/core/platform/apple_health_icon.dart`).
  ///
  /// Apple'ın HealthKit görsel lisansı simgeyi yalnızca iOS'ta çalışan
  /// yazılımda kullanmaya izin veriyor. Flutter varlıkları Android paketine de
  /// girdiği için simge Assets.xcassets'te (`AppleHealthIcon`) duruyor ve
  /// buradan PNG olarak veriliyor.
  private func registerArtworkChannel() {
    guard let registrar = self.registrar(forPlugin: "NiluArtwork") else { return }
    let channel = FlutterMethodChannel(
      name: "nilu/apple_artwork",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "healthIcon" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let data = UIImage(named: "AppleHealthIcon")?.pngData() else {
        result(nil)
        return
      }
      result(FlutterStandardTypedData(bytes: data))
    }
  }

  /// Sonuç titreşimleri: başarı, uyarı, hata (bkz.
  /// `lib/core/platform/app_haptics.dart`). Flutter'ın `HapticFeedback`'i
  /// yalnızca darbe ve seçim titreşimlerini veriyor. iOS, kullanıcı Ayarlar'da
  /// sistem titreşimlerini kapattıysa bunları da çalmıyor.
  private func registerHapticsChannel() {
    guard let registrar = self.registrar(forPlugin: "NiluHaptics") else { return }
    let channel = FlutterMethodChannel(
      name: "nilu/haptics",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "notify", let kind = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      let type: UINotificationFeedbackGenerator.FeedbackType
      switch kind {
      case "success": type = .success
      case "warning": type = .warning
      default: type = .error
      }
      UINotificationFeedbackGenerator().notificationOccurred(type)
      result(nil)
    }
  }

  /// Ana ekran simgesini değiştiren kanal (bkz. `lib/core/platform/app_icon.dart`).
  ///
  /// Alternatif simge Assets.xcassets içindeki `AppIconNeutral` seti; derleme
  /// ayarı `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` onu pakete
  /// koyuyor. iOS değişikliği kendi uyarısıyla bildiriyor.
  private func registerAppIconChannel() {
    guard let registrar = self.registrar(forPlugin: "NiluAppIcon") else { return }
    let channel = FlutterMethodChannel(
      name: "nilu/app_icon",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      let app = UIApplication.shared
      switch call.method {
      case "isSupported":
        result(app.supportsAlternateIcons)
      case "current":
        result(app.alternateIconName)
      case "set":
        guard app.supportsAlternateIcons else {
          result("failed")
          return
        }
        let name = call.arguments as? String
        if app.alternateIconName == name {
          result("ok")
          return
        }
        app.setAlternateIconName(name) { error in
          // Tamamlama UIKit'in kuyruğunda geliyor; Flutter yanıtı ana iş
          // parçacığında bekliyor.
          DispatchQueue.main.async {
            // Sonuca iOS'un hata koduyla değil simgenin gerçek durumuyla
            // karar veriliyor: simülatörde simge değiştiği hâlde tamamlama
            // "G/Ç hatası" (POSIX 5) döndüğü görüldü; kullanıcı "değişmedi"
            // uyarısı alırken ana ekranda yeni simge duruyordu.
            if app.alternateIconName == name {
              result("ok")
              return
            }
            guard let error = error as NSError? else {
              result("failed")
              return
            }
            NSLog("Alternate icon failed (\(error.domain) \(error.code)): \(error.localizedDescription)")
            // iOS simge değişikliğini kısa aralıklarla sınırlıyor
            // (LaunchServices "icon alert token" alamıyor: POSIX 35). Bu
            // bir arıza değil; kullanıcıya "biraz sonra" denmeli. Hemen
            // yeniden denemek sınırı uzatıyor.
            let throttled = error.domain == NSPOSIXErrorDomain && error.code == 35
            result(throttled ? "throttled" : "failed")
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
