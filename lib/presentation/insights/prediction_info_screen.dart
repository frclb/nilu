import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/prediction_basis.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import '../calendar/view_models/calendar_view_model.dart';

/// "Bu tahmin nasıl hesaplandı?"
///
/// Tahmin bir kara kutu olunca kullanıcı ona ya fazla güveniyor ya da hiç
/// güvenmiyor. Burada sayının nereden geldiği kullanıcının kendi
/// verisiyle söyleniyor: kaç döngü, en kısa/en uzun, varsayım varsa hangi
/// varsayım. Bkz. `PredictionBasis`.
class PredictionInfoScreen extends StatelessWidget {
  const PredictionInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final takvim = context.watch<CalendarViewModel>();
    final info = takvim.cycleInfo;
    final basis = info.basis;
    final next = info.predictedNextPeriod;
    final gecikti = info.daysLateAt(DateTime.now()) > 0;

    String tarih(DateTime d) => '${d.day} ${context.monthName(d.month)}';

    final hesap = <String>[];
    if (basis != null) {
      switch (basis.source) {
        case PredictionSource.history:
          hesap.add(
            context.tr(
              basis.cyclesAveraged == 1
                  ? 'prediction_info_history_avg_one'
                  : 'prediction_info_history_avg',
              params: {
                'k': '${basis.cyclesAveraged}',
                'n': '${basis.cycleLength}',
              },
            ),
          );
          if (basis.rangeFromHistory) {
            hesap.add(
              context.tr(
                'prediction_info_history_range',
                params: {
                  'm': '${basis.cyclesConsidered}',
                  'min': '${basis.shortest}',
                  'max': '${basis.longest}',
                },
              ),
            );
          } else {
            hesap.add(
              context.tr(
                basis.cyclesConsidered == 1
                    ? 'prediction_info_few_one'
                    : 'prediction_info_few',
                params: {
                  'm': '${basis.cyclesConsidered}',
                  'p': '${PredictionBasis.fewCyclesMargin}',
                },
              ),
            );
          }
        case PredictionSource.settings:
          hesap.add(
            context.tr(
              'prediction_info_settings',
              params: {
                'n': '${basis.cycleLength}',
                'p': '${PredictionBasis.fewCyclesMargin}',
              },
            ),
          );
        case PredictionSource.assumed:
          hesap.add(
            context.tr(
              'prediction_info_assumed',
              params: {
                'n': '${basis.cycleLength}',
                'p': '${PredictionBasis.assumedMargin}',
              },
            ),
          );
      }
      if (basis.isIrregular) hesap.add(context.tr('prediction_info_irregular'));
    }

