import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import 'delete_pregnancy.dart';

/// Geçmiş gebelikler.
///
/// Gebelik bitince kayıt silinmiyordu (sonlandırma ekranı "geçmişte kalır"
/// diyor) ama bir daha görülemiyordu. Burası bilinçli olarak açılan yer:
/// takvimde ve panoda kayıpla biten gebelikler anılmıyor (bkz.
/// `PregnancyCalendar`).
///
/// Nasıl bittiği yalnızca kullanıcı belirttiyse yazıyor; "belirtmek
/// istemiyorum" diyene burada da bir etiket konmuyor. Kartlar her sonuçta
/// aynı görünümde: doğum ile kayıp arasında renk ya da simge farkı yok.
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
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        title: Text(
          context.tr('past_preg_title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppGradients.blush(context),
                  borderRadius: BorderRadius.circular(AppCard.radius),
                  border: Border.all(color: AppCard.borderColor(t)),
                ),
                child: Row(
                  children: [
                    AppIconTile(
                      icon: Icons.spa_outlined,
                      size: 44,
                      circle: true,
                      background: t.surface,
                      color: t.secondary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        context.tr(
                          gecmis.isEmpty
                              ? 'past_preg_empty'
                              : 'past_preg_list_intro',
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: t.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (final g in gecmis) ...[
                _Kart(gebelik: g),
                const SizedBox(height: 14),
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

    return Container(
      decoration: AppCard.decoration(t),
      clipBehavior: Clip.antiAlias,
      child: Material(
        key: Key('past_preg_${gebelik.id}'),
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => context.pushNamed(
            RouteNames.pastPregnancy,
            pathParameters: {'id': gebelik.id},
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (alt.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: t.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                alt,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: t.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        _aralik(context),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 22,
                          height: 1.2,
                          color: t.text,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: AppCard.dividerColor(t)),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              context.tr('past_preg_record_title'),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: t.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: t.textMuted,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: Key('past_preg_delete_${gebelik.id}'),
                      tooltip: context.tr('preg_delete_title'),
                      icon: Icon(Icons.delete_outline, color: t.textMuted),
                      onPressed: () =>
                          confirmDeletePregnancy(context, gebelik.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
