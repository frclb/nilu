import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../domain/models/period_log.dart';
import '../../../domain/services/insights_service.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/date_names.dart';
import '../../calendar/view_models/calendar_view_model.dart';

/// Bütün döngülerin listesi ve temel istatistik — herkese açık.
///
/// Ücretsiz kullanıcı önceden yalnızca son üç döngüyü görebiliyordu;
/// "döngüm ne kadar sürmüştü" sorusunun cevabı ödeme duvarının
/// arkasındaydı. Rakiplerin en çok tepki çeken hamlesi tam olarak buydu.
/// Liste ve ortalama temel ihtiyaç; Premium'un kattığı, tüm geçmişle trend
/// grafiği ve analiz.
class CycleHistoryCard extends StatefulWidget {
  const CycleHistoryCard({super.key});

  /// Açılmadan gösterilen döngü sayısı.
  static const int collapsedCount = 6;

  @override
  State<CycleHistoryCard> createState() => _CycleHistoryCardState();
}

class _CycleHistoryCardState extends State<CycleHistoryCard> {
  bool _hepsi = false;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CalendarViewModel>();
    final dongu = InsightsService.cycleLengths(
      vm.periodLogs,
      breaks: vm.cycleBreaks,
      limit: null,
    );
    if (dongu.isEmpty) return const SizedBox.shrink();

    final t = context.tokens;
    final theme = Theme.of(context);
    final enYeni = dongu.reversed.toList();
    final gorunen = _hepsi
        ? enYeni
        : enYeni.take(CycleHistoryCard.collapsedCount).toList();
    final uzunluklar = dongu.map((p) => p.lengthInDays);
    final ortalama = InsightsService.averageLength(dongu)!;
    final enKisa = uzunluklar.reduce((a, b) => a < b ? a : b);
    final enUzun = uzunluklar.reduce((a, b) => a > b ? a : b);

    return AppCard(
      key: const Key('cycle_history_card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              context.tr('insights_history_title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 21,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            dongu.length == 1
                ? context.tr(
                    'insights_history_stats_one',
                    params: {'avg': '$ortalama'},
                  )
                : context.tr(
                    'insights_history_stats',
                    params: {
                      'count': '${dongu.length}',
                      'avg': '$ortalama',
                      'min': '$enKisa',
                      'max': '$enUzun',
                    },
                  ),
            style: theme.textTheme.bodySmall?.copyWith(color: t.textMuted),
          ),
          const SizedBox(height: 16),
          for (final p in gorunen)
            _Satir(
              key: Key('cycle_history_row_${_gunAnahtari(p.startDate)}'),
              baslangic: p.startDate,
              uzunluk: p.lengthInDays,
              reglGunu: _reglSuresi(vm.periodLogs, p.startDate),
              enUzun: p.lengthInDays == enUzun && enUzun != enKisa,
            ),
          if (!_hepsi && enYeni.length > CycleHistoryCard.collapsedCount) ...[
            const SizedBox(height: 4),
            TextButton(
              key: const Key('cycle_history_show_all'),
              onPressed: () => setState(() => _hepsi = true),
              style: TextButton.styleFrom(
                backgroundColor: t.surfaceAlt,
                foregroundColor: theme.colorScheme.primary,
                minimumSize: const Size.fromHeight(48),
                shape: const StadiumBorder(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      context.tr(
                        'insights_history_show_all',
                        params: {'count': '${enYeni.length}'},
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _gunAnahtari(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// O döngüyü başlatan reglin kaydedilmiş süresi; bitişi girilmemişse
  /// `null` (uydurulmuyor).
  static int? _reglSuresi(List<PeriodLog> kayitlar, DateTime baslangic) {
    for (final k in kayitlar) {
      if (k.firstDay == baslangic) return k.completedLength;
    }
    return null;
  }
}

class _Satir extends StatelessWidget {
  const _Satir({
    super.key,
    required this.baslangic,
    required this.uzunluk,
    required this.reglGunu,
    required this.enUzun,
  });

  final DateTime baslangic;
  final int uzunluk;
  final int? reglGunu;

  /// Listedeki en uzun döngü mü? Uzunluğu ikincil renkte yazılıyor.
  final bool enUzun;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final tarih =
        '${baslangic.day} ${context.monthName(baslangic.month)} '
        '${baslangic.year}';
    final regl = reglGunu;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: t.brandTint.withAlpha(170),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            AppIconTile(
              icon: Icons.water_drop,
              size: 36,
              color: t.secondary,
              background: t.secondaryTint,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tarih,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                  ),
                  if (regl != null)
                    Text(
                      context.tr(
                        regl == 1
                            ? 'insights_history_period_one'
                            : 'insights_history_period',
                        params: {'days': '$regl'},
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: t.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              context.tr(
                'insights_history_cycle_days',
                params: {'days': '$uzunluk'},
              ),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: enUzun ? t.secondary : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
