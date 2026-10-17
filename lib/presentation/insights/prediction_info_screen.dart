import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
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
              'prediction_info_history_avg',
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
                'prediction_info_few',
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

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('prediction_info_title'),
          style: TextStyle(
            color: t.text,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
      ),
      body: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _Bolum(
              key: const Key('prediction_info_next'),
              icon: Icons.water_drop_outlined,
              title: context.tr('prediction_info_next'),
              lines: [
                if (basis == null || next == null)
                  context.tr('prediction_info_none')
                else if (gecikti)
                  context.tr('prediction_info_late')
                else ...[
                  context.tr(
                    'prediction_info_range',
                    params: {
                      'range': context.dayRange(basis.earliest, basis.latest),
                    },
                  ),
                  context.tr(
                    'prediction_info_likely',
                    params: {'date': tarih(next)},
                  ),
                ],
              ],
            ),
            if (hesap.isNotEmpty)
              _Bolum(
                key: const Key('prediction_info_how'),
                icon: Icons.calculate_outlined,
                title: context.tr('prediction_info_how'),
                lines: hesap,
              ),
            _Bolum(
              key: const Key('prediction_info_fertile'),
              icon: Icons.spa_outlined,
              title: context.tr('prediction_info_fertile_title'),
              lines: [
                context.tr(
                  info.fertilityTracked
                      ? 'prediction_info_fertile'
                      : 'prediction_info_fertile_off',
                ),
              ],
            ),
            _Bolum(
              icon: Icons.trending_up,
              title: context.tr('prediction_info_improve_title'),
              lines: [context.tr('prediction_info_improve')],
              action: takvim.lifeStage.recordsPeriods
                  ? TextButton(
                      key: const Key('prediction_info_past_periods'),
                      onPressed: () =>
                          context.pushNamed(RouteNames.pastPeriods),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(context.tr('past_periods_entry')),
                    )
                  : null,
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lock_outline, size: 16, color: t.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr('prediction_info_device'),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: t.textMuted,
                    ),
                  ),
                ),
              ],
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
    required this.lines,
    this.action,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: t.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: TextStyle(fontSize: 14, height: 1.5, color: t.text),
              ),
            ),
          ?action,
        ],
      ),
    );
  }
}
