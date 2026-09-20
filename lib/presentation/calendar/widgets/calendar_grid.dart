import 'package:flutter/material.dart';
import '../../../design_system/app_contrast.dart';
import '../../../design_system/app_card.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/date_names.dart';
import '../../../domain/models/daily_log.dart';

import 'package:provider/provider.dart';
import '../view_models/calendar_view_model.dart';
import '../../../domain/models/log_vocabulary.dart';

/// Ayın ızgarası ve açıklama satırı.
///
/// Yalnızca takvimi gösterir: seçili günün bilgisi ve o güne uygulanan
/// eylemler [CalendarDayHeader]'ın işi. Eskiden ikisi de burada duruyordu ve
/// seçili gün bilgisi, alttaki özet bölümüyle birebir tekrar ediyordu.
/// [date] takvim ızgarasında satırın **ilk** hücresinde mi?
///
/// Izgara her zaman pazartesi ile başlıyor (`previousMonthFill =
/// firstWeekday - 1`), yani pazartesi ilk sütun, pazar son sütun.
bool startsCalendarRow(DateTime date) => date.weekday == DateTime.monday;

/// [date] satırın **son** hücresinde mi?
bool endsCalendarRow(DateTime date) => date.weekday == DateTime.sunday;

/// Gün hücresinin içeriği: daire + boşluk + gösterge.
///
/// Hücre yüksekliği eskiden genişlikten türetiliyordu (`childAspectRatio:
/// 1.0`). Takvim kartının iç genişliği 7 × 47 = 329 pt'nin altına düşünce
/// hücre içeriğinden kısa kalıyor ve her hafta satırında sarı taşma şeridi
/// çıkıyordu: iPhone 16e'de (390 pt ekran → 46.3 pt hücre) 0.7 pt, daha dar
/// yerlerde daha fazla. iPhone 17 Pro'da (402 pt) hücre 48 pt olduğu için
/// görünmüyordu — cihaza göre değişen bir hata.
/// Bandın hücre kenarına aktığı uçta sönme payı (hücre genişliğinin oranı).
///
/// Dönem hafta sınırını aşarken kullanılıyor: bant kenara kadar gidip
/// tamamen saydamlaşıyor, böylece "kopmuş" değil "devam ediyor" okunuyor.
const double _continuesFade = 0.45;

/// İki gün birleşirken oluşan dikişteki alfa ve sönme payı.
///
/// Yan yana iki hücrenin bandı aynı noktada bitip başlıyordu. Tam opak iki
/// dikdörtgen kenar kenara gelince aradaki sınır cihaz pikseline denk
/// gelmiyor ve zemin ince bir çizgi hâlinde sızıyordu — ölçüldü: bandın
/// `(178, 74, 102)` rengi dikişte `(197, 118, 139)`'a açılıyordu, tek piksel
/// genişliğinde keskin bir çizgi.
///
/// Dikişteki renk, bandın rengi ile onun "geri çekilen" tonu arasında bu
/// oranda karıştırılıyor. `flowSoft` açık temada `flow`'dan açık, koyu
/// temada koyu — yani iki temada da zemine doğru çekiliyor.
///
/// Karışım **opak**: saydamlık kullanılsaydı bindirme yerinde iki kat
/// boyanıp koyu bir çizgi çıkardı. Opak aynı renk üst üste gelince hiçbir
/// iz bırakmıyor.
const double _seamBlend = 0.42;

/// Dikişin bandın renk farkından koruduğu oran.
///
/// Regl bandında dikiş rengi `flow` ile `flowSoft` arası %42'de; bu, zemine
/// olan renk farkının %87'sini koruyor. Tahmin bandı tül olduğu için oradaki
/// karşılığı doğrudan tülün inceltilmesi — aynı oran kullanılıyor ki iki
/// bant aynı dili konuşsun.
const double _seamVeil = 0.87;

/// Düz uçların komşuya doğru taşma payı (pt).
///
/// İki kabın kenarı aynı noktada bitiyordu. Her kenar ayrı ayrı kenar
/// yumuşatmadan geçtiği için sınır pikselini ikisi de yarım kaplıyor ve
/// arada zemin kalıyordu — ölçüldü: dikiş pikseli %26 zemin. Yarım puntoluk
/// bindirme bunu kapatıyor.
const double _seamOverlap = 0.5;

