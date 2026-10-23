import 'package:flutter/material.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';

/// Eşleşme sunucusu yokken (Firebase yapılandırılmamış) gösterilen not.
///
/// Önceden bu durumda da geçerli görünen bir QR üretiliyor, paylaşım
/// "gönderildi" diyordu; kodu okutan kişi ise "geçersiz kod" görüyordu.
class PartnerUnavailableNotice extends StatelessWidget {
  const PartnerUnavailableNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      key: const Key('partner_unavailable'),
      padding: const EdgeInsets.only(top: 16),
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconTile(
              icon: Icons.cloud_off_outlined,
              background: t.surfaceAlt,
              color: t.textMuted,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                context.tr('partner_unavailable'),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(height: 1.45, color: t.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
