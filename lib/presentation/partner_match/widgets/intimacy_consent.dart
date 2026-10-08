import 'package:flutter/material.dart';

import '../../../design_system/app_theme.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';

/// Yakınlık durumunu partnerle paylaşmak için açık rıza.
///
/// Paylaşılan şey cinsel istek düzeyi ve sevgi ihtiyaçları: KVKK'da cinsel
/// hayata ilişkin, yani özel nitelikli kişisel veri. Bu tür veri ancak açık
/// rızayla işlenebiliyor ve rıza **bilgilendirilmiş** olmalı: ne gidiyor,
/// kime, nerede saklanıyor, nasıl geri alınıyor. Önceden paylaşım varsayılan
/// olarak açıktı ve hiçbiri sorulmuyordu.
///
/// Kullanıcı onaylarsa `true`.
Future<bool> askIntimacyConsent(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final t = ctx.tokens;
      final theme = Theme.of(ctx);
      Widget madde(IconData icon, String key) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ctx.tr(key),
                style: TextStyle(fontSize: 13, height: 1.45, color: t.text),
              ),
            ),
          ],
        ),
      );
      return AlertDialog(
        key: const Key('intimacy_consent_dialog'),
        title: Text(ctx.tr('consent_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              madde(Icons.favorite_border, 'consent_what'),
              madde(Icons.person_outline, 'consent_who'),
              madde(Icons.cloud_outlined, 'consent_where'),
              madde(Icons.shield_outlined, 'consent_special'),
              madde(Icons.undo, 'consent_withdraw'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            key: const Key('intimacy_consent_accept'),
            style: AppTheme.dialogAction(),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('consent_accept')),
          ),
        ],
      );
    },
  );
  return result ?? false;
}
