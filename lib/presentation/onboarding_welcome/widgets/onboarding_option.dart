import 'package:flutter/material.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';

/// Kurulumdaki dokununca ilerleyen seçenek kartı.
///
/// Beyaz kart, solda renkli simge dairesi, sağda küçük ok. Seçili durumu
/// yok: dokunmak seçmek ve ilerlemek demek, ayrı bir "Devam" fazladan bir
/// dokunuş olurdu.
class OnboardingOption extends StatelessWidget {
  const OnboardingOption({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
    this.iconColor,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  /// Simge ve zemini. Verilmezse marka rengi ve tülü.
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final renk = iconColor ?? theme.colorScheme.primary;
    final radius = BorderRadius.circular(AppCard.radius);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: DecoratedBox(
        decoration: AppCard.decoration(t),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBackground ?? t.brandTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: renk, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: t.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                            color: t.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: t.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
