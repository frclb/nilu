import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/services/pairing_token.dart';
import '../../../domain/view_models/intimacy_view_model.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';

/// Sahibin bağlı partneri ve erişimi kaldırma.
///
/// Önceden paylaşım ayarları ekranı sabit bir "Bağlı Partner • Aktif"
/// yazıyor ve partnerin adı yerine ham kimliğini gösteriyordu. Uygulama ad
/// toplamıyor; partneri tanımanın yolu iki ekranda da görünen doğrulama
/// kodu.
class ConnectedPartnerCard extends StatelessWidget {
  const ConnectedPartnerCard({super.key});

  Future<void> _remove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('partner_remove_title')),
        content: Text(ctx.tr('partner_remove_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            key: const Key('partner_remove_confirm'),
            style: AppTheme.dialogAction().copyWith(
              backgroundColor: WidgetStatePropertyAll(ctx.tokens.danger),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('partner_share_stop_access')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final user = context.read<UserViewModel>();
    final intimacy = context.read<IntimacyViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final done = context.tr('partner_remove_done');
    final failed = context.tr('partner_remove_failed');

    final ok = await user.removePartnerAccess();
    // Yeni bir partner bağlanırsa paylaşım yeniden rıza istemeli.
    if (ok) await intimacy.stopSharing();
    messenger.showSnackBar(SnackBar(content: Text(ok ? done : failed)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    final partnerId = context.watch<UserViewModel>().partnerId ?? '';

    return Container(
      key: const Key('connected_partner_card'),
      padding: const EdgeInsets.all(20),
      decoration: AppCard.decoration(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr('partner_connected_title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: t.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'partner_connected_code',
              params: {'code': PairingToken.confirmationCode(partnerId)},
            ),
            style: TextStyle(fontSize: 13, height: 1.4, color: t.textMuted),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('partner_remove'),
            onPressed: () => _remove(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: t.danger,
              side: BorderSide(color: t.danger.withAlpha(127)),
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.link_off, size: 18),
            label: Text(context.tr('partner_share_stop_access')),
          ),
        ],
      ),
    );
  }
}
