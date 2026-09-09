import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import 'package:provider/provider.dart';
import '../../../design_system/app_colors.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/date_names.dart';
import '../view_models/calendar_view_model.dart';
import 'day_detail_bottom_sheet.dart';

/// Seçili günün kimliği, durumu ve o güne uygulanan eylemler.
///
/// Bu bilgi ekranda eskiden **iki kez** çıkıyordu: takvim kartının altındaki
/// küçük kutu ("18 Ağu · Döngü günü 2 · Regl günü") ve hemen ardından gelen
/// özet bölümünün başlığı ("18 Ağustos / Salı · Döngü günü 2"). Üstelik eylem
/// düğmeleri, üzerinde çalıştıkları günün bilgisinden **önce** geliyordu.
///
/// Tek başlıkta toplandı. Ekran sırası artık okunma sırasıyla aynı:
/// takvim → seçili gün ve durumu → o güne yapılacak eylemler → günün özeti.
class CalendarDayHeader extends StatelessWidget {
  const CalendarDayHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = context.watch<CalendarViewModel>();

    final selectedDate = viewModel.selectedDate;
    final cycleDay = viewModel.getCycleDayForDate(selectedDate);
    final isPeriod = viewModel.isPeriodDay(selectedDate);
    final status = _DayStatus.resolve(
      context,
      isPeriod: isPeriod,
      isOvulation: viewModel.cycleInfo.isOvulationDay(selectedDate),
      isFertile: viewModel.cycleInfo.isFertile(selectedDate),
      isPredicted: viewModel.isPredictedPeriodDay(selectedDate),
    );

    final dateStr =
        '${selectedDate.day} ${context.monthName(selectedDate.month)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      context.weekdayName(selectedDate.weekday),
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (cycleDay != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.tr(
                      'calendar_cycle_day',
                      params: {'day': '$cycleDay'},
                    ),
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Seçili günün durumu
          Row(
            children: [
              Icon(status.icon, size: 18, color: status.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.text,
                  style: TextStyle(
                    color: status.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Seçili güne uygulanan eylemler.
          // Erişilebilir dokunma alanı (min 48dp); uzun çevirilerde taşma
          // yerine kısaltma.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _togglePeriod(context, viewModel),
                  icon: Icon(
                    isPeriod ? Icons.water_drop : Icons.water_drop_outlined,
                    size: 18,
                    color: isPeriod
                        ? AppColors.flowMedium
                        : theme.colorScheme.primary,
                  ),
                  label: Text(
                    context.tr(
                      isPeriod
                          ? 'calendar_unmark_period'
                          : 'calendar_mark_period',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isPeriod
                          ? AppColors.flowMedium
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    side: BorderSide(
                      color: isPeriod
                          ? AppColors.flowMedium.withAlpha(102)
                          : theme.colorScheme.primary.withAlpha(76),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showDayDetailSheet(context, selectedDate),
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: Text(
                    context.tr('calendar_add_note'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    backgroundColor: theme.brightness == Brightness.dark
                        ? theme.colorScheme.primary.withAlpha(51)
                        : theme.colorScheme.primary.withAlpha(25),
                    foregroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _togglePeriod(
    BuildContext context,
    CalendarViewModel viewModel,
  ) async {
    final date = viewModel.selectedDate;
    final wasPeriod = viewModel.isPeriodDay(date);
    final success = await viewModel.togglePeriodDay(date);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? context.tr(
                  wasPeriod
                      ? 'calendar_period_unmarked'
                      : 'calendar_period_marked',
                  params: {'date': '${date.day}/${date.month}'},
                )
              : context.tr('calendar_future_date_error'),
        ),
        backgroundColor: !success
            ? context.tokens.danger
            : wasPeriod
            ? Colors.grey.shade700
            : AppColors.flowMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Seçili günün durum rozetini (metin + renk + ikon) çözer.
class _DayStatus {
  final String text;
  final Color color;
  final IconData icon;

  const _DayStatus(this.text, this.color, this.icon);

  static _DayStatus resolve(
    BuildContext context, {
    required bool isPeriod,
    required bool isOvulation,
    required bool isFertile,
    required bool isPredicted,
  }) {
    if (isPeriod) {
      return _DayStatus(
        context.tr('calendar_status_period'),
        AppColors.flowMedium,
        Icons.water_drop,
      );
    }
    if (isOvulation) {
      return _DayStatus(
        context.tr('calendar_status_ovulation'),
        Colors.deepPurple.shade400,
        Icons.star,
      );
    }
    if (isFertile) {
      return _DayStatus(
        context.tr('calendar_status_fertile'),
        Colors.pink.shade300,
        Icons.favorite,
      );
    }
    if (isPredicted) {
      return _DayStatus(
        context.tr('calendar_status_predicted'),
        AppColors.flowLight,
        Icons.water_drop_outlined,
      );
    }
    return _DayStatus(
      context.tr('calendar_status_normal'),
      Colors.grey,
      Icons.circle_outlined,
    );
  }
}
