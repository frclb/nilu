import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/platform/app_settings_link.dart';
import '../../../design_system/app_scrim.dart';
import '../../../localization/app_localizations.dart';

/// Kamera kullanılamadığında gösterilen ekran.
///
/// İki farklı sebebi ayırır: izin verilmemiş olması (kullanıcı bunu ayarlardan
/// düzeltebilir) ve cihazda kamera bulunmaması (düzeltemez).
class ScanUnavailable extends StatelessWidget {
  final MobileScannerException error;

  const ScanUnavailable({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: AppScrim.cameraBackground,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                denied ? Icons.no_photography_outlined : Icons.videocam_off,
                size: 48,
                color: AppScrim.inkMuted,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr(
                  denied
                      ? 'partner_scan_camera_denied'
                      : 'partner_scan_camera_missing',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppScrim.ink,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              // Kamera izni uygulamanın kendi ayar sayfasında duruyor, yani
              // düğme tam doğru yere açılıyor. Kamera **yoksa** düğme yok:
              // ayarlarda düzeltilecek bir şey de yok.
              if (denied && AppSettingsLink.isSupported) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: AppSettingsLink.open,
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: Text(context.tr('open_settings')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
