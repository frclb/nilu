import 'package:flutter/material.dart';

import '../../design_system/app_card.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';

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
    (Icons.water_drop_outlined, 'partner_guide_period_title', [
      'partner_guide_period_1',
      'partner_guide_period_2',
      'partner_guide_period_3',
    ]),
    (Icons.cloud_outlined, 'partner_guide_pms_title', [
      'partner_guide_pms_1',
      'partner_guide_pms_2',
    ]),
    (Icons.favorite_border, 'partner_guide_status_title', [
      'partner_guide_status_1',
      'partner_guide_status_2',
    ]),
    (Icons.local_hospital_outlined, 'partner_guide_doctor_title', [
      'partner_guide_doctor_1',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          context.tr('partner_support_title'),
          style: TextStyle(
            color: t.text,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              context.tr('partner_guide_intro'),
              style: TextStyle(fontSize: 14, height: 1.5, color: t.textMuted),
            ),
            const SizedBox(height: 20),
            for (final (icon, titleKey, items) in _sections) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: AppCard.decoration(t),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, color: primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr(titleKey),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: t.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.tr(item),
                                style: TextStyle(
                                  fontSize: 14,
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
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}
