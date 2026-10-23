import 'package:flutter/material.dart';

import '../../../design_system/app_decor.dart';
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
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIconTile(icon: icon, size: 32, circle: true),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  ctx.tr(key),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    height: 1.45,
                    color: t.text,
                  ),
                ),
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
              madde(Icons.favorite_border_rounded, 'consent_what'),
              madde(Icons.person_outline_rounded, 'consent_who'),
              madde(Icons.cloud_outlined, 'consent_where'),
              madde(Icons.shield_outlined, 'consent_special'),
              madde(Icons.undo_rounded, 'consent_withdraw'),
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
