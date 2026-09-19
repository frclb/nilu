import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../../localization/app_localizations.dart';

class SharedInfoSection extends StatelessWidget {
  const SharedInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor = context.tokens.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('partner_match_shared_info'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: headerColor,
              ),
            ),
            Icon(Icons.info, color: context.tokens.textFaint, size: 20),
          ],
        ),
        const SizedBox(height: 16),
        // Yalnızca gerçekten giden iki şey listeleniyor.
        //
        // Eskiden burada "Döngü Fazı — güncel döngü aşamanızı ve tahmini
        // tarihleri görür" ve "Ruh Hali Özeti" yazıyordu. İkisi de partnere
        // hiç gitmiyor. Kullanıcı bağlanma kararını tam bu ekranda veriyor;
        // vermediği bir izni verdiğini sanarak vermesi, gizlilik açısından
        // en kötü hâl.
        _buildInfoItem(
          context,
          Icons.favorite_border,
          context.tr('partner_match_intimacy'),
          context.tr('partner_match_intimacy_desc'),
          isDark,
          theme,
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          Icons.lightbulb,
          context.tr('partner_match_tips'),
          context.tr('partner_match_tips_desc'),
          isDark,
          theme,
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
    bool isDark,
    ThemeData theme,
  ) {
    final iconBg = theme.colorScheme.primary.withAlpha(25);
    final titleColor = context.tokens.text;
    final descColor = context.tokens.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCard.decoration(context.tokens),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 12, color: descColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
