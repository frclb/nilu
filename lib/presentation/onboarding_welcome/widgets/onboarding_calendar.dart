import 'package:flutter/material.dart';

import '../../../design_system/app_card.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tappable.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../../localization/date_names.dart';

/// Kurulumun ay takvimi: son regl ve doğum tarihi aynı takvimle seçiliyor.
///
/// Doğum ekranı Flutter'ın hazır takvimini (`CalendarDatePicker`)
/// kullanıyordu: görünüşü son regl ekranındakinden farklıydı, gün hücreleri
/// 42 pt yüksekliğindeydi (iOS'un önerdiği 44'ün altı) ve ekranı tek sayfaya
/// sığdıran ölçüm (iç boy sorgusu) onda çalışmıyordu. Hücreler satır
/// satır çiziliyor; ızgara (`GridView`) de aynı sebeple kullanılmıyor.
class OnboardingCalendar extends StatefulWidget {
  const OnboardingCalendar({
    super.key,
    required this.selected,
    required this.onSelected,
    this.firstDate,
    this.lastDate,
    this.footer,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  /// Seçilebilecek en erken ve en geç gün; dışındakiler soluk ve kapalı.
  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Kartın altında, takvimle aynı yüzeyde (ör. seçilen günün anlamı).
  final Widget? footer;

  /// Satır yüksekliği: iOS'un önerdiği 44 pt'lik dokunma hedefi. Altı
  /// satırlı aylarda (ör. Kasım 2026) takvim ekranın en uzun öğesi; fazlası
  /// kurulum ekranını küçültüyordu.
  static const double rowHeight = 44;

  @override
  State<OnboardingCalendar> createState() => _OnboardingCalendarState();
}

class _OnboardingCalendarState extends State<OnboardingCalendar> {
  late DateTime _month = DateTime(widget.selected.year, widget.selected.month);

  static const List<String> _weekDayKeys = [
    'calendar_day_mon',
    'calendar_day_tue',
    'calendar_day_wed',
    'calendar_day_thu',
    'calendar_day_fri',
    'calendar_day_sat',
    'calendar_day_sun',
  ];

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _allowed(DateTime date) {
    final first = widget.firstDate;
    final last = widget.lastDate;
    if (first != null && date.isBefore(_day(first))) return false;
    if (last != null && date.isAfter(_day(last))) return false;
    return true;
  }

  bool get _canGoBack {
    final first = widget.firstDate;
    return first == null || DateTime(first.year, first.month).isBefore(_month);
  }

  bool get _canGoForward {
    final last = widget.lastDate;
    return last == null || DateTime(last.year, last.month).isAfter(_month);
  }

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    Widget navButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback? onPressed,
    }) => IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      color: primary,
      disabledColor: t.textFaint,
      style: IconButton.styleFrom(
        backgroundColor: t.brandTint,
        minimumSize: const Size(44, 44),
      ),
    );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      // Yatay pay 10: gün hücreleri iOS'un önerdiği 44 pt'nin altına
      // düşmesin (16 iken 43,7 idi).
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: AppCard.decoration(t),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.monthYear(_month),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
                navButton(
                  icon: Icons.chevron_left,
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).previousMonthTooltip,
                  onPressed: _canGoBack ? () => _shift(-1) : null,
                ),
                const SizedBox(width: 6),
                navButton(
                  icon: Icons.chevron_right,
                  tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                  onPressed: _canGoForward ? () => _shift(1) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final key in _weekDayKeys)
                Expanded(
                  child: Text(
                    context.upper(context.tr(key)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: t.textFaint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          _grid(context),
          if (widget.footer case final footer?) ...[
            const SizedBox(height: 6),
            footer,
          ],
        ],
      ),
    );
  }

  Widget _grid(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final today = _day(DateTime.now());
    final selected = _day(widget.selected);
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    // 1: pazartesi … 7: pazar.
    final leading = DateTime(_month.year, _month.month).weekday - 1;

    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var d = 1; d <= daysInMonth; d++)
        _cell(
          context,
          date: DateTime(_month.year, _month.month, d),
          isSelected: DateTime(_month.year, _month.month, d) == selected,
          isToday: DateTime(_month.year, _month.month, d) == today,
          t: t,
          scheme: scheme,
        ),
    ];
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    return Column(
      children: [
        for (var r = 0; r < cells.length; r += 7)
          SizedBox(
            height: OnboardingCalendar.rowHeight,
            child: Row(
              children: [
                for (final cell in cells.sublist(r, r + 7))
                  Expanded(child: cell),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(
    BuildContext context, {
    required DateTime date,
    required bool isSelected,
    required bool isToday,
    required AppTokens t,
    required ColorScheme scheme,
  }) {
    final allowed = _allowed(date);
    final label = Text(
      '${date.day}',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 15,
        height: 1.1,
        fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? AppGradients.onMark
            : (allowed ? t.text : t.textFaint.withAlpha(110)),
      ),
    );
    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected ? AppGradients.mark(context) : null,
        // Bugün halkayla: tarih seçerken nerede durulduğu belli olsun.
        border: isToday && !isSelected
            ? Border.all(color: scheme.primary, width: 1.5)
            : null,
        boxShadow: isSelected ? AppShadows.floating(context) : null,
      ),
      child: Center(child: label),
    );
    if (!allowed) {
      return Semantics(
        label: context.dayMonthYear(date),
        enabled: false,
        excludeSemantics: true,
        child: Center(child: circle),
      );
    }
    return AppTappable(
      selected: isSelected,
      label: context.dayMonthYear(date),
      excludeChildSemantics: true,
      onTap: () => widget.onSelected(date),
      // Hücrenin tamamı dokunma alanı; görünen daire biraz küçük.
      child: Center(child: circle),
    );
  }
}
