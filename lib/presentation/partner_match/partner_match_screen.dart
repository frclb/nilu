import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/route_names.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import 'partner_dashboard_screen.dart';
import 'widgets/connected_partner_card.dart';
import 'widgets/pairing_requests_section.dart';
import 'widgets/partner_match_app_bar.dart';
import 'widgets/partner_match_hero.dart';
import 'widgets/partner_unavailable_notice.dart';
import 'widgets/privacy_control_section.dart';
import 'widgets/shared_info_section.dart';

/// Partner sekmesi (sahip tarafı).
///
/// Üç hâli var: eşleşme sunucusu yok (Firebase yapılandırılmamış), bağlı
/// bir partner var, ya da davet. Önceden sunucu yokken de geçerli görünen
/// bir QR üretiliyordu ve bağlı kullanıcıya yine "davet et" gösteriliyordu.
class PartnerMatchScreen extends StatefulWidget {
  const PartnerMatchScreen({super.key, @visibleForTesting this.remote});

  final FirestoreDataSource? remote;

  @override
  State<PartnerMatchScreen> createState() => _PartnerMatchScreenState();
}

class _PartnerMatchScreenState extends State<PartnerMatchScreen> {
  late final FirestoreDataSource _remote =
      widget.remote ?? FirestoreDataSource();

  /// QR ekranından dönünce istek bölümü kodu yeniden okusun diye.
  int _generation = 0;

  Future<void> _invite() async {
    await context.pushNamed(RouteNames.partnerQrGen);
    if (mounted) setState(() => _generation++);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserViewModel>();
    if (user.isPartner) return const PartnerDashboardScreen();

    final t = context.tokens;
    final available = _remote.isAvailable;
    final connected = user.hasPartner;

    return Scaffold(
      backgroundColor: t.background,
      appBar: const PartnerMatchAppBar(),
      body: AppContentWidth(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (connected) ...[
                      const ConnectedPartnerCard(),
                      const SizedBox(height: 28),
                      const PrivacyControlSection(),
                      const SizedBox(height: 28),
                      const SharedInfoSection(),
                    ] else ...[
                      const PartnerMatchHero(),
                      if (!available)
                        const PartnerUnavailableNotice()
                      else
                        // Bekleyen istekler en üstte: erişimi vermek
                        // sahibin kararı.
                        PairingRequestsSection(
                          key: ValueKey(_generation),
                          remote: _remote,
                        ),
                      const SizedBox(height: 28),
                      const SharedInfoSection(),
                    ],
                  ],
                ),
              ),
            ),
            if (!connected && available)
              _InviteActions(onInvite: _invite, onHowItWorks: _howItWorks),
          ],
        ),
      ),
    );
  }

  void _howItWorks() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('partner_match_how_it_works')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Step(
                icon: Icons.qr_code_2_rounded,
                title: ctx.tr('partner_step_qr_title'),
                desc: ctx.tr('partner_step_qr_desc'),
              ),
              const SizedBox(height: 16),
              _Step(
                icon: Icons.qr_code_scanner_rounded,
                title: ctx.tr('partner_step_scan_title'),
                desc: ctx.tr('partner_step_scan_desc'),
              ),
              const SizedBox(height: 16),
              _Step(
                icon: Icons.favorite_border_rounded,
                title: ctx.tr('partner_step_track_title'),
                desc: ctx.tr('partner_step_track_desc'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.tr('got_it')),
          ),
        ],
      ),
    );
  }
}

class _InviteActions extends StatelessWidget {
  const _InviteActions({required this.onInvite, required this.onHowItWorks});

  final VoidCallback onInvite;
  final VoidCallback onHowItWorks;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      color: t.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppGradientButton(
            key: const Key('partner_invite'),
            label: context.tr('partner_match_invite_button'),
            icon: Icons.qr_code_2_rounded,
            onPressed: onInvite,
            height: 56,
            radius: AppRadius.pill,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('partner_scan'),
            onPressed: () => context.pushNamed(RouteNames.partnerScan),
            style: OutlinedButton.styleFrom(
              backgroundColor: t.surface,
              side: BorderSide(color: AppCard.borderColor(t)),
              minimumSize: const Size.fromHeight(56),
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
            label: Text(context.tr('partner_match_scan_button')),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: onHowItWorks,
              style: TextButton.styleFrom(
                foregroundColor: t.textMuted,
                minimumSize: const Size(0, 44),
              ),
              icon: const Icon(Icons.help_outline_rounded, size: 18),
              label: Text(
                context.tr('partner_match_how_it_works'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: t.textMuted,
                  decoration: TextDecoration.underline,
                  decorationColor: t.textFaint,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.title, required this.desc});

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconTile(icon: icon, size: 36, circle: true),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.45,
                  color: t.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
