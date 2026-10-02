import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';

/// Geçmiş gebelikler.
///
/// Gebelik bitince kayıt silinmiyordu (sonlandırma ekranı "geçmişte kalır"
/// diyor) ama bir daha görülemiyordu. Burası bilinçli olarak açılan yer:
/// takvimde ve panoda kayıpla biten gebelikler anılmıyor (bkz.
/// `PregnancyCalendar`).
///
/// Nasıl bittiği yalnızca kullanıcı belirttiyse yazıyor; "belirtmek
/// istemiyorum" diyene burada da bir etiket konmuyor.
class PastPregnanciesScreen extends StatelessWidget {
  const PastPregnanciesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final gecmis = context.watch<PregnancyViewModel>().pastPregnancies;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(context.tr('past_preg_title')),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                context.tr(
                  gecmis.isEmpty ? 'past_preg_empty' : 'past_preg_list_intro',
                ),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: t.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              for (final g in gecmis) ...[
                _Kart(gebelik: g),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Kart extends StatelessWidget {
  const _Kart({required this.gebelik});

  final Pregnancy gebelik;

  /// "Ağustos 2025 – Mart 2026": bir gebelik iki takvim yılına yayılıyor,
  /// ay ve yıl ikisini birbirinden ayırmaya yetiyor.
  String _aralik(BuildContext context) {
    String ay(DateTime d) => '${context.monthName(d.month)} ${d.year}';
    return '${ay(gebelik.gestationStart)} – ${ay(gebelik.endedAt!)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final sonuc = gebelik.outcome;
    final ga = gebelik.gestationAtEnd;
    final alt = [
      if (sonuc != null && sonuc != PregnancyOutcome.undisclosed)
        context.tr('preg_outcome_${sonuc.name}'),
      if (ga != null)
        context.tr(
          'past_preg_weeks_short',
          params: {'ga': '${ga.weeks}+${ga.days}'},
        ),
    ].join(' · ');

    return Material(
      key: Key('past_preg_${gebelik.id}'),
      color: t.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: t.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          RouteNames.pastPregnancy,
          pathParameters: {'id': gebelik.id},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _aralik(context),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: t.text,
                      ),
                    ),
                    if (alt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        alt,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: t.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
