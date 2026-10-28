import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../data/repositories/pairing_repository.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/pairing_token.dart';
import 'widgets/pairing_requests_section.dart';
import 'widgets/partner_match_app_bar.dart';
import 'widgets/partner_sign_in_required.dart';

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

  /// Hesap yok: eşleşme kodu Apple ya da Google ile girişten sonra.
  bool _needsAccount = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _failed = false;
      _needsAccount = false;
    });
    if (!_remote.isAvailable) {
      setState(() => _failed = true);
      return;
    }
    // Kimlik üretimi tek bir yerde: UserViewModel.ensureMyId().
    final id = await context.read<UserViewModel>().ensureMyId();
    if (!mounted) return;
    if (id == null) {
      setState(() => _needsAccount = true);
      return;
    }
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
    final token = id == null ? null : await _pairing.rotate(id);
    if (!mounted) return;
    final snack = AppSnack.of(context);
    final failed = context.tr('partner_qr_gen_failed');
    setState(() {
      // Yenilenemezse eski kod geçerli kalıyor; ekran onu göstermeye devam
      // ediyor.
      _token = token ?? _token;
      _rotating = false;
    });
    if (token == null) {
      snack.error(failed);
    }
    // Onay bildirimi kaldırıldı: QR ile kodun kendisi zaten gözle görülür
    // biçimde değişiyor, bildirim ise "Eşleşme Kodunu Kopyala" düğmesinin
    // üstüne binip (390×844'te düğme 789, bildirim 780–844) yeni kodu
    // kopyalamayı dört saniye engelliyordu.
    //
    // Kopyalama bildirimi duruyor: panoya yazmanın ekranda başka bir izi yok.
  }

  Future<void> _copy() async {
    final copied = context.tr('partner_qr_gen_code_copied');
    final snack = AppSnack.of(context);
    await Clipboard.setData(ClipboardData(text: _token!));
    if (!mounted) return;
    snack.show(copied);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: t.background,
      appBar: const PartnerMatchAppBar(
        titleKey: 'partner_qr_gen_title',
        showSettings: false,
      ),
      body: AppContentWidth(
        child: _needsAccount
            ? PartnerSignInRequired(onSignedIn: _load)
            : _failed
            ? _Failed(unavailable: !_remote.isAvailable, onRetry: _load)
            : _token == null
            ? Center(child: CircularProgressIndicator(color: primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('partner_qr_gen_header'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 30,
                        height: 1.15,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('partner_qr_gen_desc'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                        color: t.textMuted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _QrCard(
                      token: _token!,
                      rotating: _rotating,
                      onRotate: _rotate,
                      onCopy: _copy,
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: _copy,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: Text(context.tr('partner_qr_gen_copy_code')),
                    ),

                    // Partner kodu okutunca istek burada beliriyor: sahip
                    // QR'ı gösterirken onaylayabiliyor.
                    PairingRequestsSection(
                      key: ValueKey(_token),
                      remote: _remote,
                      pairing: _pairing,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// QR, elle yazılacak kod ve yenileme — tek kartta.
class _QrCard extends StatelessWidget {
  const _QrCard({
    required this.token,
    required this.rotating,
    required this.onRotate,
    required this.onCopy,
  });

  final String token;
  final bool rotating;
  final VoidCallback onRotate;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppCard.borderColor(t)),
        boxShadow: AppShadows.floating(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppCard.borderColor(t)),
              ),
              child: QrImageView(
                data: token,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.transparent,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: t.text,
                ),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: t.text,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Kodun tamamı gösteriliyor: kamera çalışmadığında elle
          // yazılabilmeli. Kısaltılmış bir parça hiçbir işe yaramıyordu.
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 4, 4),
            decoration: BoxDecoration(
              color: t.brandTint,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      PairingToken.forDisplay(token),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.2,
                        color: t.text,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.tr('partner_qr_gen_copy_code'),
                  onPressed: onCopy,
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Kodu yenile.
          //
          // Ayrılırken erişimi kesmek listeden çıkarmakla oluyor ama eski QR
          // ortada kalıyor. Bunu yenilemek onu da geçersiz kılar —
          // kullanıcının kontrolünde olması gereken bir şey.
          Center(
            child: TextButton.icon(
              onPressed: rotating ? null : onRotate,
              icon: rotating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.autorenew_rounded, size: 18),
              label: Text(context.tr('partner_qr_gen_rotate')),
              style: TextButton.styleFrom(
                foregroundColor: t.secondary,
                minimumSize: const Size(0, 44),
              ),
            ),
          ),
          Text(
            context.tr('partner_qr_gen_rotate_hint'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.45,
              color: t.textMuted,
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          key: const Key('partner_qr_failed'),
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconTile(
              icon: Icons.cloud_off_outlined,
              size: 80,
              circle: true,
              background: t.surfaceAlt,
              color: t.textMuted,
            ),
            const SizedBox(height: 20),
            Text(
              context.tr(
                unavailable ? 'partner_unavailable' : 'partner_qr_gen_failed',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: t.text,
              ),
            ),
            if (!unavailable) ...[
              const SizedBox(height: 20),
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
