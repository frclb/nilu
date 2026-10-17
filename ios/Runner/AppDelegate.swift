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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
          result(false)
          return
        }
        let name = call.arguments as? String
        app.setAlternateIconName(name) { error in
          // Tamamlama UIKit'in kuyruğunda geliyor; Flutter yanıtı ana
          // iş parçacığında bekliyor.
          DispatchQueue.main.async {
            if let error = error {
              NSLog("Alternate icon failed: \(error.localizedDescription)")
            }
            result(error == nil)
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
