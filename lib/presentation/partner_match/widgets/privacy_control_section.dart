import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/view_models/intimacy_view_model.dart';
import '../../../localization/app_localizations.dart';
import 'intimacy_consent.dart';

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
    final t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('partner_match_privacy'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: t.text,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: AppCard.decoration(t),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('partner_match_allow_sharing'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('partner_match_allow_sharing_desc'),
                      style: TextStyle(fontSize: 12, color: t.textMuted),
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
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.lock, size: 14, color: t.textFaint),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                context.tr('partner_match_encryption_notice'),
                style: TextStyle(fontSize: 12, height: 1.4, color: t.textFaint),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
