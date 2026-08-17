import 'package:flutter/material.dart';
import '../../../../localization/app_localizations.dart';
import '../../../../localization/date_names.dart';
import '../../../../design_system/app_colors.dart';
import '../../../domain/models/daily_log.dart';

import 'package:provider/provider.dart';
import '../view_models/calendar_view_model.dart';
import 'day_detail_bottom_sheet.dart';

class CalendarGrid extends StatelessWidget {
  const CalendarGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final viewModel = context.watch<CalendarViewModel>();

    if (viewModel.isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Gerçek takvim verilerini hesapla
    final currentMonth = viewModel.currentMonth;
    final year = currentMonth.year;
    final month = currentMonth.month;

    // Ayın ilk günü ve haftanın hangi günü olduğu
    final firstDayOfMonth = DateTime(year, month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 (Pzt) - 7 (Paz)

    // Grid'de görünmesi gereken önceki aydan kalan gün sayısı
    final previousMonthFill = firstWeekday - 1;

    // Ayın toplam gün sayısı
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Toplam grid eleman sayısı (Genellikle 35 veya 42)
    final totalItems = ((daysInMonth + previousMonthFill) / 7).ceil() * 7;

    final daysOfWeek = [
      context.tr('calendar_day_mon'),
      context.tr('calendar_day_tue'),
      context.tr('calendar_day_wed'),
      context.tr('calendar_day_thu'),
      context.tr('calendar_day_fri'),
      context.tr('calendar_day_sat'),
      context.tr('calendar_day_sun'),
    ];

    final currentMonthName = context.monthName(month);

    // Seçili gün bilgisi
    final selectedDate = viewModel.selectedDate;
    final selectedCycleDay = viewModel.getCycleDayForDate(selectedDate);
    final selectedIsFertile = viewModel.cycleInfo.isFertile(selectedDate);
    final selectedIsOvulation = viewModel.cycleInfo.isOvulationDay(
      selectedDate,
    );
    final selectedIsPeriod = viewModel.isPeriodDay(selectedDate);
    final selectedIsPredicted = viewModel.cycleInfo.isPredictedPeriod(
      selectedDate,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      child: Column(
        children: [
          // Ay Navigasyonu
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => viewModel.previousMonth(),
                  icon: const Icon(Icons.chevron_left),
                  color: theme.textTheme.labelLarge?.color,
                ),
                Text(
                  context.tr(
                    'calendar_month_year',
                    params: {
                      'month': currentMonthName,
                      'year': year.toString(),
                    },
                  ),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => viewModel.nextMonth(),
                  icon: const Icon(Icons.chevron_right),
                  color: theme.textTheme.labelLarge?.color,
                ),
              ],
            ),
          ),

          // Haftanın Günleri Başlığı
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: daysOfWeek.map((day) {
              return SizedBox(
                width: 48,
                child: Text(
                  day.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.primary.withAlpha(178),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Takvim Izgarası
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalItems,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 2,
              crossAxisSpacing: 0,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) {
              final DateTime date;
              bool isFaded = false;

              if (index < previousMonthFill) {
                isFaded = true;
                date = firstDayOfMonth.subtract(
                  Duration(days: previousMonthFill - index),
                );
              } else if (index < previousMonthFill + daysInMonth) {
                date = DateTime(year, month, index - previousMonthFill + 1);
              } else {
                isFaded = true;
                date = DateTime(year, month, daysInMonth).add(
                  Duration(days: index - (previousMonthFill + daysInMonth) + 1),
                );
              }

              return _DayTile(date: date, isFaded: isFaded);
            },
          ),

          const SizedBox(height: 12),

          // Açıklamalar (Legend)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                context,
                AppColors.flowMedium,
                context.tr('calendar_legend_period'),
              ),
              const SizedBox(width: 12),
              _buildLegendItem(
                context,
                AppColors.flowLight,
                context.tr('calendar_legend_predicted'),
              ),
              const SizedBox(width: 12),
              _buildLegendItem(
                context,
                isDark ? AppColors.secondaryPinkDark : AppColors.fertileLight,
                context.tr('calendar_legend_fertility'),
              ),
              const SizedBox(width: 12),
              _buildLegendItem(
                context,
                Colors.deepPurple.shade300,
                context.tr('calendar_legend_ovulation'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Hızlı Aksiyon Butonları — "Regli düzenle" & "Not ekle"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Direkt regl toggle — sheet açmadan
                      final isPeriodNow = viewModel.isPeriodDay(selectedDate);
                      final success = await viewModel.togglePeriodDay(
                        selectedDate,
                      );
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr(
                                  isPeriodNow
                                      ? 'calendar_period_unmarked'
                                      : 'calendar_period_marked',
                                  params: {
                                    'date':
                                        '${selectedDate.day}/${selectedDate.month}',
                                  },
                                ),
                              ),
                              backgroundColor: isPeriodNow
                                  ? Colors.grey.shade700
                                  : AppColors.flowMedium,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.tr('calendar_future_date_error'),
                              ),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      selectedIsPeriod
                          ? Icons.water_drop
                          : Icons.water_drop_outlined,
                      size: 18,
                      color: selectedIsPeriod
                          ? AppColors.flowMedium
                          : theme.colorScheme.primary,
                    ),
                    label: Text(
                      context.tr(
                        selectedIsPeriod
                            ? 'calendar_unmark_period'
                            : 'calendar_mark_period',
                      ),
                      style: TextStyle(
                        color: selectedIsPeriod
                            ? AppColors.flowMedium
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: selectedIsPeriod
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
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) =>
                            DayDetailBottomSheet(date: selectedDate),
                      );
                    },
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: Text(
                      context.tr('calendar_add_note'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: isDark
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
          ),

          const SizedBox(height: 16),

          // Seçili Gün Bilgisi
          _buildSelectedDayInfo(
            context,
            selectedDate,
            selectedCycleDay,
            selectedIsPeriod,
            selectedIsPredicted,
            selectedIsFertile,
            selectedIsOvulation,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayInfo(
    BuildContext context,
    DateTime date,
    int? cycleDay,
    bool isPeriod,
    bool isPredicted,
    bool isFertile,
    bool isOvulation,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    // Durum metni ve rengi
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isPeriod) {
      statusText = context.tr('calendar_status_period');
      statusColor = AppColors.flowMedium;
      statusIcon = Icons.water_drop;
    } else if (isOvulation) {
      statusText = context.tr('calendar_status_ovulation');
      statusColor = Colors.deepPurple.shade400;
      statusIcon = Icons.star;
    } else if (isFertile) {
      statusText = context.tr('calendar_status_fertile');
      statusColor = Colors.pink.shade300;
      statusIcon = Icons.favorite;
    } else if (isPredicted) {
      statusText = context.tr('calendar_status_predicted');
      statusColor = AppColors.flowLight;
      statusIcon = Icons.water_drop_outlined;
    } else {
      statusText = context.tr('calendar_status_normal');
      statusColor = Colors.grey;
      statusIcon = Icons.circle_outlined;
    }

    final dateStr = '${date.day} ${context.shortMonthName(date.month)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(15) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (cycleDay != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
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
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(statusIcon, size: 18, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.labelLarge?.copyWith(fontSize: 10)),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  final DateTime date;
  final bool isFaded;

  const _DayTile({required this.date, required this.isFaded});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<CalendarViewModel>();
    final isSelected = context.select<CalendarViewModel, bool>(
      (v) => DateUtils.isSameDay(date, v.selectedDate),
    );
    final isPeriod = context.select<CalendarViewModel, bool>(
      (v) => v.isPeriodDay(date),
    );
    final isPredicted = context.select<CalendarViewModel, bool>(
      (v) => v.cycleInfo.isPredictedPeriod(date),
    );
    final isFertile = context.select<CalendarViewModel, bool>(
      (v) => v.cycleInfo.isFertile(date),
    );
    final isOvulation = context.select<CalendarViewModel, bool>(
      (v) => v.cycleInfo.isOvulationDay(date),
    );

    final dailyLog = context.select<CalendarViewModel, DailyLog>(
      (v) => v.getDailyLogForDate(date),
    );
    final hasLog =
        dailyLog.symptoms.isNotEmpty ||
        dailyLog.moods.isNotEmpty ||
        dailyLog.flowIntensity != null ||
        (dailyLog.notes != null && dailyLog.notes!.isNotEmpty);

    final isToday = DateUtils.isSameDay(date, DateTime.now());

    // Ardışık gün kontrolü (bağlantı barları için)
    final hasPeriodBefore =
        isPeriod &&
        context.select<CalendarViewModel, bool>(
          (v) => v.isPeriodDay(date.subtract(const Duration(days: 1))),
        );
    final hasPeriodAfter =
        isPeriod &&
        context.select<CalendarViewModel, bool>(
          (v) => v.isPeriodDay(date.add(const Duration(days: 1))),
        );

    final hasPredictedBefore =
        isPredicted &&
        !isPeriod &&
        context.select<CalendarViewModel, bool>(
          (v) => v.cycleInfo.isPredictedPeriod(
            date.subtract(const Duration(days: 1)),
          ),
        );
    final hasPredictedAfter =
        isPredicted &&
        !isPeriod &&
        context.select<CalendarViewModel, bool>(
          (v) =>
              v.cycleInfo.isPredictedPeriod(date.add(const Duration(days: 1))),
        );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- Renk Hesaplamaları ---
    Color textColor;
    if (isFaded) {
      textColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    } else if (isPeriod) {
      textColor = Colors.white;
    } else if (isSelected) {
      textColor = Colors.white;
    } else if (isToday) {
      textColor = theme.colorScheme.primary;
    } else {
      textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    }

    return GestureDetector(
      onTap: () {
        viewModel.selectDate(date);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Period bağlantı barı ──
            if (isPeriod && (hasPeriodBefore || hasPeriodAfter))
              Positioned(
                left: hasPeriodBefore ? 0 : 12,
                right: hasPeriodAfter ? 0 : 12,
                top: 10,
                bottom: 14,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.flowMedium,
                    borderRadius: BorderRadius.horizontal(
                      left: hasPeriodBefore
                          ? Radius.zero
                          : const Radius.circular(20),
                      right: hasPeriodAfter
                          ? Radius.zero
                          : const Radius.circular(20),
                    ),
                  ),
                ),
              ),

            // ── Predicted period bağlantı barı ──
            if (isPredicted &&
                !isPeriod &&
                (hasPredictedBefore || hasPredictedAfter))
              Positioned(
                left: hasPredictedBefore ? 0 : 12,
                right: hasPredictedAfter ? 0 : 12,
                top: 10,
                bottom: 14,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.flowLight.withAlpha(isDark ? 30 : 50),
                    borderRadius: BorderRadius.horizontal(
                      left: hasPredictedBefore
                          ? Radius.zero
                          : const Radius.circular(20),
                      right: hasPredictedAfter
                          ? Radius.zero
                          : const Radius.circular(20),
                    ),
                  ),
                ),
              ),