    final aralikVar = basis != null && next != null && !gecikti;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('prediction_info_title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 21,
            color: t.text,
          ),
        ),
      ),
      body: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _Bolum(
              key: const Key('prediction_info_next'),
              icon: Icons.water_drop,
              iconColor: t.secondary,
              iconBackground: t.secondaryTint,
              title: context.tr('prediction_info_next'),
              children: [
                if (!aralikVar)
                  _Satir(
                    basis == null || next == null
                        ? context.tr('prediction_info_none')
                        : context.tr('prediction_info_late'),
                  )
                else ...[
                  _Satir(
                    context.tr(
                      'prediction_info_range',
                      params: {
                        'range': context.dayRange(basis.earliest, basis.latest),
                      },
                    ),
                    vurgulu: true,
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppTag(
                      label: context.tr(
                        'prediction_info_likely',
                        params: {'date': tarih(next)},
                      ),
                      dotColor: t.secondary,
                      foreground: t.flowText,
                      background: t.secondaryTint,
                    ),
                  ),
                  if (basis.latest.daysSince(basis.earliest) < 7) ...[
                    const SizedBox(height: 16),
                    _GunSeridi(
                      from: basis.earliest,
                      to: basis.latest,
                      likely: next,
                    ),
                  ],
                ],
              ],
            ),
            if (hesap.isNotEmpty)
              _Bolum(
                key: const Key('prediction_info_how'),
                icon: Icons.calculate_outlined,
                title: context.tr('prediction_info_how'),
                children: [
                  for (var i = 0; i < hesap.length; i++)
                    _Satir(
                      hesap[i],
                      vurgulu:
                          i == 0 && basis?.source == PredictionSource.history,
                    ),
                ],
              ),
            _Bolum(
              key: const Key('prediction_info_fertile'),
              icon: Icons.spa_outlined,
              iconColor: t.ovulationText,
              iconBackground: t.ovulationTint,
              title: context.tr('prediction_info_fertile_title'),
              children: [
                _Satir(
                  context.tr(
                    info.fertilityTracked
                        ? 'prediction_info_fertile'
                        : 'prediction_info_fertile_off',
                  ),
                  soluk: true,
                ),
              ],
            ),
            _Bolum(
              icon: Icons.trending_up,
              iconBackground: t.surfaceAlt,
              title: context.tr('prediction_info_improve_title'),
              children: [
                _Satir(context.tr('prediction_info_improve'), soluk: true),
                if (takvim.lifeStage.recordsPeriods) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    key: const Key('prediction_info_past_periods'),
                    onPressed: () => context.pushNamed(RouteNames.pastPeriods),
                    style: TextButton.styleFrom(
                      backgroundColor: t.surfaceAlt,
                      foregroundColor: theme.colorScheme.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(context.tr('past_periods_entry')),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.brandTint.withAlpha(170),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  AppIconTile(
                    icon: Icons.verified_user_outlined,
                    size: 36,
                    circle: true,
                    background: t.surface,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      context.tr('prediction_info_device'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                        color: t.textMuted,
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

class _Bolum extends StatelessWidget {
  const _Bolum({
    super.key,
    required this.icon,
    required this.title,
    required this.children,
    this.iconColor,
    this.iconBackground,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Color? iconColor;
  final Color? iconBackground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconTile(
                  icon: icon,
                  size: 44,
                  circle: true,
                  color: iconColor,
                  background: iconBackground,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Bölüm satırı. [vurgulu] ise "etiket: değer" biçiminde değer kalın.
///
/// Metin bölünmüyor; ekranda okunan cümle çeviri metninin kendisi.
class _Satir extends StatelessWidget {
  const _Satir(this.text, {this.vurgulu = false, this.soluk = false});

  final String text;
  final bool vurgulu;
  final bool soluk;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final base = theme.textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.5,
      color: soluk ? t.textMuted : t.text,
    );

    final at = vurgulu ? text.indexOf(': ') : -1;
    final Widget child;
    if (at <= 0 || at + 2 >= text.length) {
      child = Text(text, style: base);
    } else {
      child = Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(text: text.substring(0, at + 2)),
            TextSpan(
              text: text.substring(at + 2),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: child);
  }
}

/// Tahmin aralığındaki günler; en olası gün öne çıkıyor.
///
/// Yalnızca aralık bir haftadan kısayken çiziliyor: geniş aralıkta kutular
/// ekrana sığmayacak kadar daralıyor ve şerit bilgi değil gürültü oluyor.
/// Ekran okuyucu yukarıdaki cümleyi okuyor; şerit görsel bir tekrar.
class _GunSeridi extends StatelessWidget {
  const _GunSeridi({
    required this.from,
    required this.to,
    required this.likely,
  });

  final DateTime from;
  final DateTime to;
  final DateTime likely;

  static const _gunAnahtarlari = [
    'calendar_day_mon',
    'calendar_day_tue',
    'calendar_day_wed',
    'calendar_day_thu',
    'calendar_day_fri',
    'calendar_day_sat',
    'calendar_day_sun',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = to.daysSince(from) + 1;

    return ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = from.plusDays(i);
                  final secili = day.daysSince(likely) == 0;
                  final fg = secili ? scheme.onSecondary : t.text;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: secili ? t.secondary : t.brandTint,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      boxShadow: secili ? AppShadows.soft(context) : null,
                    ),
                    child: Column(
                      children: [
                        Text(
                          context.tr(_gunAnahtarlari[day.weekday - 1]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: secili ? fg : t.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${day.day}',
                          maxLines: 1,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: secili
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
