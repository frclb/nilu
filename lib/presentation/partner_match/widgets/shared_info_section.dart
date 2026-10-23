import 'package:flutter/material.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import 'partner_ui.dart';

/// Partnere gerçekte giden şeyler.
class SharedInfoSection extends StatelessWidget {
  const SharedInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PartnerSectionTitle(context.tr('partner_match_shared_info')),
        const SizedBox(height: 14),
        // Yalnızca gerçekten giden iki şey listeleniyor.
        //
        // Eskiden burada "Döngü Fazı — güncel döngü aşamanızı ve tahmini
        // tarihleri görür" ve "Ruh Hali Özeti" yazıyordu. İkisi de partnere
        // hiç gitmiyor. Kullanıcı bağlanma kararını tam bu ekranda veriyor;
        // vermediği bir izni verdiğini sanarak vermesi, gizlilik açısından
        // en kötü hâl.
        _InfoItem(
          icon: Icons.favorite_border_rounded,
          tint: t.flowTint,
          color: t.secondary,
          title: context.tr('partner_match_intimacy'),
          desc: context.tr('partner_match_intimacy_desc'),
        ),
        const SizedBox(height: 12),
        _InfoItem(
          icon: Icons.lightbulb_outline_rounded,
          tint: t.accentTint,
          color: t.accent,
          title: context.tr('partner_match_tips'),
          desc: context.tr('partner_match_tips_desc'),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.tint,
    required this.color,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color tint;
  final Color color;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(icon: icon, size: 48, background: tint, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: t.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
