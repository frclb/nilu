import 'package:flutter/material.dart';
import '../../core/platform/app_haptics.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_scrim.dart';
import 'widgets/partner_unavailable_notice.dart';
import 'widgets/scan_unavailable.dart';
import '../../design_system/app_tokens.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../domain/services/pairing_token.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/services/partner_code.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../design_system/app_layout.dart';

class PartnerScanScreen extends StatefulWidget {
  const PartnerScanScreen({super.key, this.remote});

  /// Testte sahte eşleşme sunucusu.
  final FirestoreDataSource? remote;

  @override
  State<PartnerScanScreen> createState() => _PartnerScanScreenState();
}

class _PartnerScanScreenState extends State<PartnerScanScreen> {
  // We use MobileScannerController to pause/start parsing barcodes
  final MobileScannerController _scannerController = MobileScannerController();
  late final FirestoreDataSource _remote =
      widget.remote ?? FirestoreDataSource();

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
    final String? ownerUid;
    try {
      ownerUid = await _remote.resolvePairingToken(token);
    } on PairingUnavailable {
      // Sunucuya ulaşılamadı: "geçersiz kod" demek yanlış olurdu.
      if (!mounted) return;
      _showMessage(context.tr('partner_scan_unreachable'), ok: false);
      await _resumeScanner();
      if (!mounted) return;
      setState(() => _isProcessing = false);
      return;
    }
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
    AppHaptics.error();
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

