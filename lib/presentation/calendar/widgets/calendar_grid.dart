import 'package:flutter/material.dart';
import '../../../design_system/app_contrast.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/date_names.dart';
import '../../../domain/models/daily_log.dart';

import 'package:provider/provider.dart';
import '../view_models/calendar_view_model.dart';

/// Ayın ızgarası ve açıklama satırı.
///
/// Yalnızca takvimi gösterir: seçili günün bilgisi ve o güne uygulanan
/// eylemler [CalendarDayHeader]'ın işi. Eskiden ikisi de burada duruyordu ve
/// seçili gün bilgisi, alttaki özet bölümüyle birebir tekrar ediyordu.
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

    // Izgara ekranın iki kenarına yapışık, yalnızca altı yuvarlak bir paneldi
    // ve gölgesi %2 opaklıktaydı — ana ekrandaki kartlarla aynı dili
    // konuşmuyordu. Artık paylaşılan kart bileşeni kullanılıyor.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: AppCard(
        // Regl aralığı çubuğu satırın iki ucuna kadar uzuyor; dar boşlukta
        // kartın yuvarlak köşesinde kesiliyordu.
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
        child: Column(
          children: [
            // Ay Navigasyonu
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => viewModel.previousMonth(),
                    icon: const Icon(Icons.chevron_left),
                    color: theme.textTheme.labelLarge?.color,
                    tooltip: context.tr('calendar_previous_month'),
                  ),
                  Expanded(
                    child: Text(
                      context.tr(
                        'calendar_month_year',
                        params: {
                          'month': currentMonthName,
                          'year': year.toString(),
                        },
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => viewModel.nextMonth(),
                    icon: const Icon(Icons.chevron_right),
                    color: theme.textTheme.labelLarge?.color,
                    tooltip: context.tr('calendar_next_month'),
                  ),
                ],
              ),
            ),

            // "Bugüne dön" — yalnızca başka bir aya gidildiğinde görünür.
            // Aksi halde kullanıcı ok düğmesine ay sayısı kadar basmak zorunda.
            if (!viewModel.isViewingCurrentMonth)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton.icon(
                  onPressed: viewModel.goToToday,
                  icon: const Icon(Icons.today, size: 16),
                  label: Text(context.tr('calendar_jump_today')),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    foregroundColor: theme.colorScheme.primary,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            // Haftanın Günleri Başlığı.
            // Sabit 48px genişlik yerine eşit paylaşım: dar ekranlarda
            // (7 × 48 = 336px) satır taşıyordu.
            Row(
              children: daysOfWeek.map((day) {
                return Expanded(
                  child: Text(
                    day.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
              // Hücre içeriği 47px (36 daire + 3 boşluk + 8 nokta). 0.85 oranı
              // hücreyi 62px yapıyor, boşa giden 15px × 6 satır yüzünden eylem
              // düğmeleri ekranın altında kalıyordu.
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 0,
                childAspectRatio: 1.0,
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
                    Duration(
                      days: index - (previousMonthFill + daysInMonth) + 1,
                    ),
                  );
                }

                return _DayTile(date: date, isFaded: isFaded);
              },
            ),

            const SizedBox(height: 12),

            // Açıklamalar (Legend)
            //
            // Sabit bir Row idi; dört etiket tek satıra sığmak zorundaydı.
            // Uzun çevirilerde (ör. Almanca "Fruchtbares Fenster") taşıyordu.
            // Wrap ile gerektiğinde alt satıra iniyor.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 14,
                runSpacing: 8,
                children: [
                  _buildLegendItem(
                    context,
                    context.tokens.flow,
                    context.tr('calendar_legend_period'),
                  ),
                  _buildLegendItem(
                    context,
                    context.tokens.flowSoft,
                    context.tr('calendar_legend_predicted'),
                  ),
                  // Hormonal doğum kontrolünde takvimde doğurganlık ve
                  // yumurtlama işareti çizilmiyor; açıklama satırında da
                  // görünmemeli, yoksa var olmayan renkleri tarif ediyor.
                  if (context.select<CalendarViewModel, bool>(
                    (v) => v.cycleInfo.fertilityTracked,
                  )) ...[
                    // Koyu temada `secondaryPinkDark` kullanılıyordu: zemine
                    // çok yakın bir ton, nokta görünmüyordu. Üstelik hücrenin
                    // gerçekte boyadığı renk bu değil — açıklama ile takvim
                    // farklı şeyler söylüyordu.
                    _buildLegendItem(
                      context,
                      context.tokens.fertile,
                      context.tr('calendar_legend_fertility'),
                    ),
                    _buildLegendItem(
                      context,
                      context.tokens.ovulation,
                      context.tr('calendar_legend_ovulation'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            // Doğurganlık tonu bilerek soluk — hücrede zemine serilen tülü
            // temsil ediyor. Açık temada beyaz yüzeye karşı 1.46:1 kalıyor,
            // yani nokta olarak seçilmiyordu. Saç teli inceliğinde bir
            // çerçeve, dolgunun açıklığından bağımsız olarak sınırı veriyor.
            border: Border.all(color: context.tokens.border),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(fontSize: 11),
        ),
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
      (v) => v.isPredictedPeriodDay(date),
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
          (v) => v.isPredictedPeriodDay(date.subtract(const Duration(days: 1))),
        );
    final hasPredictedAfter =
        isPredicted &&
        !isPeriod &&
        context.select<CalendarViewModel, bool>(
          (v) => v.isPredictedPeriodDay(date.add(const Duration(days: 1))),
        );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- Renk Hesaplamaları ---
    Color textColor;
    if (isFaded) {
      textColor = context.tokens.textFaint;
    } else if (isPeriod) {
      // Akış rengi koyu temada açık pembe; beyaz metin orada okunmuyor.
      textColor = AppContrast.on(context.tokens.flow);
    } else if (isSelected) {
      textColor = theme.colorScheme.onPrimary;
    } else if (isToday) {
      textColor = theme.colorScheme.primary;
    } else {
      textColor = context.tokens.text;
    }

    return GestureDetector(
      onTap: () => viewModel.selectDate(date),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gün dairesi ve ardışık günleri birleştiren bant.
          //
          // Bant, dairenin bulunduğu 36px'lik şeridin *içinde* duruyor.
          // Eskiden hücrenin tamamına göre sabit değerlerle (top: 10,
          // bottom: 14) konumlanıyordu; hücre yüksekliği değiştiğinde
          // daireyle hizası kayıyordu.
          SizedBox(
            height: 36,
            // Bant hücrenin iki ucuna kadar uzanabilmeli. Genişlik
            // verilmezse Stack yalnızca daire kadar (36px) geniş oluyor ve
            // ardışık günler arasında boşluk kalıyor.
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Bandın yuvarlak ucu tam dairenin kenarında başlasın:
                // hücre genişliği cihazdan cihaza değişiyor.
                final inset = ((constraints.maxWidth - 36) / 2).clamp(
                  0.0,
                  24.0,
                );
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isPeriod && (hasPeriodBefore || hasPeriodAfter))
                      _buildConnector(
                        color: context.tokens.flow,
                        openLeft: hasPeriodBefore,
                        openRight: hasPeriodAfter,
                        inset: inset,
                      ),

                    if (isPredicted &&
                        !isPeriod &&
                        (hasPredictedBefore || hasPredictedAfter))
                      _buildConnector(
                        color: context.tokens.flowSoft.withAlpha(
                          isDark ? 30 : 50,
                        ),
                        openLeft: hasPredictedBefore,
                        openRight: hasPredictedAfter,
                        inset: inset,
                      ),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
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
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: isPeriod
                                      ? context.tokens.flow.withAlpha(80)
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
                  ],
                );
              },
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
              isFaded: isFaded,
              theme: theme,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Ardışık regl (veya tahmin) günlerini görsel olarak birleştiren bant.
  ///
  /// Bant, komşu gün de aynı türdeyse o yöne doğru hücre kenarına kadar
  /// uzanır ve köşesi düz kalır; değilse dairenin hizasında yuvarlanır.
  Widget _buildConnector({
    required Color color,
    required bool openLeft,
    required bool openRight,
    required double inset,
  }) {
    return Positioned(
      left: openLeft ? 0 : inset,
      right: openRight ? 0 : inset,
      top: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.horizontal(
            left: openLeft ? Radius.zero : const Radius.circular(20),
            right: openRight ? Radius.zero : const Radius.circular(20),
          ),
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
    // `context` bu yardımcıda yok; roller temadan okunuyor.
    final t = theme.extension<AppTokens>() ?? AppTokens.light;

    if (isPeriod && isSelected) {
      return t.flow;
    } else if (isPeriod) {
      return t.flow;
    } else if (isSelected) {
      return theme.colorScheme.primary;
    } else if (isPredicted) {
      return t.flowSoft.withAlpha(isDark ? 20 : 35);
    } else if (isFertile) {
      return isDark
          // Koyu temada %6 opaklıktaydı; doğurgan günler hiç görünmüyordu.
          ? t.fertile.withAlpha(45)
          : t.fertile.withAlpha(30);
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
    final t = theme.extension<AppTokens>() ?? AppTokens.light;
    if (isSelected && isPeriod) {
      // Seçili regl günü: dolgunun üstünde okunan halka
      return Border.all(color: AppContrast.on(t.flow), width: 2.5);
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
    required bool isFaded,
    required ThemeData theme,
    required bool isDark,
  }) {
    if (isFaded) return const SizedBox.shrink();

    // `context` bu yardımcıda yok; roller temadan okunuyor.
    final t = theme.extension<AppTokens>() ?? AppTokens.light;
    List<Widget> dots = [];

    // Yumurtlama noktası
    if (isOvulation) {
      dots.add(_dot(t.ovulation, 6));
    }
    // Doğurganlık noktası
    else if (isFertile && !isPeriod) {
      dots.add(_dot(t.flow, 5));
    }

    // Log noktası (yumurtlama/doğurganlık varsa ek olarak)
    if (hasLog && !isPeriod) {
      dots.add(_dot(t.textFaint, 4));
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
