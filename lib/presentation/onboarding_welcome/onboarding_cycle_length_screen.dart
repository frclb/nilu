import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/navigation/route_names.dart';
import '../../data/repositories/cycle_settings_repository.dart';
import '../../data/repositories/period_repository.dart';
import '../../domain/models/period_log.dart';
import '../../presentation/calendar/view_models/calendar_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';

class OnboardingCycleLengthScreen extends StatefulWidget {
  const OnboardingCycleLengthScreen({super.key});

  @override
  State<OnboardingCycleLengthScreen> createState() =>
      _OnboardingCycleLengthScreenState();
}

class _OnboardingCycleLengthScreenState
    extends State<OnboardingCycleLengthScreen> {
  final FixedExtentScrollController _scrollController =
      FixedExtentScrollController(initialItem: 6); // Default 27 (21 + 6 = 27)
  int _selectedDays = 27;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final cycleSettingsRepo = CycleSettingsRepository();
    final periodRepo = PeriodRepository();
    const int defaultPeriodLength = 5;

    // 1. Döngü ayarlarını kaydet (ilk kurulum)
    await cycleSettingsRepo.saveInitialSettings(
      cycleLength: _selectedDays,
      periodLength: defaultPeriodLength,
    );

    // 2. Onboarding'de seçilen son regl tarihini oku
    final prefs = await SharedPreferences.getInstance();
    final lastPeriodDateStr = prefs.getString('onboarding_last_period_date');

    if (lastPeriodDateStr != null) {
      final lastPeriodDate = DateTime.tryParse(lastPeriodDateStr);
      if (lastPeriodDate != null) {
        // 3. PeriodLog oluştur ve kaydet
        final startDate = DateTime(
          lastPeriodDate.year,
          lastPeriodDate.month,
          lastPeriodDate.day,
        );
        final endDate = startDate.add(Duration(days: defaultPeriodLength - 1));
        final periodLog = PeriodLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          startDate: startDate,
          endDate: endDate,
        );
        await periodRepo.savePeriodLogs([periodLog]);
      }

      // Geçici veriyi temizle
      await prefs.remove('onboarding_last_period_date');
    }

    if (!mounted) return;

    // 4. CalendarViewModel'i yenile
    context.read<CalendarViewModel>().refreshData();
    context.goNamed(RouteNames.onboardingSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = context.tokens.background;
    final textColor = context.tokens.text;
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
            onPressed: _completeOnboarding,
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
            child: Text(
              context.tr('onb_finish_setup'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => context.pop(),
                    ),
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                      child: Text(
                        context.tr('onboarding_skip'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Progress Indicator (6th step)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isActive = index == 5; // 6th dot is active
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: isActive ? 24 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: isActive
                            ? (Theme.of(context).colorScheme.primary)
                            : primaryColor.withAlpha(
                                (isDark ? 0.4 : 0.2 * 255).toInt(),
                              ),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        context.tr('onb_cycle_length_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('onb_cycle_length_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondaryColor,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Wheel Picker
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Selection Highlight
                            Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: primaryColor.withAlpha(
                                  (isDark ? 0.2 : 0.1 * 255).toInt(),
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.symmetric(
                                  horizontal: BorderSide(
                                    color: primaryColor.withAlpha(51),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            // The Picker
                            ListWheelScrollView.useDelegate(
                              controller: _scrollController,
                              itemExtent: 60,
                              perspective: 0.005,
                              diameterRatio: 2.0,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() {
                                  _selectedDays =
                                      index + 21; // Range: 21 to 45 days
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 25, // 21 to 45
                                builder: (context, index) {
                                  final isSelected =
                                      index + 21 == _selectedDays;
                                  return Center(
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      style: TextStyle(
                                        fontSize: isSelected ? 36 : 24,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? primaryColor
                                            : textSecondaryColor.withAlpha(127),
                                      ),
                                      child: Text('${index + 21} Gün'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // I don't know Button
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedDays = 28; // Standard fallback
                            _scrollController.animateToItem(
                              7,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: textSecondaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          context.tr('onb_dont_know'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
