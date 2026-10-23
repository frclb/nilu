import 'package:flutter/material.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';

/// Davet ekranının girişi: kalp halkası, başlık ve neyin paylaşıldığı.
class PartnerMatchHero extends StatelessWidget {
  const PartnerMatchHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final primary = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
      decoration: BoxDecoration(
        gradient: AppGradients.blush(context),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppCard.borderColor(t)),
        boxShadow: AppCard.shadow(t),
      ),
      child: Column(
        children: [
          const _HeartHalo(),
          const SizedBox(height: 22),
          Text(
            context.tr('partner_match_hero_title'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontSize: 30,
              height: 1.15,
              color: primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('partner_match_hero_desc'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.55,
              color: t.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Degrade halkanın içinde kalp; köşede küçük bir ışıltı.
class _HeartHalo extends StatelessWidget {
  const _HeartHalo();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 104,
      height: 104,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.mark(context),
        boxShadow: AppShadows.floating(context),
      ),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, color: t.surface),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 42, color: primary),
            Positioned(
              top: 22,
              right: 20,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: t.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
