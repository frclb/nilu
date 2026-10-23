import 'package:flutter/material.dart';

import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
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
/// Teşhis koymuyor, yönlendiriyor. İşaretlenenler hiçbir yere kaydedilmiyor
/// ve hekim özetine eklenmiyor; ekran kapanınca gidiyor.
class HeavyBleedingScreen extends StatefulWidget {
  const HeavyBleedingScreen({super.key});

  @override
  State<HeavyBleedingScreen> createState() => _HeavyBleedingScreenState();
}

class _HeavyBleedingScreenState extends State<HeavyBleedingScreen> {
  final Set<HeavyBleedingSign> _selected = {};

  static IconData _iconOf(HeavyBleedingSign sign) => switch (sign) {
    HeavyBleedingSign.frequentChanges => Icons.timer_outlined,
    HeavyBleedingSign.doubleProtection => Icons.layers_outlined,
    HeavyBleedingSign.longerThanSevenDays => Icons.calendar_month_outlined,
    HeavyBleedingSign.largeClots => Icons.grain,
    HeavyBleedingSign.floodingThrough => Icons.water_drop_outlined,
    HeavyBleedingSign.limitsDailyLife => Icons.bed_outlined,
    HeavyBleedingSign.tirednessOrBreathlessness => Icons.battery_alert_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final result = HeavyBleedingCheck.evaluate(_selected);
    final demir = ArticleCatalog.byKey('library_article_iron');

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(
          context.tr('bleeding_check_title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 21,
            color: t.text,
          ),
        ),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIconTile(
                      icon: Icons.monitor_heart_outlined,
                      circle: true,
                      background: t.brandTint,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.tr('bleeding_check_intro'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.55,
                          color: t.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              for (final sign in HeavyBleedingCheck.allSigns)
                _SignTile(
                  icon: _iconOf(sign),
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

              const SizedBox(height: 16),

              if (result.shouldSeeClinician) ...[
                _Callout(
                  icon: Icons.medical_information,
                  title: context.tr('bleeding_check_result_title'),
                  body: context.tr('bleeding_check_result_body'),
                  background: t.brandTint,
                  iconColor: scheme.onPrimary,
                  iconBackground: scheme.primary,
                  titleColor: scheme.primary,
                ),
                // Demir yazısı katalogdan anahtarla bulunuyor. Anahtar
                // değişirse bağlantı sessizce kaybolmalı — eskiden
                // `firstWhere` fırlatıyor, ekran çöküyordu.
                if (result.suggestsIronCheck && demir != null) ...[
                  const SizedBox(height: 12),
                  _Callout(
                    icon: Icons.bloodtype,
                    title: context.tr('bleeding_check_iron_title'),
                    body: context.tr('bleeding_check_iron_body'),
                    background: t.accentTint,
                    iconColor: t.accent,
                    iconBackground: t.surface,
                    titleColor: t.text,
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
                  background: t.surfaceAlt,
                  iconColor: t.textMuted,
                  iconBackground: t.surface,
                  titleColor: t.text,
                ),

              const SizedBox(height: 24),
              Text(
                context.tr('article_disclaimer'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  height: 1.55,
                  color: t.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'NHS — Heavy periods',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
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
    required this.icon,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(AppRadius.md);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        checked: selected,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: AppShadows.soft(context),
          ),
          child: Material(
            color: selected ? t.brandTint : t.surface,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: () => onChanged(!selected),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(
                    color: selected
                        ? scheme.primary.withAlpha(90)
                        : AppCard.borderColor(t),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 20,
                      color: selected ? t.secondary : t.textMuted,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          height: 1.45,
                          color: t.text,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? scheme.primary : t.surfaceAlt,
                        border: selected ? null : Border.all(color: t.border),
                      ),
                      child: selected
                          ? Icon(Icons.check, size: 17, color: scheme.onPrimary)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
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
    required this.background,
    required this.iconColor,
    required this.iconBackground,
    required this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color background;
  final Color iconColor;
  final Color iconBackground;
  final Color titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconTile(
                icon: icon,
                size: 38,
                circle: true,
                color: iconColor,
                background: iconBackground,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 19,
                        height: 1.25,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        height: 1.55,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 22, color: t.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
