import 'package:flutter/material.dart';
import '../../design_system/app_scrim.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/route_names.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localizations.dart';
import 'onboarding_progress.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = context.tokens.background;
    final cardColor = context.tokens.surface;
    final textMainColor = context.tokens.text;
    final textSecondaryColor = context.tokens.textMuted;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: bgColor,
      // Eylem çubuğu gövdenin değil `Scaffold`'un altında: içerik
      // sütununun içinde kalınca zemini geniş ekranda 600 pt'de
      // kesilip sayfanın üstünde sert kenarlı bir dikdörtgen
      // bırakıyordu. Burada tam genişlikte ve dibe sabitli.
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          border: Border(top: BorderSide(color: context.tokens.surfaceAlt)),
        ),
        child: AppContentWidth(
          // Zemin tam genişlikte, düğme okunur sütunda kalıyor.
          child: ElevatedButton(
            onPressed: () async {
              // Seçilen tarihi geçici olarak SharedPreferences'a kaydet
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                'onboarding_last_period_date',
                _selectedDate.toIso8601String(),
              );

              if (context.mounted) {
                context.pushNamed(RouteNames.onboardingPeriodLength);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: primaryColor.withAlpha(76),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.tr('onb_continue'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward),
              ],
            ),
          ),
        ),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: textMainColor),
                      onPressed: () => onboardingBack(context),
                    ),
                    const SizedBox(width: 48), // Spacer to balance back button
                  ],
                ),
              ),

              const OnboardingStepDots(step: OnboardingStep.lastPeriod),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('onb_last_period_title'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textMainColor,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('onb_last_period_desc'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: textSecondaryColor,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Calendar Container
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 340),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: context.tokens.border),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: AppScrim.veil(26),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                          ),
                          child: Column(
                            children: [
                              // Month Navigator
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.chevron_left,
                                      color: textMainColor,
                                    ),
                                    onPressed: _previousMonth,
                                    style: IconButton.styleFrom(
                                      hoverColor: context.tokens.surfaceAlt,
                                    ),
                                  ),
                                  Text(
                                    _getFormattedMonth(context, _currentMonth),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textMainColor,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.chevron_right,
                                      color: textMainColor,
                                    ),
                                    onPressed: _nextMonth,
                                    style: IconButton.styleFrom(
                                      hoverColor: context.tokens.surfaceAlt,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Days of Week
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: _weekDayKeys.map((key) {
                                  final day = context.tr(key);
                                  return SizedBox(
                                    width: 40,
                                    child: Text(
                                      day,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: context.tokens.textFaint,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Days Grid
                              _buildCalendarGrid(
                                primaryColor,
                                isDark,
                                textMainColor,
                                textSecondaryColor,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Hint
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.tokens.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.tokens.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  context.tr('onb_last_period_hint'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.tokens.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(
    Color primaryColor,
    bool isDark,
    Color textMainColor,
    Color textSecondaryColor,
  ) {
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
      gridItems.add(const SizedBox(width: 40, height: 40));
    }

    // Add days
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, i);
      final isSelected =
          _selectedDate.year == date.year &&
          _selectedDate.month == date.month &&
          _selectedDate.day == date.day;

      gridItems.add(
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? primaryColor : Colors.transparent,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withAlpha(76),
                        blurRadius: 8,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                '$i',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : (context.tokens.text),
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
      mainAxisSpacing: 8,
      crossAxisSpacing: 0,
      children: gridItems,
    );
  }

  String _getFormattedMonth(BuildContext context, DateTime date) {
    return '${context.monthName(date.month)} ${date.year}';
  }
}
