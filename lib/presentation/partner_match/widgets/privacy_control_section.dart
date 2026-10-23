import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/view_models/intimacy_view_model.dart';
import '../../../localization/app_localizations.dart';
import 'intimacy_consent.dart';
import 'partner_ui.dart';

/// Yakınlık durumu paylaşımının anahtarı.
///
/// Açmak açık rıza istiyor (bkz. [askIntimacyConsent]); kapatmak rızayı
/// geri alıyor ve sunucudaki paylaşılmış durumu siliyor. Önceden anahtar
/// varsayılan olarak açıktı, kapatmak da yalnızca sonraki gönderimleri
/// durduruyordu.
class PrivacyControlSection extends StatelessWidget {
  const PrivacyControlSection({super.key});

  Future<void> _toggle(BuildContext context, bool on) async {
    final vm = context.read<IntimacyViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final retractFailed = context.tr('partner_share_retract_failed');
    if (on) {
      if (await askIntimacyConsent(context)) await vm.startSharing();
      return;
    }
    if (!await vm.stopSharing()) {
      messenger.showSnackBar(SnackBar(content: Text(retractFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IntimacyViewModel>();
    final theme = Theme.of(context);
    final t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PartnerSectionTitle(context.tr('partner_match_privacy')),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('partner_match_allow_sharing'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('partner_match_allow_sharing_desc'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    key: const Key('partner_share_switch'),
                    value: vm.sharingOn,
                    onChanged: vm.isLoaded ? (v) => _toggle(context, v) : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('partner_match_encryption_notice'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.45,
                          color: t.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
