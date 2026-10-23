import 'package:flutter/material.dart';

import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';
import '../widgets/profile_avatar_button.dart';
import 'widgets/partner_match_app_bar.dart';
import 'widgets/partner_ui.dart';

/// Partner rolündeki kullanıcı için genel rehber.
///
/// Önceden bu ekran tamamen sabit veriydi: "1. GÜN", "Menstruasyon
/// Dönemi", "Su ihtiyacı 2,5 L", "östrojen ve progesteron en düşük
/// noktada", "2 görev". Partnere döngü bilgisi hiç gönderilmiyor (bilerek);
/// ekran ise onun vücudu hakkında bilgi veriyormuş gibi konuşuyordu.
///
/// Şimdi her dönem için genel öneriler var ve ekran bunu açıkça söylüyor.
class PartnerSupportScreen extends StatelessWidget {
  const PartnerSupportScreen({super.key});

  static const List<(IconData, String, List<String>)> _sections = [
    (
      Icons.water_drop_outlined,
      'partner_guide_period_title',
      [
        'partner_guide_period_1',
        'partner_guide_period_2',
        'partner_guide_period_3',
      ],
    ),
    (
      Icons.cloud_outlined,
      'partner_guide_pms_title',
      ['partner_guide_pms_1', 'partner_guide_pms_2'],
    ),
    (
      Icons.favorite_border_rounded,
      'partner_guide_status_title',
      ['partner_guide_status_1', 'partner_guide_status_2'],
    ),
    (
      Icons.local_hospital_outlined,
      'partner_guide_doctor_title',
      ['partner_guide_doctor_1'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final on = theme.colorScheme.onPrimary;
    // Sekme kökü (partnerin "Rehber" sekmesi); ayrı rotadan açılırsa geri.
    final pushed = Navigator.of(context).canPop();

    // Her bölümün tonu: regl gülü, PMS menekşe, paylaşılan durum böğürtlen,
    // hekim uyarısı tehlike rengi.
    final tones = <(Color, Color)>[
      (t.flowTint, t.flowText),
      (t.ovulationTint, t.ovulationText),
      (t.secondaryTint, t.secondary),
      (t.danger.withAlpha(28), t.danger),
    ];

    return Scaffold(
      backgroundColor: t.background,
      appBar: pushed
          ? const PartnerMatchAppBar(
              titleKey: 'partner_support_title',
              showSettings: false,
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!pushed)
              AppBrandBar(
                title: context.tr('partner_nav_support'),
                trailing: const ProfileAvatarButton(),
              ),
            Expanded(
              child: AppContentWidth(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // Giriş: rehberin neye dayandığı ve neye dayanmadığı.
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: PartnerUi.plum(context),
                        borderRadius: BorderRadius.circular(AppCard.radius),
                        boxShadow: AppShadows.floating(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: on.withAlpha(36),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.privacy_tip_outlined,
                              size: 18,
                              color: on,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            context.tr('partner_guide_intro'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontSize: 20,
                              height: 1.35,
                              color: on,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (final (i, (icon, titleKey, items))
                        in _sections.indexed) ...[
                      _Section(
                        icon: icon,
                        title: context.tr(titleKey),
                        items: [for (final k in items) context.tr(k)],
                        tint: tones[i].$1,
                        color: tones[i].$2,
                        // Hekim bölümü bir uyarı: maddesi tehlike tülünde.
                        alert: titleKey == 'partner_guide_doctor_title',
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.items,
    required this.tint,
    required this.color,
    required this.alert,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final Color tint;
  final Color color;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppIconTile(
                icon: icon,
                size: 48,
                circle: true,
                background: tint,
                color: color,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final (i, item) in items.indexed)
            Container(
              margin: EdgeInsets.only(top: i == 0 ? 0 : 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: alert ? tint : t.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (alert)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: color,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: t.text,
                      ),
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