            // ── Ana gün hücresi ──
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Gün numarası dairesi
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    // Arka plan rengi
                    color: _getCircleBgColor(
                      isPeriod,
                      isSelected,
                      isPredicted,
                      isFertile,
                      isDark,
                      theme,
                    ),
                    shape: BoxShape.circle,
                    // Seçim halkası — her zaman görünür
                    border: _getCircleBorder(
                      isSelected,
                      isPeriod,
                      isToday,
                      isFaded,
                      theme,
                      isDark,
                    ),
                    // Seçim gölge efekti
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: isPeriod
                                  ? AppColors.flowMedium.withAlpha(80)
                                  : theme.colorScheme.primary.withAlpha(60),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: (isSelected || isPeriod || isToday)
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 3),

                // Alt gösterge noktaları
                SizedBox(
                  height: 8,
                  child: _buildBottomIndicator(
                    isOvulation: isOvulation,
                    isFertile: isFertile,
                    isPeriod: isPeriod,
                    hasLog: hasLog,
                    isToday: isToday,
                    isSelected: isSelected,
                    isFaded: isFaded,
                    theme: theme,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getCircleBgColor(
    bool isPeriod,
    bool isSelected,
    bool isPredicted,
    bool isFertile,
    bool isDark,
    ThemeData theme,
  ) {
    if (isPeriod && isSelected) {
      return AppColors.flowMedium;
    } else if (isPeriod) {
      return AppColors.flowMedium;
    } else if (isSelected) {
      return theme.colorScheme.primary;
    } else if (isPredicted) {
      return AppColors.flowLight.withAlpha(isDark ? 20 : 35);
    } else if (isFertile) {
      return isDark
          ? AppColors.fertileLight.withAlpha(15)
          : AppColors.fertileLight.withAlpha(30);
    }
    return Colors.transparent;
  }

  Border? _getCircleBorder(
    bool isSelected,
    bool isPeriod,
    bool isToday,
    bool isFaded,
    ThemeData theme,
    bool isDark,
  ) {
    if (isSelected && isPeriod) {
      // Seçili regl günü: beyaz halka ile göster
      return Border.all(color: Colors.white, width: 2.5);
    } else if (isSelected) {
      // Seçili normal gün: primary renk halkası
      return Border.all(color: theme.colorScheme.primary, width: 2.5);
    } else if (isToday && !isFaded && !isPeriod) {
      // Bugün: ince halka
      return Border.all(
        color: theme.colorScheme.primary.withAlpha(isDark ? 150 : 120),
        width: 1.5,
      );
    }
    return null;
  }

  Widget _buildBottomIndicator({
    required bool isOvulation,
    required bool isFertile,
    required bool isPeriod,
    required bool hasLog,
    required bool isToday,
    required bool isSelected,
    required bool isFaded,
    required ThemeData theme,
    required bool isDark,
  }) {
    if (isFaded) return const SizedBox.shrink();

    List<Widget> dots = [];

    // Yumurtlama noktası
    if (isOvulation) {
      dots.add(_dot(Colors.deepPurple.shade400, 6));
    }
    // Doğurganlık noktası
    else if (isFertile && !isPeriod) {
      dots.add(
        _dot(isDark ? Colors.pink.shade300 : theme.colorScheme.primary, 5),
      );
    }

    // Log noktası (yumurtlama/doğurganlık varsa ek olarak)
    if (hasLog && !isPeriod) {
      dots.add(_dot(isDark ? Colors.grey.shade500 : Colors.grey.shade400, 4));
    }

    if (dots.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: dots,
    );
  }

  Widget _dot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