  /// Kamera ekranında bildirim kameranın üstünde yüzüyor; bu yüzden
  /// [AppSnack] değil. Sonuç titreşimi aynı.
  void _showMessage(String text, {required bool ok}) {
    ok ? AppHaptics.success() : AppHaptics.error();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showConfirmationDialog(String code) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ScanConfirmSheet(
        token: _scannedToken,
        onConfirm: () => _confirmConnection(code),
        onCancel: () {
          Navigator.pop(context); // close sheet
          setState(() {
            _isProcessing = false;
          });
          _scannerController.start(); // resume scanning
        },
      ),
    );
  }

  /// İstek bırakır ve bu cihazı partner moduna geçirir.
  ///
  /// Kodu okumak tek başına erişim vermiyor: sahip onaylayana kadar hiçbir
  /// şey okunamaz. İstek gönderilemezse (sunucu yok, bağlantı yok) cihaz
  /// partner moduna geçmiyor — önceden geçiyor ve "istek gönderildi"
  /// diyordu.
  Future<void> _confirmConnection(String ownerUid) async {
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
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    final requested = context.tr('partner_scan_requested');
    final failed = context.tr('partner_scan_request_failed');

    final ok = await userViewModel.requestPartnerAccess(
      token: _scannedToken!,
      ownerUid: ownerUid,
    );
    if (!mounted) return;
    navigator.pop(); // yükleniyor
    navigator.pop(); // onay sayfası
    _showMessage(ok ? requested : failed, ok: ok);
    if (ok) {
      router.goNamed(RouteNames.home);
    } else {
      setState(() => _isProcessing = false);
      await _resumeScanner();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Kamera her temada koyu; geri dönülebiliyorsa buzlu bir daire içinde
    // geri düğmesi.
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor:
          AppScrim.cameraBackground, // Better for scanner background
      appBar: AppBar(
        title: Text(context.tr('partner_scan_title')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppScrim.ink),
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(
          color: AppScrim.ink,
          fontSize: 21,
          fontWeight: FontWeight.w600,
        ),
        leading: canPop
            ? Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppScrim.frost(36),
                  ),
                  child: const BackButton(color: AppScrim.ink),
                ),
              )
            : null,
      ),
      extendBodyBehindAppBar: true,
      body: AppContentWidth(
        child: !_remote.isAvailable
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: PartnerUnavailableNotice(),
                ),
              )
            : MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
                // Paketin kendi hata ekranı İngilizce sabit metin gösteriyor
                // ("Scanning is not supported on this device"). Kullanıcı kamera
                // iznini reddettiğinde de bu ekran çıkıyor, yani gerçek cihazda
                // ulaşılabilir bir durum.
                errorBuilder: (context, error) => ScanUnavailable(error: error),
                // Çerçeve ve alt ipucu `overlayBuilder`'a veriliyor; paket bunları
                // **yalnızca önizleme görünürken** çiziyor.
                //
                // Önceden ikisi de `Stack`'te `MobileScanner`'ın kardeşiydi ve
                // kamera açılamadığında da çiziliyordu: karartma katmanı hata
                // metnini kenarlardan soluklaştırıyor, köşe parantezleri "Ayarları
                // aç" düğmesinin üstüne biniyor, altta da "Karekod otomatik olarak
                // taranacaktır" yazıyordu — hiçbir şeyin taranamayacağı bir ekranda.
                overlayBuilder: (context, constraints) {
                  // Kesim alanı **gelen genişlikten** hesaplanıyor, ekranınkinden
                  // değil: geniş ekranda önizleme okunur genişlikte ortalanıyor ve
                  // ekran genişliğinin %70'i kutunun kendisinden büyük çıkıyordu.
                  final size = constraints.biggest;
                  final cutOut = size.shortestSide * 0.70;
                  final bottomInset = MediaQuery.of(context).padding.bottom;
                  // İpucu kesimin hemen altında; kısa ekranda alta yaslanıyor.
                  final hintTop = ((size.height + cutOut) / 2 + 24).clamp(
                    0.0,
                    size.height - bottomInset - 72,
                  );
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: ShapeDecoration(
                            shape: _ScannerOverlayShape(
                              borderColor: _reticle,
                              borderRadius: 20,
                              borderLength: 34,
                              borderWidth: 4,
                              cutOutSize: cutOut,
                            ),
                          ),
                        ),
                      ),

                      // İpucu hapı
                      Positioned(
                        top: hintTop,
                        left: 20,
                        right: 20,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: AppScrim.frost(30),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _reticle,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    context.tr('partner_scan_helper'),
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppScrim.ink,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

/// Nişangâhın ve ipucu noktasının rengi: koyu kamera görüntüsü üstünde
/// parlayan gül. Kamera temayla değişmediği için koyu temanın ikincil rengi
/// her iki temada da kullanılıyor (bkz. `AppScrim`).
final Color _reticle = AppTokens.dark.secondary;

/// Karekod okunduktan sonraki onay sayfası.
///
/// Kamera ekranının üstünde açıldığı için koyu: açık bir sayfa karanlık
/// görüntünün üstünde göz alıyordu.
class _ScanConfirmSheet extends StatelessWidget {
  const _ScanConfirmSheet({
    required this.token,
    required this.onConfirm,
    required this.onCancel,
  });

  /// Okunan eşleştirme kodu; hangi kodun onaylandığı görünsün.
  final String? token;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const surface = AppTokens.dark;
    final code = token;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: surface.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        boxShadow: AppScrim.lift(
          blurRadius: 24,
          offset: const Offset(0, -6),
          alpha: 70,
        ),
      ),
      child: SafeArea(
        top: false,
        child: AppContentWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppScrim.frost(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: surface.success.withAlpha(40),
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: surface.success,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('partner_scan_success_title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppScrim.ink,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (code != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppScrim.frost(18),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2, color: _reticle, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          PairingToken.forDisplay(code),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppScrim.ink,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppScrim.frost(10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline,
                        color: _reticle,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('partner_scan_success_desc'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppScrim.inkMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppGradientButton(
                label: context.tr('partner_scan_confirm'),
                icon: Icons.link,
                onPressed: onConfirm,
                radius: AppRadius.pill,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppScrim.inkMuted,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(context.tr('partner_scan_cancel')),
              ),
            ],
          ),
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

    // Köşe parantezleri: kesimin yuvarlak köşesini aynı yarıçapla izliyor.
    // Önceki eğriler köşeden köşeye farklıydı (sağ alt köşe parantezin
    // tamamını tek bir eğriyle çiziyordu).
    final l = cutOutRect.left;
    final t = cutOutRect.top;
    final r = cutOutRect.right;
    final b = cutOutRect.bottom;
    final arc = Radius.circular(borderRadius);
    final path = Path()
      // Sol üst
      ..moveTo(l, t + borderLength)
      ..lineTo(l, t + borderRadius)
      ..arcToPoint(Offset(l + borderRadius, t), radius: arc)
      ..lineTo(l + borderLength, t)
      // Sağ üst
      ..moveTo(r - borderLength, t)
      ..lineTo(r - borderRadius, t)
      ..arcToPoint(Offset(r, t + borderRadius), radius: arc)
      ..lineTo(r, t + borderLength)
      // Sağ alt
      ..moveTo(r, b - borderLength)
      ..lineTo(r, b - borderRadius)
      ..arcToPoint(Offset(r - borderRadius, b), radius: arc)
      ..lineTo(r - borderLength, b)
      // Sol alt
      ..moveTo(l + borderLength, b)
      ..lineTo(l + borderRadius, b)
      ..arcToPoint(Offset(l, b - borderRadius), radius: arc)
      ..lineTo(l, b - borderLength);

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
