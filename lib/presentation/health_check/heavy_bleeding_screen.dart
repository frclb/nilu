import 'package:flutter/material.dart';

import '../../design_system/app_tokens.dart';
import '../../domain/models/article.dart';
import '../../domain/services/heavy_bleeding_check.dart';
import '../../localization/app_localizations.dart';
import '../health_library/article_screen.dart';
import '../../design_system/app_layout.dart';

/// Yoğun kanama kendini değerlendirme aracı.
///
/// Uygulama zaten akış yoğunluğunu ("hafif/orta/ağır") soruyordu ama bu tek
/// başına hiçbir şey söylemiyor: "ağır" herkes için farklı bir şey. NHS'in
/// somut ölçütleri kullanıcıya karşılaştırabileceği bir zemin veriyor.
///
/// Teşhis koymuyor, yönlendiriyor.
class HeavyBleedingScreen extends StatefulWidget {
  const HeavyBleedingScreen({super.key});

  @override
  State<HeavyBleedingScreen> createState() => _HeavyBleedingScreenState();
}

class _HeavyBleedingScreenState extends State<HeavyBleedingScreen> {
  final Set<HeavyBleedingSign> _selected = {};

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final result = HeavyBleedingCheck.evaluate(_selected);
    final demir = ArticleCatalog.byKey('library_article_iron');

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(context.tr('bleeding_check_title')),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                context.tr('bleeding_check_intro'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  height: 1.6,
                  color: t.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              for (final sign in HeavyBleedingCheck.allSigns)
                _SignTile(
                  label: context.tr(HeavyBleedingResult.signKey(sign)),
                  selected: _selected.contains(sign),
                  onChanged: (v) => setState(() {
                    if (v) {
                      _selected.add(sign);
                    } else {
                      _selected.remove(sign);
                    }
                  }),
                ),

              const SizedBox(height: 24),

              if (result.shouldSeeClinician) ...[
                _Callout(
                  icon: Icons.medical_information_outlined,
                  title: context.tr('bleeding_check_result_title'),
                  body: context.tr('bleeding_check_result_body'),
                  color: theme.colorScheme.primary,
                ),
                // Demir yazısı katalogdan anahtarla bulunuyor. Anahtar
                // değişirse bağlantı sessizce kaybolmalı — eskiden
                // `firstWhere` fırlatıyor, ekran çöküyordu.
                if (result.suggestsIronCheck && demir != null) ...[
                  const SizedBox(height: 12),
                  _Callout(
                    icon: Icons.bloodtype_outlined,
                    title: context.tr('bleeding_check_iron_title'),
                    body: context.tr('bleeding_check_iron_body'),
                    color: t.warning,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ArticleScreen(article: demir),
                      ),
                    ),
                  ),
                ],
              ] else
                _Callout(
                  icon: Icons.info_outline,
                  title: context.tr('bleeding_check_none_title'),
                  body: context.tr('bleeding_check_none_body'),
                  color: t.textMuted,
                ),

              const SizedBox(height: 20),
              Text(
                context.tr('article_disclaimer'),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  height: 1.55,
                  color: t.textFaint,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'NHS — Heavy periods',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  color: t.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignTile extends StatelessWidget {
  const _SignTile({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!selected),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? t.brandTint : t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : t.border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                size: 22,
                color: selected ? theme.colorScheme.primary : t.textFaint,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    height: 1.5,
                    color: t.text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(64)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      height: 1.55,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 20, color: color),
          ],
        ),
      ),
    );
  }
}
