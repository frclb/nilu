import 'package:flutter/material.dart';

import '../../../design_system/app_card.dart';
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
    return Container(
      key: const Key('partner_unavailable'),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppCard.decoration(t),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: t.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('partner_unavailable'),
              style: TextStyle(fontSize: 13, height: 1.45, color: t.text),
            ),
          ),
        ],
      ),
    );
  }
}
