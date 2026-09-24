import 'package:flutter/material.dart';
import '../../design_system/app_scrim.dart';
import '../../design_system/app_tokens.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../domain/services/pairing_token.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/services/partner_code.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../core/platform/app_settings_link.dart';
import '../../../localization/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../design_system/app_layout.dart';

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

class PartnerScanScreen extends StatefulWidget {
  const PartnerScanScreen({super.key});

  @override
  State<PartnerScanScreen> createState() => _PartnerScanScreenState();
}

class _PartnerScanScreenState extends State<PartnerScanScreen> {
  // We use MobileScannerController to pause/start parsing barcodes
  final MobileScannerController _scannerController = MobileScannerController();
  final FirestoreDataSource _remote = FirestoreDataSource();

  /// Okunan eşleştirme kodu. İstek bu koda bırakılıyor.
  String? _scannedToken;
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

    // View model kamerayı durdurmadan **önce** okunuyor: `stop()` artık
    // await ediliyor ve sonrasında `context` bir async boşluğun ötesinde
    // kalıyor.
    final userViewModel = context.read<UserViewModel>();

    setState(() {
      _isProcessing = true;
    });
    await _pauseScanner();

    final token = PairingToken.normalize(raw!);
    final ownerUid = await _remote.resolvePairingToken(token);
    if (!mounted) return;

    final status = PartnerCode.validateOwner(
      ownerUid,
      myId: userViewModel.myId,
      currentPartnerId: userViewModel.partnerId,
    );

    if (!status.isValid) {
      // Mesaj kamerayı yeniden başlatmadan **önce** gösteriliyor. Ters
      // sırada, başlatma hata verdiğinde mesaja hiç sıra gelmiyordu:
      // kullanıcı neyin yanlış olduğunu öğrenemeden kamera aynı kodu
      // okumaya devam ediyordu.
      _showScanError(status);
      await _resumeScanner();
      if (!mounted) return;
      setState(() => _isProcessing = false);
      return;
    }

    _scannedToken = token;
    // `_isProcessing` açık kalıyor: onay sayfası kapanana kadar yeni
    // okuma işlenmemeli.
    _showConfirmationDialog(ownerUid!);
  }

  /// Kamerayı durdurur.
  ///
  /// `stop()` await edilmiyordu ve hemen ardından `start()` çağrılıyordu;
  /// denetleyici daha durmayı bitirmemişken:
  ///
  ///     MobileScannerException(controllerInitializing, The
  ///     MobileScannerController is still initializing.)
  ///
  /// İstisna yakalanmadığı için hata mesajı hiç gösterilmiyor, `_isProcessing`
  /// da sıfırlandığı için bir sonraki kare aynı yoldan geçiyordu — kamera
  /// aynı geçersiz kodu durmadan okumaya çalışıyordu.
  Future<void> _pauseScanner() async {
    try {
      await _scannerController.stop();
    } on MobileScannerException catch (e) {
      // Zaten durmuş ya da hiç başlamamış olabilir; ikisi de sorun değil.
      debugPrint('Scanner stop failed: ${e.errorCode}');
    }
  }

  /// Kamerayı yeniden başlatır; başlatılamazsa ekran yine de kullanılabilir
  /// kalır (kullanıcı geri dönüp tekrar girebilir).
  Future<void> _resumeScanner() async {
    try {
      await _scannerController.start();
    } on MobileScannerException catch (e) {
      debugPrint('Scanner start failed: ${e.errorCode}');
    }
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
        backgroundColor: context.tokens.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showConfirmationDialog(String code) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.tokens.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppScrim.veil(51),
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
                    color: context.tokens.success.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: context.tokens.success,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('partner_scan_success_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.tokens.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('partner_scan_success_desc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.tokens.textMuted,
                  ),
                ),
                const SizedBox(height: 32),

                // Confirm Button
                ElevatedButton(
                  onPressed: () => _confirmConnection(code),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: AppScrim.ink,
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
                    foregroundColor: context.tokens.textMuted,
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

    final userViewModel = context.read<UserViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final requested = context.tr('partner_scan_requested');

    // Kodu okumak tek başına erişim vermiyor: sahip onaylayana kadar hiçbir
    // şey okunamaz. Önceki modelde okuyan taraf kendini doğrudan bağlıyordu —
    // erişimi verenin sahip olmaması, iptalin çalışmamasının da sebebiydi.
    final myId = await userViewModel.ensureMyId();
    await _remote.requestPairing(_scannedToken!, myId);

    // Yerel taraf partner moduna geçiyor; veriyi ancak onay sonrası görecek.
    await userViewModel.setPartnerState(isPartner: true, partnerId: code);
    await userViewModel.completeOnboarding();

    if (mounted) {
      // pop loading
      Navigator.pop(context);
      // pop sheet
      Navigator.pop(context);

      messenger.showSnackBar(SnackBar(content: Text(requested)));
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppScrim.cameraBackground, // Better for scanner background
      appBar: AppBar(
        title: Text(context.tr('partner_scan_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppScrim.ink),
        titleTextStyle: const TextStyle(
          color: AppScrim.ink,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AppContentWidth(
        child: Stack(
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
            //
            // Kesim alanı **gelen genişlikten** hesaplanıyor, ekranınkinden
            // değil: geniş ekranda önizleme okunur genişlikte ortalanıyor ve
            // ekran genişliğinin %70'i kutunun kendisinden büyük çıkıyordu.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) => Container(
                  decoration: ShapeDecoration(
                    shape: _ScannerOverlayShape(
                      borderColor: Theme.of(context).primaryColor,
                      borderRadius: 12,
                      borderLength: 40,
                      borderWidth: 6,
                      cutOutSize: constraints.biggest.shortestSide * 0.70,
                    ),
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
                  color: AppScrim.inkMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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
    this.borderColor = AppScrim.ink,
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
      ..color = AppScrim.cameraBackground
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
