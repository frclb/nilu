import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import 'settings_surface.dart';

class SettingsItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  /// Başlığın altındaki ikinci satır (ör. tahmini doğum tarihi).
  final String? subtitle;

  /// Sağdaki ok yerine gösterilecek öğe (ör. bir anahtar).
  final Widget? trailing;

  SettingsItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });
}

/// Başlıklı ayar grubu: küçük büyük harfli etiket, altında beyaz kartta
/// simge kutulu satırlar.
class SettingsGroup extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;

  const SettingsGroup({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: AppSectionLabel(title),
        ),
        // Kenarlık açık temada `Colors.grey[100]` idi — beyaz yüzeye karşı
        // görünmüyordu ve grup zeminden ayrışmıyordu. Gölge de yoktu.
        SettingsCard(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _SettingsRow(item: items[i]),
                if (i != items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    // Simge kutusunun sağından başlıyor: satırlar simge
                    // sütunuyla birbirine bağlı görünsün.
                    indent: 68,
                    endIndent: 14,
                    color: AppCard.dividerColor(t),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.item});

  final SettingsItem item;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    // Satır ve sağdaki anahtar tek öğe: VoiceOver anahtarı ayrı ve
    // etiketsiz okuyordu ("anahtar, kapalı" — neyin anahtarı?).
    return MergeSemantics(
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                AppIconTile(
                  icon: item.icon,
                  color: item.iconColor,
                  background: item.iconBgColor,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: SettingsText.title(context)),
                      if (item.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle!,
                          style: SettingsText.subtitle(
                            context,
                          )?.copyWith(fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                item.trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: t.textFaint,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
