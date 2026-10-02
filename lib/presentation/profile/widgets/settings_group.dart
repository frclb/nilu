import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';

class SettingsItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  SettingsItem({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  });
}

class SettingsGroup extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;

  const SettingsGroup({super.key, required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Text(
            context.upper(title),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.tokens.textMuted,
              letterSpacing: 1.0,
            ),
          ),
        ),
        // Kenarlık açık temada `Colors.grey[100]` idi — beyaz yüzeye karşı
        // görünmüyordu ve grup zeminden ayrışmıyordu. Gölge de yoktu.
        Container(
          decoration: AppCard.decoration(context.tokens),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: item.onTap,
                      borderRadius: isLast
                          ? const BorderRadius.vertical(
                              bottom: Radius.circular(12),
                            )
                          : index == 0
                          ? const BorderRadius.vertical(
                              top: Radius.circular(12),
                            )
                          : BorderRadius.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? item.iconBgColor.withAlpha(12)
                                    : item.iconBgColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.icon,
                                color: item.iconColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: isDark
                                  ? context.tokens.textMuted
                                  : context.tokens.textFaint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: context.tokens.surfaceAlt,
                      indent: 72,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
