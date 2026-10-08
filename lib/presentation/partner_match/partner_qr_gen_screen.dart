import 'package:flutter/material.dart';
import '../../design_system/app_scrim.dart';
import '../../design_system/app_tokens.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../data/repositories/pairing_repository.dart';
import 'widgets/pairing_requests_section.dart';
import '../../domain/services/pairing_token.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/app_layout.dart';

class PartnerQrGenScreen extends StatefulWidget {
  const PartnerQrGenScreen({super.key, this.remote});

  /// Testte sahte eşleşme sunucusu.
  final FirestoreDataSource? remote;

  @override
  State<PartnerQrGenScreen> createState() => _PartnerQrGenScreenState();
}

class _PartnerQrGenScreenState extends State<PartnerQrGenScreen> {
  late final FirestoreDataSource _remote =
      widget.remote ?? FirestoreDataSource();
  late final PairingRepository _pairing = PairingRepository(remote: _remote);

  /// QR'da paylaşılan eşleştirme kodu.
  ///
  /// Burada eskiden kullanıcının UID'si duruyordu. UID hiç değişmediği için
  /// paylaşılan QR kalıcı olarak geçerli kalıyordu: ayrılmak erişimi
  /// koparmıyor, eski partner elindeki kodla geri bağlanabiliyordu. Kod artık
  /// döndürülebilir.
  String? _token;
  bool _rotating = false;

  /// Kod sunucuda yayımlanamadı (sunucu yok ya da bağlantı yok). Önceden
  /// bu durumda da QR gösteriliyordu; okutan kişi "geçersiz kod" görüyordu.
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    if (!_remote.isAvailable) {
      setState(() => _failed = true);
      return;
    }
    // Kimlik üretimi tek bir yerde: UserViewModel.ensureMyId().
    final id = await context.read<UserViewModel>().ensureMyId();
    final token = await _pairing.currentToken(id);
    if (!mounted) return;
    setState(() {
      _token = token;
      _failed = token == null;
    });
  }

  /// Kodu yeniler. Daha önce paylaşılmış bütün QR'lar geçersiz olur.
  Future<void> _rotate() async {
    setState(() => _rotating = true);
    final id = await context.read<UserViewModel>().ensureMyId();
    final token = await _pairing.rotate(id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.tr('partner_qr_gen_failed');
    setState(() {
      // Yenilenemezse eski kod geçerli kalıyor; ekran onu göstermeye devam
      // ediyor.
      _token = token ?? _token;
      _rotating = false;
    });
    if (token == null) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
    // Onay bildirimi kaldırıldı: QR ile kodun kendisi zaten gözle görülür
    // biçimde değişiyor, bildirim ise "Eşleşme Kodunu Kopyala" düğmesinin
    // üstüne binip (390×844'te düğme 789, bildirim 780–844) yeni kodu
    // kopyalamayı dört saniye engelliyordu.
    //
    // Kopyalama bildirimi duruyor: panoya yazmanın ekranda başka bir izi yok.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = context.tokens.background;
    final surfaceColor = context.tokens.surface;
    final primaryColor = theme.colorScheme.primary;
    final textMainColor = context.tokens.text;
    final textMutedColor = context.tokens.textMuted;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textMainColor),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          context.tr('partner_qr_gen_title'),
          style: TextStyle(
            color: textMainColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: AppContentWidth(
        child: _failed
            ? _Failed(unavailable: !_remote.isAvailable, onRetry: _load)
            : _token == null
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.qr_code_2,
                        size: 60,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title and instruction
                    Text(
                      context.tr('partner_qr_gen_header'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textMainColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('partner_qr_gen_desc'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: textMutedColor,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Premium QR Code Card with glow
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Decorative Glow Background
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withAlpha(51),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),

                        // QR Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: context.tokens.border),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? AppScrim.veil(76)
                                    : primaryColor.withAlpha(20),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              QrImageView(
                                data: _token!,
                                version: QrVersions.auto,
                                size: 200.0,
                                backgroundColor: Colors.transparent,
                                eyeStyle: QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: context.tokens.text,
                                ),
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.circle,
                                  color: context.tokens.text,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // ID Display (hidden optionally or stylized)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: context.tokens.surfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                // Kodun tamamı gösteriliyor: kamera
                                // çalışmadığında elle yazılabilmeli. Kısaltılmış
                                // bir parça hiçbir işe yaramıyordu.
                                child: Text(
                                  PairingToken.forDisplay(_token!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: textMutedColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Kodu yenile.
                    //
                    // Ayrılırken erişimi kesmek listeden çıkarmakla oluyor ama
                    // eski QR ortada kalıyor. Bunu yenilemek onu da geçersiz
                    // kılar — kullanıcının kontrolünde olması gereken bir şey.
                    TextButton.icon(
                      onPressed: _rotating ? null : _rotate,
                      icon: _rotating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.autorenew, size: 18),
                      label: Text(context.tr('partner_qr_gen_rotate')),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        context.tr('partner_qr_gen_rotate_hint'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: textMutedColor),
                      ),
                    ),

                    // Partner kodu okutunca istek burada beliriyor: sahip
                    // QR'ı gösterirken onaylayabiliyor.
                    PairingRequestsSection(
                      key: ValueKey(_token),
                      remote: _remote,
                      pairing: _pairing,
                    ),

                    const SizedBox(height: 24),

                    // Share Button Alternative
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: _token!));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('partner_qr_gen_code_copied'),
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textMainColor,
                        side: BorderSide(color: context.tokens.border),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: Text(
                        context.tr('partner_qr_gen_copy_code'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.unavailable, required this.onRetry});

  final bool unavailable;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          key: const Key('partner_qr_failed'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 56, color: t.textMuted),
            const SizedBox(height: 16),
            Text(
              context.tr(
                unavailable ? 'partner_unavailable' : 'partner_qr_gen_failed',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5, color: t.text),
            ),
            if (!unavailable) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(context.tr('retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
