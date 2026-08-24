import 'package:flutter/material.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../domain/services/pairing_token.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/services/partner_code.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../design_system/app_colors.dart';

/// Kamera kullanılamadığında gösterilen ekran.
///
/// İki farklı sebebi ayırır: izin verilmemiş olması (kullanıcı bunu ayarlardan
/// düzeltebilir) ve cihazda kamera bulunmaması (düzeltemez).
class _ScanUnavailable extends StatelessWidget {
  final MobileScannerException error;

  const _ScanUnavailable({required this.error});

  @override
  Widget build(BuildContext context) {
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                denied ? Icons.no_photography_outlined : Icons.videocam_off,
                size: 48,
                color: Colors.white70,
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
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PartnerScanScreen extends StatefulWidget {
  const PartnerScanScreen({super.key});

  @override
  State<PartnerScanScreen> createState() => _PartnerScanScreenState();
}

class _PartnerScanScreenState extends State<PartnerScanScreen> {
  // We use MobileScannerController to pause/start parsing barcodes
  final MobileScannerController _scannerController = MobileScannerController();
  final FirestoreDataSource _remote = FirestoreDataSource();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;

    // Eskiden okunan **her** QR doğrudan partnerId olarak kaydediliyordu:
    // afişteki bir bağlantı ya da kişinin kendi kodu da dahil.
    //
    // Artık iki aşama var. QR'daki şey UID değil döndürülebilir bir kod;
    // kime ait olduğu ancak sunucuda çözülüyor. Biçim kontrolü önce
    // yapılıyor ki geçersiz her kare için ağa gidilmesin.
    final format = PartnerCode.validateFormat(raw);
    if (!format.isValid) {
      // Kamera açık kalsın: kullanıcı doğru kodu okutmayı sürdürebilsin.
      _showScanError(format);
      return;
    }

    setState(() {
      _isProcessing = true;
    });
    _scannerController.stop();

    final userViewModel = context.read<UserViewModel>();
    final token = PairingToken.normalize(raw!);
    final ownerUid = await _remote.resolvePairingToken(token);
    if (!mounted) return;

    final status = PartnerCode.validateOwner(
      ownerUid,
      myId: userViewModel.myId,
      currentPartnerId: userViewModel.partnerId,
    );

    if (!status.isValid) {
      setState(() => _isProcessing = false);
      await _scannerController.start();
      if (!mounted) return;
      _showScanError(status);
      return;
    }

    _showConfirmationDialog(ownerUid!);
  }

  /// Geçersiz kodu bildirir ve taramaya devam eder.
  ///
  /// Aynı geçersiz QR kare kare tekrar okunduğu için mesaj sürekli
  /// yenilenmesin diye kısa bir bekleme konuyor.
  DateTime? _lastErrorAt;

  void _showScanError(PartnerCodeStatus status) {
    final now = DateTime.now();
    final last = _lastErrorAt;
    if (last != null && now.difference(last) < const Duration(seconds: 3)) {
      return;
    }
    _lastErrorAt = now;

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.tr(status.messageKey!)),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showConfirmationDialog(String code) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceWarmDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(51),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon Glow
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('partner_scan_success_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textMainSlate,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('partner_scan_success_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Confirm Button
                ElevatedButton(
                  onPressed: () => _confirmConnection(code),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    context.tr('partner_scan_confirm'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close sheet
                    setState(() {
                      _isProcessing = false;
                    });
                    _scannerController.start(); // resume scanning
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Text(
                    context.tr('partner_scan_cancel'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmConnection(String code) async {
    // Show a loading overlay immediately
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    // Update state
    final userViewModel = context.read<UserViewModel>();
    await userViewModel.setPartnerState(isPartner: true, partnerId: code);

    // Mark onboarding as complete
    await userViewModel.completeOnboarding();

    if (mounted) {
      // pop loading
      Navigator.pop(context);
      // pop sheet
      Navigator.pop(context);

      // Navigate Home (where Partner Dashboard will be shown if isPartner is true)
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Better for scanner background
      appBar: AppBar(
        title: Text(context.tr('partner_scan_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: _onDetect,
            // Paketin kendi hata ekranı İngilizce sabit metin gösteriyor
            // ("Scanning is not supported on this device"). Kullanıcı kamera
            // iznini reddettiğinde de bu ekran çıkıyor, yani gerçek cihazda
            // ulaşılabilir bir durum.
            errorBuilder: (context, error) => _ScanUnavailable(error: error),
          ),
          // Scanner overlay
          Positioned.fill(
            child: Container(
              decoration: ShapeDecoration(
                shape: _ScannerOverlayShape(
                  borderColor: Theme.of(context).primaryColor,
                  borderRadius: 12,
                  borderLength: 40,
                  borderWidth: 6,
                  cutOutSize: MediaQuery.of(context).size.width * 0.70,
                ),
              ),
            ),
          ),

          // Helper text at bottom
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 20,
            right: 20,
            child: Text(
              context.tr('partner_scan_helper'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overlay Shape ──
class _ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const _ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 8.0,
    this.borderLength = 30.0,
    this.borderRadius = 12.0,
    this.cutOutSize = 250.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path();
    path.addRect(rect);
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: rect.center,
          width: cutOutSize,
          height: cutOutSize,
        ),
        Radius.circular(borderRadius),
      ),
    );
    return path..fillType = PathFillType.evenOdd;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = Colors.black
          .withAlpha(165) // Darker overlay for better contrast
      ..style = PaintingStyle.fill;

    canvas.drawPath(getOuterPath(rect), paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final cutOutRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Draw corners
    Path path = Path();

    // Top left
    path.moveTo(cutOutRect.left, cutOutRect.top + borderLength);
    path.quadraticBezierTo(
      cutOutRect.left,
      cutOutRect.top,
      cutOutRect.left + borderRadius,
      cutOutRect.top,
    );
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.top);

    // Top right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.top);
    path.quadraticBezierTo(
      cutOutRect.right,
      cutOutRect.top,
      cutOutRect.right,
      cutOutRect.top + borderRadius,
    );
    path.lineTo(cutOutRect.right, cutOutRect.top + borderLength);

    // Bottom left
    path.moveTo(cutOutRect.left, cutOutRect.bottom - borderLength);
    path.quadraticBezierTo(
      cutOutRect.left,
      cutOutRect.bottom,
      cutOutRect.left + borderRadius,
      cutOutRect.bottom,
    );
    path.lineTo(cutOutRect.left + borderLength, cutOutRect.bottom);

    // Bottom right
    path.moveTo(cutOutRect.right - borderLength, cutOutRect.bottom);
    path.quadraticBezierTo(
      cutOutRect.right,
      cutOutRect.bottom,
      cutOutRect.right,
      cutOutRect.bottom - borderLength,
    );

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return _ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      borderLength: borderLength * t,
      borderRadius: borderRadius * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
