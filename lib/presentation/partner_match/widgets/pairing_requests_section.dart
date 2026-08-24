import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/datasources/remote/firestore_datasource.dart';
import '../../../data/repositories/pairing_repository.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';

/// Bekleyen eşleştirme istekleri ve onayları.
///
/// Erişimi vermeye yalnızca **sahip** yetkili. Kodu okuyan taraf istek
/// bırakıyor, ama sahip onaylayana kadar hiçbir şey okuyamıyor.
///
/// Önceki modelde okuyan taraf kendini doğrudan bağlıyordu; erişimi verenin
/// sahip olmaması, ayrılıktan sonra erişimin kesilememesinin de sebebiydi.
class PairingRequestsSection extends StatefulWidget {
  const PairingRequestsSection({super.key});

  @override
  State<PairingRequestsSection> createState() => _PairingRequestsSectionState();
}

class _PairingRequestsSectionState extends State<PairingRequestsSection> {
  final PairingRepository _pairing = PairingRepository();
  final FirestoreDataSource _remote = FirestoreDataSource();

  String? _token;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final id = await context.read<UserViewModel>().ensureMyId();
    final token = await _pairing.currentToken(id);
    if (!mounted) return;
    setState(() => _token = token);
  }

  Future<void> _approve(String requesterUid) async {
    final userViewModel = context.read<UserViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final approved = context.tr('partner_request_approved');

    setState(() => _busy.add(requesterUid));
    final myId = await userViewModel.ensureMyId();
    await _remote.approvePartner(myId, requesterUid);
    await userViewModel.setPartnerState(
      isPartner: false,
      partnerId: requesterUid,
    );
    await _remote.clearPairingRequest(_token!, requesterUid);
    if (!mounted) return;
    setState(() => _busy.remove(requesterUid));
    messenger.showSnackBar(SnackBar(content: Text(approved)));
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
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('partner_requests_title'),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('partner_requests_hint'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  height: 1.5,
                  color: t.textMuted,
                ),
              ),
              const SizedBox(height: 12),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.border),
      ),
      child: Row(
        children: [
          Icon(Icons.person_add_alt, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              // Kimlik dışında gösterecek bir şey yok: uygulama isim
              // toplamıyor. Kısaltılmış kimlik en azından iki farklı isteği
              // ayırt etmeye yetiyor.
              requesterUid.length > 8
                  ? '${requesterUid.substring(0, 8)}…'
                  : requesterUid,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else ...[
            TextButton(
              onPressed: onReject,
              child: Text(context.tr('partner_request_reject')),
            ),
            FilledButton(
              onPressed: onApprove,
              child: Text(context.tr('partner_request_approve')),
            ),
          ],
        ],
      ),
    );
  }
}