/// Tahmin bandının rengi — tül **zemine önceden karıştırılmış** hâli.
///
/// Bant hâlâ `flowSoft`'un ince bir katmanı gibi görünüyor ama artık opak.
/// Fark ettiği tek yer dikiş: yarı saydam iki kap yan yana geldiğinde
/// aralarından zemin sızıyor ve bindirilemiyorlar, çünkü üst üste gelen iki
/// tül koyu bir çizgi bırakır. Opak renk bindirilebiliyor.
///
/// Görünüm değişmiyor: bandın üstündeki gün dairesi de tül ve kompozit
/// birleşmeli — `zemin → tül bant → tül daire` ile
/// `karışmış bant → tül daire` aynı pikseli veriyor.
///
/// Bandın altında başka bir şey çizilmediği için zemin kesin olarak
/// biliniyor: bağlayıcı hücrenin `Stack`'indeki ilk çocuk, kart da
/// [AppCard] ile `surface` boyuyor.
Color predictedBandColor(AppTokens t, bool isDark) =>
    Color.alphaBlend(t.flowSoft.withAlpha(isDark ? 100 : 90), t.surface);

/// Tahmin bandının dikişindeki renk: aynı tül, [_seamVeil] kadar incesi.
Color predictedSeamColor(AppTokens t, bool isDark) => Color.alphaBlend(
  t.flowSoft.withAlpha(((isDark ? 100 : 90) * _seamVeil).round()),
  t.surface,
);

