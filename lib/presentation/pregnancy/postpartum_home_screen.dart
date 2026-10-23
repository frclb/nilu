import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/models/log_vocabulary.dart';
import '../../domain/services/lochia_trend.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../calendar/view_models/calendar_view_model.dart';
import '../home/widgets/cycle_ring.dart';
import '../home/widgets/cycle_ring_data.dart';
import '../home/widgets/home_header.dart';
import '../home/widgets/home_hero_card.dart';
import '../home/widgets/log_entry_fab.dart';
import 'care_grouping.dart';
import 'danger_signs_screen.dart';
import 'pregnancy_home_screen.dart';
import 'return_to_cycle.dart';

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
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: AppContentWidth(
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: HomeBrandBar()),
                const SliverToBoxAdapter(child: HomeHeader()),
                if (g != null && dogum != null)
                  SliverPadding(
                    // Listenin sonu düğmenin altında kalmasın.
                    padding: const EdgeInsets.only(bottom: 104),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _GunKarti(dogum: dogum, bugun: bugun),
                        if (kaygi != LochiaConcern.none)
                          _KaygiKarti(kaygi: kaygi),
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
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: OutlinedButton.icon(
                            key: const Key('pp_return_button'),
                            onPressed: () => confirmReturnToCycle(context),
                            icon: Icon(
                              Icons.swap_horiz_rounded,
                              size: 20,
                              color: context.tokens.secondary,
                            ),
                            label: Text(context.tr('pp_return_to_cycle')),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: context.tokens.surface,
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              side: BorderSide(
                                color: AppCard.borderColor(context.tokens),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
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
    final gun = bugun.daysSince(dogum);

    // 42 boncuk, her biri bir gün — gebelik panosundaki 40 haftalık dizinin
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: HomeHeroCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CycleRing(
              data: data,
              caption: RingCaption(
                context.tr(
                  'pp_days_total',
                  params: {'n': '${LifeStage.postpartumDays}'},
                ),
              ),
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RingLabel(
                    context.upper(context.tr('pp_label')),
                    dotColor: t.accent,
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      // Doğum günü "0. gün" yazıyordu: tutarlı (pencereler
                      // doğumdan sonraki günlerle sayılıyor) ama hata gibi.
                      gun == 0
                          ? context.tr('pp_day_birth')
                          : context.tr('pp_day', params: {'n': '$gun'}),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontSize: 40,
                        height: 1.05,
                        letterSpacing: -0.6,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        key: const Key('pp_lochia_concern'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: t.warning, width: 1.5),
          boxShadow: AppShadows.soft(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconTile(
                  icon: Icons.warning_amber_rounded,
                  size: 36,
                  background: t.accentTint,
                  color: t.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(
                      kaygi == LochiaConcern.reIncrease
                          ? 'pp_concern_reincrease_title'
                          : 'pp_concern_rising_title',
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: t.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('pp_concern_body'),
              style: theme.textTheme.bodyMedium?.copyWith(
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AppCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop_outlined, size: 22, color: t.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('pp_lochia_title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('pp_lochia_body'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13.5,
                height: 1.45,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final kod in LogVocabulary.flowIntensities)
                  ChoiceChip(
                    key: Key('pp_lochia_$kod'),
                    label: Text(context.tr('log_flow_$kod')),
                    selected: bugunku.flowIntensity == kod,
                    showCheckmark: false,
                    selectedColor: t.secondary,
                    backgroundColor: t.surfaceAlt,
                    side: BorderSide(
                      color: bugunku.flowIntensity == kod
                          ? t.secondary
                          : t.border,
                    ),
                    labelStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: bugunku.flowIntensity == kod
                          ? theme.colorScheme.onPrimary
                          : t.textMuted,
                    ),
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (k, icon) in const [
            ('pp_info_fertility', Icons.child_care_outlined),
            ('pp_info_supplements', Icons.medication_outlined),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppCard.borderColor(t)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppIconTile(
                      icon: icon,
                      size: 32,
                      circle: true,
                      background: t.secondaryTint.withAlpha(150),
                      color: t.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.tr(k),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.5,
                          height: 1.5,
                          color: t.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
