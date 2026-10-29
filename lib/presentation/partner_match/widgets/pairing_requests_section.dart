import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/datasources/remote/firestore_datasource.dart';
import '../../../data/repositories/pairing_repository.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_snack.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/services/pairing_token.dart';
import '../../../domain/view_models/intimacy_view_model.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import 'approve_partner_sheet.dart';
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

  /// İsteklerin dinlendiği kodlar: QR kodu ve açık davet bağlantısı.
  /// Akışlar bir kez kuruluyor; her çizimde yenisi yeniden abone olurdu.
  Map<String, Stream<QuerySnapshot<Map<String, dynamic>>>> _streams = {};

  /// Açık davet bağlantısının kodu; onay ya da retten sonra kapanıyor.
  String? _invite;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  /// Yalnızca daha önce paylaşılmış kodlar: sekmeyi açmak tek başına
  /// kimlik ve kod üretip sunucuya yazmamalı.
  Future<void> _loadToken() async {
    final token = await _pairing.existingToken();
    final invite = await _pairing.existingInvite();
    if (!mounted) return;
    setState(() {
      _invite = invite;
      _streams = {
        for (final t in [?token, ?invite]) t: _remote.watchPairingRequests(t),
      };
    });
  }

  /// Davet bağlantısının işi bitti: tek kullanımlık, bir daha açılmasın.
  Future<void> _closeInviteIfUsed(String token) async {
    if (token != _invite) return;
    await _pairing.closeInvite(token);
  }

  /// Önce sahip partnerin neyi göreceğini görüyor ve seçiyor; sonra
  /// onay ve — seçtiyse — paylaşım birlikte.
  ///
  /// Önceden onay erişimi veriyor ama hiçbir şey göndermiyordu; partner
  /// sahip ayrıca paylaşana kadar boş bir ekran gördü.
  Future<void> _approve(String requesterUid, String token) async {
    final userViewModel = context.read<UserViewModel>();
    final intimacy = context.read<IntimacyViewModel>();
    final snack = AppSnack.of(context);
    final approved = context.tr('partner_request_approved');
    final approvedShared = context.tr('partner_request_approved_shared');
    final approvedEmpty = context.tr('partner_request_approved_empty');
    final failed = context.tr('partner_request_failed');
    final shareFailed = context.tr('intimacy_share_failed_msg');

    final karar = await showApprovePartnerSheet(
      context,
      code: PairingToken.confirmationCode(requesterUid),
      sexualDesire: intimacy.selectedSexualDesire,
      affectionNeeds: intimacy.selectedAffectionNeeds,
      consentGiven: intimacy.sharingOn,
    );
    if (karar == null || !mounted) return;

    setState(() => _busy.add(requesterUid));
    final ok = await userViewModel.approvePartnerRequest(
      requesterUid,
      token: token,
    );
    // Onaydan sonra bu bölüm ağaçtan kalkabilir (ekran "bağlı" hâline
    // geçiyor); paylaşım ona bağlı değil.
    if (mounted) setState(() => _busy.remove(requesterUid));
    if (!ok) {
      snack.error(failed);
      return;
    }
    await _closeInviteIfUsed(token);

    if (!karar.share) {
      // Daha önce verilmiş bir rıza açık kalmasın: "paylaşmadan" dendi.
      if (intimacy.sharingOn) await intimacy.stopSharing();
      snack.success(approved);
      return;
    }
    final myId = userViewModel.myId;
    final sent =
        myId != null &&
        await intimacy.approveAndShare(
          myId,
          sexualDesire: karar.sexualDesire,
          affectionNeeds: karar.affectionNeeds,
        );
    if (!sent) {
      snack.error(shareFailed);
    } else if (karar.sexualDesire == null && karar.affectionNeeds.isEmpty) {
      snack.success(approvedEmpty);
    } else {
      snack.success(approvedShared);
    }
  }

  Future<void> _reject(String requesterUid, String token) async {
    setState(() => _busy.add(requesterUid));
    await _remote.clearPairingRequest(token, requesterUid);
    await _closeInviteIfUsed(token);
    if (!mounted) return;
    setState(() => _busy.remove(requesterUid));
  }

  @override
  Widget build(BuildContext context) =>
      _watch(_streams.entries.toList(), const []);

  /// Her kodun akışını iç içe dinler, istekleri (kod, istekte bulunan)
  /// olarak toplar.
  Widget _watch(
    List<MapEntry<String, Stream<QuerySnapshot<Map<String, dynamic>>>>> kalan,
    List<(String, String)> istekler,
  ) {
    if (kalan.isEmpty) return _list(istekler);
    final MapEntry(key: token, value: stream) = kalan.first;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? const [];
        return _watch(kalan.sublist(1), [
          ...istekler,
          for (final d in docs) (token, d.id),
        ]);
      },
    );
  }

  Widget _list(List<(String, String)> docs) {
    return Builder(
      builder: (context) {
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
              for (final (token, uid) in docs)
                _RequestTile(
                  requesterUid: uid,
                  busy: _busy.contains(uid),
                  onApprove: () => _approve(uid, token),
                  onReject: () => _reject(uid, token),
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
