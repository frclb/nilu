package com.furkan.rcperiodtracker

import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth biyometrik istemi bir FragmentActivity içinde açıyor; düz
// FlutterActivity ile uygulama kilidi Android'de hiç açılmaz.
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Reddedilen bir izin (kamera, bildirim) için uygulamanın ayar
        // sayfası. Dart tarafı: lib/core/platform/app_settings_link.dart.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nilu/app_settings")
            .setMethodCallHandler { call, result ->
                if (call.method != "open") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val intent = Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", packageName, null),
                    )
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
    }
}
