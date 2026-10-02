import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/models/log_vocabulary.dart';
import '../../domain/services/lochia_trend.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../calendar/view_models/calendar_view_model.dart';
import '../home/widgets/cycle_ring.dart';
import '../home/widgets/cycle_ring_data.dart';
import '../home/widgets/home_header.dart';
import '../home/widgets/log_entry_fab.dart';
import 'care_grouping.dart';
import 'danger_signs_screen.dart';
import 'pregnancy_home_screen.dart';

/// Lohusalıkta ana sekme (doğumdan sonraki 42 gün).
///
/// Lohia burada regl olarak değil **seyri izlenecek** biçimde kaydediliyor
/// (bkz. `LifeStage.bleedingMeaning`): tehlike işareti tek bir günde değil
/// gidişatta — azaldıktan sonra yeniden artması. Seyir rehberdeki örüntüye
/// uyduğunda pano bunu söylüyor ve tehlike işaretlerine yönlendiriyor.
class PostpartumHomeScreen extends StatelessWidget {
  const PostpartumHomeScreen({super.key, @visibleForTesting this.today});

  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PregnancyViewModel>();
    final takvim = context.watch<CalendarViewModel>();
    final g = vm.current;
    final bugun = today ?? DateTime.now();
    final dogum = g?.endedAt;

    final kaygi = dogum == null
        ? LochiaConcern.none
        : LochiaTrend.evaluate(takvim.dailyLogs, birth: dogum, today: bugun);

    return Scaffold(
      // Kayıt ekranına giriş: belirtiler, ölçümler, kanama (bkz. LogEntryFab).
      floatingActionButtonLocation: const ContentEndFloatFab(),
      floatingActionButton: const LogEntryFab(),
      body: AppContentWidth(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: HomeHeader()),
            if (g != null && dogum != null)
              SliverPadding(
                // Listenin sonu düğmenin altında kalmasın.
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _GunKarti(dogum: dogum, bugun: bugun),
                    if (kaygi != LochiaConcern.none) _KaygiKarti(kaygi: kaygi),
                    _LohiaGirisi(bugun: bugun),
                    NextCareCard(
                      gebelik: g,
                      olaylar: CareGrouping.visible(
                        vm.currentEvents,
                        LifeStage.postpartum,
                      ),
                      bugun: bugun,
                    ),
                    const DangerEntryCard(period: DangerPeriod.postpartum),
                    const _Bilgi(),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GunKarti extends StatelessWidget {
  const _GunKarti({required this.dogum, required this.bugun});

  final DateTime dogum;
  final DateTime bugun;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final gun = DateTime(
      bugun.year,
      bugun.month,
      bugun.day,
    ).difference(DateTime(dogum.year, dogum.month, dogum.day)).inDays;

    // 42 çiçek, her biri bir gün — gebelik panosundaki 40 haftalık çelengin
    // lohusalık karşılığı.
    final data = CycleRingData(
      colors: [
        for (var i = 0; i < LifeStage.postpartumDays; i++)
          i < gun ? t.accent.withAlpha(80) : t.accent,
      ],
      todayIndex: gun.clamp(0, LifeStage.postpartumDays - 1),
      expected: LifeStage.postpartumDays,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: AppSectionedCard(
        header: CycleRing(
          data: data,
          caption: context.tr(
            'pp_days_total',
            params: {'n': '${LifeStage.postpartumDays}'},
          ),
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.upper(context.tr('pp_label')),
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 11,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w700,
                  color: t.accent,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  context.tr('pp_day', params: {'n': '$gun'}),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 34,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.8,
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

class _KaygiKarti extends StatelessWidget {
  const _KaygiKarti({required this.kaygi});

  final LochiaConcern kaygi;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        key: const Key('pp_lochia_concern'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.warning, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: t.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr(
                      kaygi == LochiaConcern.reIncrease
                          ? 'pp_concern_reincrease_title'
                          : 'pp_concern_rising_title',
                    ),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: t.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('pp_concern_body'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 14,
                height: 1.5,
                color: t.text,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.pushNamed(
                RouteNames.dangerSigns,
                queryParameters: {'period': DangerPeriod.postpartum.name},
              ),
              child: Text(context.tr('pp_concern_action')),
            ),
          ],
        ),
      ),
    );
  }
}

class _LohiaGirisi extends StatelessWidget {
  const _LohiaGirisi({required this.bugun});

  final DateTime bugun;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final takvim = context.watch<CalendarViewModel>();
    final bugunku = takvim.getDailyLogForDate(bugun);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('pp_lochia_title'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('pp_lochia_body'),
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                height: 1.45,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kod in LogVocabulary.flowIntensities)
                  ChoiceChip(
                    key: Key('pp_lochia_$kod'),
                    label: Text(context.tr('log_flow_$kod')),
                    selected: bugunku.flowIntensity == kod,
                    onSelected: (_) =>
                        takvim.updateDailyLog(bugunku.withFlowIntensity(kod)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Bilgi extends StatelessWidget {
  const _Bilgi();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final k in const ['pp_info_fertility', 'pp_info_supplements'])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18, color: t.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr(k),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        height: 1.5,
                        color: t.textMuted,
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
