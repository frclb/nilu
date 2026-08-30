import 'package:flutter/material.dart';
import '../../../design_system/app_card.dart';
import '../../../../localization/app_localizations.dart';
import '../../../design_system/app_colors.dart';

class PartnerMatchHero extends StatelessWidget {
  const PartnerMatchHero({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark
        ? Colors.white
        : AppColors.textMainSlate; // slate-900
    final descColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Column(
      children: [
        // Abstract Graphic
        Container(
          width: double.infinity,
          height: 200, // Roughly aspect-[4/3] depending on screen width
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withAlpha(25),
                theme.colorScheme.primary.withAlpha(12),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withAlpha(51)
                    : Colors.white.withAlpha(102),
                shape: BoxShape.circle,
                boxShadow: AppCard.shadow(),
              ),
              child: Icon(
                Icons.diversity_1, // close enough equivalent
                size: 60,
                color: isDark ? Colors.white : theme.colorScheme.primary,
              ),
            ),
          ),
        ),

        Text(
          context.tr('partner_match_hero_title'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: titleColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            context.tr('partner_match_hero_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: descColor, height: 1.5),
          ),
        ),
      ],
    );
  }
}
