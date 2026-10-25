import '../../design_system/app_tappable.dart';
import 'package:flutter/material.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/route_names.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localizations.dart';
import 'onboarding_progress.dart';
import 'widgets/onboarding_chrome.dart';
import '../../localization/date_names.dart';
import '../../design_system/app_layout.dart';

class OnboardingLastPeriodScreen extends StatefulWidget {
  const OnboardingLastPeriodScreen({super.key});

  @override
  State<OnboardingLastPeriodScreen> createState() =>
      _OnboardingLastPeriodScreenState();
}

class _OnboardingLastPeriodScreenState
    extends State<OnboardingLastPeriodScreen> {
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  static const List<String> _weekDayKeys = [
    'calendar_day_mon',
    'calendar_day_tue',
    'calendar_day_wed',
    'calendar_day_thu',
    'calendar_day_fri',
    'calendar_day_sat',
    'calendar_day_sun',
  ];

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  Future<void> _continue() async {
    // Seçilen tarihi geçici olarak SharedPreferences'a kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'onboarding_last_period_date',
      _selectedDate.toIso8601String(),
    );

    if (mounted) {
      context.pushNamed(RouteNames.onboardingPeriodLength);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.background,
      // Eylem çubuğu gövdenin değil `Scaffold`'un altında: içerik
      // sütununun içinde kalınca zemini geniş ekranda 600 pt'de
      // kesilip sayfanın üstünde sert kenarlı bir dikdörtgen
      // bırakıyordu. Burada tam genişlikte ve dibe sabitli.
      bottomNavigationBar: OnboardingBottomBar(
        child: AppGradientButton(
          label: context.tr('onb_continue'),
          onPressed: _continue,
          radius: AppRadius.pill,
        ),
      ),
      body: AmbientBackground(
        child: AppContentWidth(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const OnboardingTopBar(),
                const OnboardingStepDots(step: OnboardingStep.lastPeriod),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OnboardingHeading(
                          tag: context.tr('cycle_settings_title'),
                          tagIcon: Icons.calendar_today_outlined,
                          title: context.tr('onb_last_period_title'),
                          description: context.tr('onb_last_period_desc'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(child: _buildCalendarCard(context)),
                        const SizedBox(height: AppSpacing.xl),
                        OnboardingNote(
                          text: context.tr('onb_last_period_hint'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const OnboardingPrivacyNote(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarCard(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    Widget navButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) => IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: primary, size: 22),
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
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      decoration: AppCard.decoration(t),
      child: Column(
        children: [
          // Ay başlığı ve gezinme
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.monthYear(_currentMonth),
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
                  onPressed: _previousMonth,
                ),
                const SizedBox(width: 6),
                navButton(
                  icon: Icons.chevron_right,
                  tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Haftanın günleri
          Row(
            children: _weekDayKeys.map((key) {
              return Expanded(
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
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          _buildCalendarGrid(context),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstDayOfMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month,
      1,
    );
    // 1: Monday, 7: Sunday
    final firstWeekday = firstDayOfMonth.weekday;

    // Calculate empty slots
    List<Widget> gridItems = [];
    for (int i = 1; i < firstWeekday; i++) {
      gridItems.add(const SizedBox.shrink());
    }

    // Add days
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      final isSelected =
          _selectedDate.year == date.year &&
          _selectedDate.month == date.month &&
          _selectedDate.day == date.day;
      final isToday = date == today;

      gridItems.add(
        AppTappable(
          selected: isSelected,
          label: '$i ${context.monthName(date.month)} ${date.year}',
          excludeChildSemantics: true,
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          // Hücrenin tamamı dokunma alanı; görünen daire biraz küçük.
          child: Center(
            child: AnimatedContainer(
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
              child: Center(
                child: Text(
                  '$i',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    height: 1.1,
                    fontWeight: isSelected || isToday
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected ? scheme.onPrimary : t.text,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 2,
      crossAxisSpacing: 0,
      children: gridItems,
    );
  }
}
