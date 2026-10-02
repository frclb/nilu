import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/care_event.dart';
import '../../domain/models/pregnancy.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import '../home/widgets/cycle_ring.dart';
import '../home/widgets/home_header.dart';
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
      body: AppContentWidth(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: HomeHeader()),
            if (gebelik != null)
              SliverPadding(
                // Listenin sonu düğmenin altında kalmasın.
                padding: const EdgeInsets.only(bottom: 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _HaftaKarti(gebelik: gebelik, bugun: bugun),
                    NextCareCard(
                      gebelik: gebelik,
                      olaylar: vm.currentEvents,
                      bugun: bugun,
                    ),
                    const DangerEntryCard(period: DangerPeriod.pregnancy),
                  ]),
                ),
              ),
          ],
        ),
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
    final kalan = DateTime(
      edd.year,
      edd.month,
      edd.day,
    ).difference(DateTime(bugun.year, bugun.month, bugun.day)).inDays;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: AppSectionedCard(
        onTap: () => showDueDateSheet(context),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${bugun.day} ${context.monthName(bugun.month)} '
              '${bugun.year} · ${context.weekdayName(bugun.weekday)}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: t.text,
              ),
            ),
            const SizedBox(height: 6),
            CycleRing(
              data: PregnancyRing.data(gebelik, today: bugun, tokens: t),
              caption: context.tr(
                'preg_due_caption',
                params: {'date': '${edd.day} ${context.monthName(edd.month)}'},
              ),
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (trimester != null)
                    Text(
                      context.upper(
                        context.tr(
                          'preg_trimester_label',
                          params: {'n': '${trimester.index + 1}'},
                        ),
                      ),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 11,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w700,
                        color: PregnancyRing.trimesterColors(
                          t,
                        )[trimester.index],
                      ),
                    ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      // Hekimin ve ultrason raporunun kullandığı gösterim:
                      // tamamlanan hafta + gün. "25. hafta" demek, 24+3'ün
                      // 24 mü 25 mi olduğu konusunda belirsizlik bırakırdı.
                      ga == null ? '—' : '${ga.weeks}+${ga.days}',
                      semanticsLabel: ga == null
                          ? null
                          : context.gestationSentence(ga),
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 40,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (ga != null)
              Center(
                child: Text(
                  context.gestationSentence(ga),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    color: t.textMuted,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                context.dueCountdown(kalan),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 13,
                  color: t.textFaint,
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
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: AppCard(
        onTap: () => context.pushNamed(RouteNames.careList),
        child: Row(
          children: [
            Icon(Icons.event_note_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.upper(context.tr('preg_next_care')),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e == null
                        ? context.tr('preg_next_care_none')
                        : context.careTitle(e),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                  ),
                  if (e != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      context.careWhen(e, gebelik),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.textFaint),
          ],
        ),
      ),
    );
  }
}

class DangerEntryCard extends StatelessWidget {
  const DangerEntryCard({super.key, required this.period});

  final DangerPeriod period;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: AppCard(
        onTap: () => context.pushNamed(
          RouteNames.dangerSigns,
          queryParameters: {'period': period.name},
        ),
        child: Row(
          children: [
            Icon(Icons.health_and_safety_outlined, color: t.warning),
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
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr('preg_danger_entry_body'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      height: 1.4,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.textFaint),
          ],
        ),
      ),
    );
  }
}