const double _dayCircleSize = 36;
const double _dayCircleToDots = 3;
const double _dayDotsSize = 8;
const double _dayTileContentHeight =
    _dayCircleSize + _dayCircleToDots + _dayDotsSize;

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
            LayoutBuilder(
              builder: (context, constraints) {
                // Hücre kare olsun ama içeriğinden kısa olmasın. Oran tek
                // başına genişliğe bağlı olduğu için dar ekranda hücreyi
                // içeriğin altına düşürüyordu (bkz. [_dayTileContentHeight]).
                final cell = constraints.maxWidth / 7;
                final rowHeight = cell < _dayTileContentHeight
                    ? _dayTileContentHeight
                    : cell;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalItems,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 2,
                    crossAxisSpacing: 0,
                    mainAxisExtent: rowHeight,
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
                      date = DateTime(
                        year,
                        month,
                        index - previousMonthFill + 1,
                      );
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
                );
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
                  // Lekelenme kanama ama regl değil: rengi regl rengiyle
                  // aynı, biçimi halka. Dolu nokta doğurganlık işaretiyle
                  // karışırdı.
                  _buildLegendItem(
                    context,
                    context.tokens.flow,
                    context.tr('calendar_legend_spotting'),
                    outlined: true,
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

  /// [outlined] işareti içi boş bir halka olarak çizer.
  ///
  /// Takvimde lekelenme halka; açıklama da halka göstermeli. Dolu nokta
  /// çizseydik açıklama ile takvim yine farklı şeyler söylerdi.
  Widget _buildLegendItem(
    BuildContext context,
    Color color,
    String label, {
    bool outlined = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : color,
            shape: BoxShape.circle,
            // Doğurganlık tonu bilerek soluk — hücrede zemine serilen tülü
            // temsil ediyor. Açık temada beyaz yüzeye karşı 1.46:1 kalıyor,
            // yani nokta olarak seçilmiyordu. Saç teli inceliğinde bir
            // çerçeve, dolgunun açıklığından bağımsız olarak sınırı veriyor.
            border: Border.all(
              color: outlined ? color : context.tokens.border,
              width: outlined ? 1.5 : 1,
            ),
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

    // Lekelenme günü: kanama var ama regl değil. Regl gününde ayrıca
    // gösterilmiyor — orada zaten bandın kendisi kanamayı anlatıyor.
    final isSpotting =
        !isPeriod && dailyLog.flowIntensity == LogVocabulary.spotting;

    final isToday = DateUtils.isSameDay(date, DateTime.now());

    // Ardışık gün kontrolü (bağlantı barları için).
    //
    // Komşuluk yalnızca tarihe bakıyordu. Satır sonundaki pazar günü için
    // "ertesi gün de regl" doğru ama o gün takvimde yan hücrede değil, bir
    // alt satırın başında: çubuk hücrenin sağ kenarına kadar düz uzanıp
    // hiçbir şeye bağlanmadan kesiliyordu. Aynısı satır başındaki
    // pazartesi için solda oluyordu.
    final rowStart = startsCalendarRow(date);
    final rowEnd = endsCalendarRow(date);

    // Önce "dönem burada sürüyor mu" (tarih), sonra "komşusu yanımda mı"
    // (satır). İkisi ayrı: satır sonundaki pazar için dönem sürüyor ama
    // komşu yan hücrede değil, bir alt satırın başında.
    final periodPrev =
        isPeriod &&
        context.select<CalendarViewModel, bool>(
          (v) => v.isPeriodDay(date.subtract(const Duration(days: 1))),
        );
    final periodNext =
        isPeriod &&
        context.select<CalendarViewModel, bool>(
          (v) => v.isPeriodDay(date.add(const Duration(days: 1))),
        );

    final hasPeriodBefore = periodPrev && !rowStart;
    final hasPeriodAfter = periodNext && !rowEnd;
    final periodContinuesLeft = periodPrev && rowStart;
    final periodContinuesRight = periodNext && rowEnd;

    final predictedPrev =
        isPredicted &&
        !isPeriod &&
        context.select<CalendarViewModel, bool>(
          (v) => v.isPredictedPeriodDay(date.subtract(const Duration(days: 1))),
        );
    final predictedNext =
        isPredicted &&
        !isPeriod &&
        context.select<CalendarViewModel, bool>(
          (v) => v.isPredictedPeriodDay(date.add(const Duration(days: 1))),
        );

    final hasPredictedBefore = predictedPrev && !rowStart;
    final hasPredictedAfter = predictedNext && !rowEnd;
    final predictedContinuesLeft = predictedPrev && rowStart;
    final predictedContinuesRight = predictedNext && rowEnd;

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
            height: _dayCircleSize,
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
                  // Bandın yarım puntoluk bindirmesi hücrenin dışına taşıyor;
                  // varsayılan kırpma onu geri kesip dikişi geri getiriyordu.
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (isPeriod &&
                        (hasPeriodBefore ||
                            hasPeriodAfter ||
                            periodContinuesLeft ||
                            periodContinuesRight))
                      _buildConnector(
                        color: context.tokens.flow,
                        seamColor: Color.lerp(
                          context.tokens.flow,
                          context.tokens.flowSoft,
                          _seamBlend,
                        )!,
                        openLeft: hasPeriodBefore,
                        openRight: hasPeriodAfter,
                        continuesLeft: periodContinuesLeft,
                        continuesRight: periodContinuesRight,
                        inset: inset,
                        cellWidth: constraints.maxWidth,
                      ),

                    if (isPredicted &&
                        !isPeriod &&
                        (hasPredictedBefore ||
                            hasPredictedAfter ||
                            predictedContinuesLeft ||
                            predictedContinuesRight))
                      _buildConnector(
                        // Bant zemine karşı koyuda 1.11:1, açıkta 1.21:1
                        // kalıyordu — ölçülebilir ama zor seçiliyordu.
                        // Koyuda daha çok opaklık gerekiyor: açık zeminde
                        // renk farkı da yardım ediyor, koyuda hem parlaklık
                        // hem renk sıkışıyor. Kayıtlı regl tam opak (5.17:1),
                        // yani "dolu vs tül" ayrımı bu değerlerde bozulmuyor.
                        color: predictedBandColor(context.tokens, isDark),
                        seamColor: predictedSeamColor(context.tokens, isDark),
                        openLeft: hasPredictedBefore,
                        openRight: hasPredictedAfter,
                        continuesLeft: predictedContinuesLeft,
                        continuesRight: predictedContinuesRight,
                        inset: inset,
                        cellWidth: constraints.maxWidth,
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

          const SizedBox(height: _dayCircleToDots),

          // Alt gösterge noktaları
          SizedBox(
            height: _dayDotsSize,
            child: _buildBottomIndicator(
              isOvulation: isOvulation,
              isFertile: isFertile,
              isPeriod: isPeriod,
              isSpotting: isSpotting,
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
  /// Ardışık günleri birleştiren bant.
  ///
  /// Her uç üç durumdan birinde:
  ///
  /// * **kapalı** — dönem burada bitiyor: içeriden başlayan yuvarlak uç.
  /// * **açık** — yandaki hücre de aynı döneme ait: düz uç, hücre kenarına
  ///   kadar; iki hücrenin bandı birleşip tek pill oluyor.
  /// * **devam** — dönem sürüyor ama sonraki gün bir alt satırın başında.
  ///   Bant hücre kenarına kadar gidiyor ve giderken **sönüyor**.
  ///
  /// Üçüncüsü olmadan hafta sınırını aşan dönem iki ayrı dönem gibi
  /// okunuyordu: pazar tek başına bir daire, pazartesi ayrı bir pill.
  /// Düz kesilen bir uç da işe yaramıyor — kartın kenar boşluğunda durduğu
  /// için "devam ediyor" değil "kopmuş" görünüyor. Sönen uç, bandın kenarın
  /// ötesine aktığını anlatıyor.
  Widget _buildConnector({
    required Color color,
    required Color seamColor,
    required bool openLeft,
    required bool openRight,
    required bool continuesLeft,
    required bool continuesRight,
    required double inset,
    required double cellWidth,
  }) {
    final flatLeft = openLeft || continuesLeft;
    final flatRight = openRight || continuesRight;

    // Bandın genişliği: kapalı uçlar daireden başlıyor, düz uçlar hücre
    // kenarına dayanıyor.
    final width =
        cellWidth - (flatLeft ? 0 : inset) - (flatRight ? 0 : inset);

    // Dikişteki sönme **tam olarak iki daire arasındaki boşluğa** oturmalı.
    // Daha geniş olursa sönme dairenin altında başlar: daire tam opak
    // olduğu için kenarında sert bir basamak çıkıyor (ölçüldü: iki pikselde
    // 98'den 134'e). Boşluk hücrenin `inset` kadarı.
    final seamFade = width <= 0 ? 0.0 : (inset / width).clamp(0.0, 0.45);

    // Her uç kendi profilini taşıyor: `(kenardaki renk, sönme payı)`.
    (Color, double)? profile(bool open, bool continues) {
      if (continues) return (color.withAlpha(0), _continuesFade);
      if (open && seamFade > 0) return (seamColor, seamFade);
      return null; // kapalı uç: yuvarlak kapak, sönme yok
    }

    final left = profile(openLeft, continuesLeft);
    final right = profile(openRight, continuesRight);

    final colors = <Color>[];
    final stops = <double>[];
    if (left != null) {
      colors.addAll([left.$1, color]);
      stops.addAll([0.0, left.$2]);
    } else {
      colors.add(color);
      stops.add(0.0);
    }
    if (right != null) {
      colors.addAll([color, right.$1]);
      stops.addAll([1 - right.$2, 1.0]);
    } else {
      colors.add(color);
      stops.add(1.0);
    }

    // Bindirme yalnızca dikiş rengi **opak** olduğunda güvenli: saydam bir
    // bant üst üste gelince iki kat boyanır ve açık çizginin yerini koyu bir
    // çizgi alır. Tahmin bandı tül olduğu için taşmıyor — zaten o kadar
    // açık ki dikişi görünmüyor.
    final overlaps = seamColor.a >= 1;

    return Positioned(
      // Açık uçlar komşuya yarım punto taşıyor: kenarların aynı noktada
      // bitmesi araya zemin sızdırıyordu.
      left: (openLeft && overlaps) ? -_seamOverlap : (flatLeft ? 0 : inset),
      right: (openRight && overlaps) ? -_seamOverlap : (flatRight ? 0 : inset),
      top: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, stops: stops),
          borderRadius: BorderRadius.horizontal(
            left: flatLeft ? Radius.zero : const Radius.circular(20),
            right: flatRight ? Radius.zero : const Radius.circular(20),
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
      // Daire ile bant tek şekil gibi görünsün diye ikisi aynı oranda
      // (bant opaklığının ~%65'i).
      return t.flowSoft.withAlpha(isDark ? 65 : 62);
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
    required bool isSpotting,
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

    // Lekelenme halkası. Regl rengiyle aynı ton — kanama olduğunu söylüyor;
    // içi boş biçim ise regl gününden ayırıyor. Dolu bir nokta doğurganlık
    // işaretiyle karışırdı, o da aynı rengi kullanıyor.
    if (isSpotting) {
      dots.add(_ring(t.flow, 6));
    }

    // Log noktası (yumurtlama/doğurganlık varsa ek olarak).
    //
    // Lekelenme zaten kendi halkasını çizdiği için burada tekrar edilmiyor;
    // yoksa aynı gün iki gri nokta görünüyordu.
    if (hasLog && !isPeriod && !isSpotting) {
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

  /// İçi boş işaret.
  Widget _ring(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }
}
