package com.furkan.rcperiodtracker

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.HapticFeedbackConstants
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// local_auth biyometrik istemi ve health eklentisi Health Connect izin
// istemini bir FragmentActivity içinde açıyor; düz FlutterActivity ile
// uygulama kilidi ve Health Connect izni Android'de hiç açılmaz.
class MainActivity : FlutterFragmentActivity() {

    /** Uygulamayı açan ve henüz Flutter'a iletilmemiş eylem. */
    private var pendingAction: String? = null

    /**
     * Bu pencere yalnızca gizlilik politikasını göstermek için mi açıldı.
     * Health Connect bağlantıyı izin ekranının üstünde yeni bir pencerede
     * açıyor; politika kapanınca pencere de kapanmalı ki kullanıcı izin
     * ekranına dönsün, uygulamanın ana sayfasına değil.
     */
    private var startedForAction = false
    private var launchChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Reddedilen bir izin (kamera, bildirim) için uygulamanın ayar
        // sayfası. Dart tarafı: lib/core/platform/app_settings_link.dart.
        MethodChannel(messenger, "nilu/app_settings")
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

        // Sonuç titreşimleri: başarı, uyarı, hata. Dart tarafı:
        // lib/core/platform/app_haptics.dart. Android 11+ "onay" ve "ret"
        // titreşimlerini veriyor; öncesinde en yakınları. Kullanıcı
        // dokunuş titreşimini kapattıysa sistem çalmıyor.
        MethodChannel(messenger, "nilu/haptics")
            .setMethodCallHandler { call, result ->
                if (call.method != "notify") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val success = call.arguments == "success"
                val effect = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    if (success) HapticFeedbackConstants.CONFIRM
                    else HapticFeedbackConstants.REJECT
                } else {
                    if (success) HapticFeedbackConstants.VIRTUAL_KEY
                    else HapticFeedbackConstants.LONG_PRESS
                }
                window.decorView.performHapticFeedback(effect)
                result.success(null)
            }

        // Uygulamayı açan eylem: Health Connect izin ekranındaki "gizlilik
        // politikası" bağlantısı. Google incelemesi politikanın orada
        // gösterilmesini istiyor. Dart tarafı:
        // lib/core/platform/launch_actions.dart.
        pendingAction = actionOf(intent)
        startedForAction = pendingAction != null
        launchChannel = MethodChannel(messenger, "nilu/launch").apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeAction" -> {
                        result.success(pendingAction)
                        pendingAction = null
                    }
                    "done" -> {
                        result.success(null)
                        if (startedForAction) finish()
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    // Uygulama açıkken gelen bağlantı.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = actionOf(intent) ?: return
        launchChannel?.invokeMethod("action", action)
    }

    private fun actionOf(intent: Intent?): String? = when (intent?.action) {
        "androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE",
        "android.intent.action.VIEW_PERMISSION_USAGE" -> "privacy_policy"
        else -> null
    }
}
