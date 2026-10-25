import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/care_event.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/models/pregnancy_month.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import '../home/widgets/cycle_ring.dart';
import '../home/widgets/home_header.dart';
import '../home/widgets/home_hero_card.dart';
import '../home/widgets/log_entry_fab.dart';
import 'care_text.dart';
import 'danger_signs_screen.dart';
import 'due_date_sheet.dart';
import 'pregnancy_ring.dart';

/// Gebelikte ana sekme.
///
/// Sıralama bilinçli: önce nerede olduğun (hafta), sonra sıradaki iş
/// (randevu), sonra "bir şeyler yolunda değil mi?" — tehlike işaretlerine
/// tek dokunuş. Haftalık içerik (meyve boyu vb.) v1'de yok: kullanıcıya ne
/// yapacağını söylemiyor ve altı dilde 40 haftalık metin yayını aylarca
/// geciktirirdi (bkz. `PREGNANCY_MODE.md` §6).
class PregnancyHomeScreen extends StatelessWidget {
  const PregnancyHomeScreen({super.key, @visibleForTesting this.today});

  /// Testte bugünün yerine.
  final DateTime? today;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PregnancyViewModel>();
    final gebelik = vm.current;
    final bugun = today ?? DateTime.now();

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
                if (gebelik != null)
                  SliverPadding(
                    // Listenin sonu düğmenin altında kalmasın.
                    padding: const EdgeInsets.only(bottom: 104),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _HaftaKarti(gebelik: gebelik, bugun: bugun),
                        NextCareCard(
                          gebelik: gebelik,
                          olaylar: vm.currentEvents,
                          bugun: bugun,
                        ),
                        const DangerEntryCard(period: DangerPeriod.pregnancy),
                        // Genel bakış en sonda: önce nerede olduğun, sıradaki
                        // iş ve tehlike işaretleri — küçük ekranda bu üçü ilk
                        // bakışta görünmeli.
                        _AylarKarti(gebelik: gebelik, bugun: bugun),
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

/// Halkanın ortasındaki küçük etiket hapı ("6. AY · 2. TRİMESTER").
class RingLabel extends StatelessWidget {
  const RingLabel(this.text, {super.key, this.dotColor});

  final String text;

  /// Baştaki küçük nokta (ör. trimester rengi).
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: t.secondaryTint.withAlpha(140),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                letterSpacing: 1,
                fontWeight: FontWeight.w700,
                color: t.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HaftaKarti extends StatelessWidget {
  const _HaftaKarti({required this.gebelik, required this.bugun});

  final Pregnancy gebelik;
  final DateTime bugun;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final ga = gebelik.gestationOn(bugun);
    final trimester = gebelik.trimesterOn(bugun);
    final edd = gebelik.estimatedDueDate;
    final kalan = edd.daysSince(bugun);

    final rakam = theme.textTheme.displaySmall?.copyWith(
      fontSize: 44,
      height: 1.05,
      letterSpacing: -0.8,
      color: theme.colorScheme.primary,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: HomeHeroCard(
        // Kart tahmini doğum tarihini düzenleme sayfasını açıyor; sağ üstteki
        // simge bunu ima ediyor (ayrı bir düğme değil).
        onTap: () => showDueDateSheet(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HeroDateLine(
              date: bugun,
              trailing: ExcludeSemantics(
                child: AppIconTile(
                  icon: Icons.edit_calendar_rounded,
                  size: 26,
                  circle: true,
                  background: t.secondaryTint.withAlpha(160),
                  color: t.secondary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            CycleRing(
              data: PregnancyRing.data(gebelik, today: bugun, tokens: t),
              caption: RingCaption(
                context.tr(
                  'preg_due_caption',
                  params: {'date': context.dayMonth(edd)},
                ),
              ),
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trimester != null) ...[
                    RingLabel(
                      // Ay ve trimester birlikte: kullanıcı süreci aylarla
                      // düşünüyor, hekim haftayla konuşuyor (bkz.
                      // `PregnancyMonth`).
                      context.upper(
                        '${context.monthLabel(PregnancyMonth.of(ga!).number)}'
                        ' · '
                        '${context.tr('preg_trimester_label', params: {'n': '${trimester.index + 1}'})}',
                      ),
                      dotColor: PregnancyRing.trimesterColors(
                        t,
                      )[trimester.index],
                    ),
                    const SizedBox(height: 6),
                  ],
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      // Hekimin ve ultrason raporunun kullandığı gösterim:
                      // tamamlanan hafta + gün. "25. hafta" demek, 24+3'ün
                      // 24 mü 25 mi olduğu konusunda belirsizlik bırakırdı.
                      ga == null
                          ? const TextSpan(text: '—')
                          : TextSpan(
                              children: [
                                TextSpan(text: '${ga.weeks}'),
                                TextSpan(
                                  text: '+${ga.days}',
                                  style: rakam?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w400,
                                    color: t.secondary,
                                  ),
                                ),
                              ],
                            ),
                      semanticsLabel: ga == null
                          ? null
                          : context.gestationSentence(ga),
                      style: rakam,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (ga != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: t.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      context.gestationSentence(ga),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 16,
                      color: t.secondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        context.dueCountdown(kalan),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

class NextCareCard extends StatelessWidget {
  const NextCareCard({
    super.key,
    required this.gebelik,
    required this.olaylar,
    required this.bugun,
  });

  final Pregnancy gebelik;
  final List<CareEvent> olaylar;
  final DateTime bugun;

  /// Henüz yapılmamış ve penceresi geçmemiş ilk kalem
  /// (bkz. `CareEvent.isPendingOn`).
  static CareEvent? siradaki(
    List<CareEvent> olaylar,
    Pregnancy gebelik,
    DateTime bugun,
  ) => olaylar.where((e) => e.isPendingOn(gebelik, bugun)).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final e = siradaki(olaylar, gebelik, bugun);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        onTap: () => context.pushNamed(RouteNames.careList),
        child: Row(
          children: [
            AppIconTile(
              icon: Icons.medical_services_outlined,
              size: 48,
              background: t.secondaryTint.withAlpha(170),
              color: t.secondary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTag(
                    label: context.upper(context.tr('preg_next_care')),
                    background: t.secondary,
                    foreground: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    e == null
                        ? context.tr('preg_next_care_none')
                        : context.careTitle(e),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      height: 1.3,
                      color: t.text,
                    ),
                  ),
                  if (e != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: t.secondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            context.careWhen(e, gebelik),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 13,
                              color: t.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: t.textFaint),
          ],
        ),
      ),
    );
  }
}

/// "Bir şeyler yolunda değil mi?" — tehlike işaretlerine tek dokunuş.
class DangerEntryCard extends StatelessWidget {
  const DangerEntryCard({super.key, required this.period});

  final DangerPeriod period;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.pushNamed(
          RouteNames.dangerSigns,
          queryParameters: {'period': period.name},
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppGradients.warm(context),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: t.warning.withAlpha(40)),
            boxShadow: AppShadows.soft(context),
          ),
          child: Row(
            children: [
              AppIconTile(
                icon: Icons.health_and_safety_rounded,
                size: 48,
                background: t.warning,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        period == DangerPeriod.pregnancy
                            ? 'preg_danger_entry_title'
                            : 'pp_danger_entry_title',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                        color: t.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr('preg_danger_entry_body'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: t.surface.withAlpha(200),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: t.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dokuz ayın neresindesin: geçen aylar dolu, bu ay vurgulu.
class _AylarKarti extends StatelessWidget {
  const _AylarKarti({required this.gebelik, required this.bugun});

  final Pregnancy gebelik;
  final DateTime bugun;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final ga = gebelik.gestationOn(bugun);
    if (ga == null) return const SizedBox.shrink();
    final ay = PregnancyMonth.of(ga);
    final sayi = theme.textTheme.labelMedium?.copyWith(
      fontSize: 11.5,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: AppCard(
        key: const Key('preg_months_card'),
        padding: const EdgeInsets.all(16),
        onTap: () => context.pushNamed(RouteNames.pregnancyMonths),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('preg_months_title'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: t.textFaint),
              ],
            ),
            const SizedBox(height: 12),
            // Ayların sayıları ekran okuyucuya tek tek okunmasın; aşağıdaki
            // satır aynı bilgiyi cümleyle veriyor.
            ExcludeSemantics(
              child: Row(
                children: [
                  for (final m in PregnancyMonth.all)
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: m.number == ay.number ? 32 : 26,
                            height: m.number == ay.number ? 32 : 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: m.number == ay.number
                                  ? AppGradients.mark(context)
                                  : null,
                              color: m.number == ay.number
                                  ? null
                                  : m.number < ay.number
                                  ? t.secondaryTint
                                  : t.surfaceAlt,
                              boxShadow: m.number == ay.number
                                  ? AppShadows.soft(context)
                                  : null,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${m.number}',
                                style: sayi?.copyWith(
                                  fontSize: m.number == ay.number ? 14 : 11.5,
                                  color: m.number == ay.number
                                      ? theme.colorScheme.onPrimary
                                      : m.number < ay.number
                                      ? t.secondary
                                      : t.textFaint,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: m.number == ay.number ? 6 : 4,
                            height: m.number == ay.number ? 6 : 4,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: m.number <= ay.number
                                  ? t.secondary
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${context.monthLabel(ay.number)} · '
              '${context.tr('preg_month_weeks', params: {'a': '${ay.fromWeek}', 'b': '${ay.toWeek}'})}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontSize: 14.5,
                color: t.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
