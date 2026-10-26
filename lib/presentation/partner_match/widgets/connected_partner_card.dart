import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_snack.dart';
import '../../../design_system/app_theme.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/content_illustration.dart';
import '../../../domain/services/pairing_token.dart';
import '../../../domain/view_models/intimacy_view_model.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import 'partner_ui.dart';

/// Sahibin bağlı partneri ve erişimi kaldırma.
///
/// Önceden paylaşım ayarları ekranı sabit bir "Bağlı Partner • Aktif"
/// yazıyor ve partnerin adı yerine ham kimliğini gösteriyordu. Uygulama ad
/// toplamıyor; partneri tanımanın yolu iki ekranda da görünen doğrulama
/// kodu. Avatar da bu yüzden genel "Partner" etiketinin baş harfi.
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
    final snack = AppSnack.of(context);
    final done = context.tr('partner_remove_done');
    final failed = context.tr('partner_remove_failed');

    final ok = await user.removePartnerAccess();
    // Yeni bir partner bağlanırsa paylaşım yeniden rıza istemeli.
    if (ok) await intimacy.stopSharing();
    ok ? snack.success(done) : snack.error(failed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final partnerId = context.watch<UserViewModel>().partnerId ?? '';
    final code = PairingToken.confirmationCode(partnerId);

    return Container(
      key: const Key('connected_partner_card'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.blush(context),
        borderRadius: BorderRadius.circular(AppCard.radius),
        border: Border.all(color: AppCard.borderColor(t)),
        boxShadow: AppCard.shadow(t),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: InitialAvatar(
                  name: context.tr('partner_label'),
                  size: 52,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  context.tr('partner_connected_title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.favorite_rounded, size: 22, color: t.secondary),
            ],
          ),
          const SizedBox(height: 14),
          // Kod tek metnin içinde, kalın: partnerin ekranındakiyle
          // karşılaştırılacak şey bu.
          Text.rich(
            PartnerUi.emphasize(
              context.tr('partner_connected_code', params: {'code': code}),
              code,
              TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: t.text,
              ),
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: t.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: OutlinedButton.icon(
              key: const Key('partner_remove'),
              onPressed: () => _remove(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: t.danger,
                backgroundColor: t.danger.withAlpha(20),
                side: BorderSide(color: t.danger.withAlpha(70)),
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 18),
              ),
              icon: const Icon(Icons.link_off_rounded, size: 18),
              label: Text(context.tr('partner_share_stop_access')),
            ),
          ),
        ],
      ),
    );
  }
}
