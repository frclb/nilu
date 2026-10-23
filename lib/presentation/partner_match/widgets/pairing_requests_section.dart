import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/datasources/remote/firestore_datasource.dart';
import '../../../data/repositories/pairing_repository.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/services/pairing_token.dart';
import '../../../domain/view_models/intimacy_view_model.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import 'intimacy_consent.dart';
import 'partner_ui.dart';

/// Bekleyen eşleştirme istekleri ve onayları.
///
/// Erişimi vermeye yalnızca **sahip** yetkili. Kodu okuyan taraf istek
/// bırakıyor, ama sahip onaylayana kadar hiçbir şey okuyamıyor.
///
/// Önceki modelde okuyan taraf kendini doğrudan bağlıyordu; erişimi verenin
/// sahip olmaması, ayrılıktan sonra erişimin kesilememesinin de sebebiydi.
class PairingRequestsSection extends StatefulWidget {
  const PairingRequestsSection({super.key, this.remote, this.pairing});

  final FirestoreDataSource? remote;
  final PairingRepository? pairing;

  @override
  State<PairingRequestsSection> createState() => _PairingRequestsSectionState();
}

class _PairingRequestsSectionState extends State<PairingRequestsSection> {
  late final FirestoreDataSource _remote =
      widget.remote ?? FirestoreDataSource();
  late final PairingRepository _pairing =
      widget.pairing ?? PairingRepository(remote: _remote);

  String? _token;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  /// Yalnızca daha önce paylaşılmış bir kod varsa: sekmeyi açmak tek
  /// başına kimlik ve kod üretip sunucuya yazmamalı.
  Future<void> _loadToken() async {
    final token = await _pairing.existingToken();
    if (!mounted) return;
    setState(() => _token = token);
  }

  Future<void> _approve(String requesterUid) async {
    final userViewModel = context.read<UserViewModel>();
    final intimacy = context.read<IntimacyViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final approved = context.tr('partner_request_approved');
    final failed = context.tr('partner_request_failed');

    setState(() => _busy.add(requesterUid));
    final ok = await userViewModel.approvePartnerRequest(
      requesterUid,
      token: _token!,
    );
    if (!mounted) return;
    setState(() => _busy.remove(requesterUid));
    messenger.showSnackBar(SnackBar(content: Text(ok ? approved : failed)));
    // Onay erişimi veriyor ama paylaşımı başlatmıyor: paylaşım ayrı bir
    // açık rıza istiyor.
    if (ok && !intimacy.sharingOn && await askIntimacyConsent(context)) {
      await intimacy.startSharing();
    }
  }

  Future<void> _reject(String requesterUid) async {
    setState(() => _busy.add(requesterUid));
    await _remote.clearPairingRequest(_token!, requesterUid);
    if (!mounted) return;
    setState(() => _busy.remove(requesterUid));
  }

  @override
  Widget build(BuildContext context) {
    final token = _token;
    if (token == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _remote.watchPairingRequests(token),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();

        final t = context.tokens;
        final theme = Theme.of(context);

        return Padding(
          padding: const EdgeInsets.only(top: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PartnerSectionTitle(
                context.tr('partner_requests_title'),
                trailing: AppTag(
                  label: '${docs.length}',
                  background: t.secondary,
                  foreground: theme.colorScheme.onSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('partner_requests_hint'),
                style: theme.textTheme.bodyMedium?.copyWith(color: t.textMuted),
              ),
              const SizedBox(height: 14),
              for (final doc in docs)
                _RequestTile(
                  requesterUid: doc.id,
                  busy: _busy.contains(doc.id),
                  onApprove: () => _approve(doc.id),
                  onReject: () => _reject(doc.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.requesterUid,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final String requesterUid;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final code = PairingToken.confirmationCode(requesterUid);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AppIconTile(
                      icon: Icons.person_outline_rounded,
                      size: 52,
                      background: t.brandTint,
                    ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: t.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: t.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text.rich(
                    // Uygulama isim toplamıyor. Önceden kısaltılmış bir
                    // kimlik gösteriliyordu ("k3Jd9QzL…") ve sahip isteği
                    // kimin gönderdiğini ayırt edemiyordu. Aynı dört haneli
                    // kod partnerin ekranında da yazıyor: eşleşiyorsa doğru
                    // kişi.
                    PartnerUi.emphasize(
                      context.tr(
                        'partner_request_code',
                        params: {'code': code},
                      ),
                      code,
                      theme.textTheme.titleLarge!.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: t.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (busy)
              const Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: onReject,
                    style: TextButton.styleFrom(
                      foregroundColor: t.textMuted,
                      minimumSize: const Size(64, 44),
                    ),
                    child: Text(context.tr('partner_request_reject')),
                  ),
                  FilledButton.icon(
                    onPressed: onApprove,
                    // Temanın tam genişlik asgarisi satırda taşırdı.
                    style: AppTheme.dialogAction(),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(context.tr('partner_request_approve')),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
