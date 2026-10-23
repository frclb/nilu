import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/platform/app_settings_link.dart';
import '../../../design_system/app_scrim.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';

/// Kamera kullanılamadığında gösterilen ekran.
///
/// İki farklı sebebi ayırır: izin verilmemiş olması (kullanıcı bunu ayarlardan
/// düzeltebilir) ve cihazda kamera bulunmaması (düzeltemez).
///
/// Tarayıcı ekranı her temada koyu (kamera görüntüsü temayla değişmiyor);
/// bu ekran da onun yerinde durduğu için koyu kalıyor. Vurgu rengi koyu
/// temanın ikincil rengi, tarayıcının nişangâhıyla aynı.
class ScanUnavailable extends StatelessWidget {
  final MobileScannerException error;

  const ScanUnavailable({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    final vurgu = AppTokens.dark.secondary;

    return ColoredBox(
      color: AppScrim.cameraBackground,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppScrim.frost(22),
                  border: Border.all(color: AppScrim.frost(30)),
                ),
                child: Icon(
                  denied ? Icons.no_photography_outlined : Icons.videocam_off,
                  size: 40,
                  color: vurgu,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.tr(
                  denied
                      ? 'partner_scan_camera_denied'
                      : 'partner_scan_camera_missing',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppScrim.ink,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              // Kamera izni uygulamanın kendi ayar sayfasında duruyor, yani
              // düğme tam doğru yere açılıyor. Kamera **yoksa** düğme yok:
              // ayarlarda düzeltilecek bir şey de yok.
              if (denied && AppSettingsLink.isSupported) ...[
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: AppSettingsLink.open,
                  style: FilledButton.styleFrom(
                    backgroundColor: vurgu,
                    foregroundColor: AppTokens.dark.background,
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                  ),
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
