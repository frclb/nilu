import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/navigation/route_names.dart';
import '../../data/repositories/cycle_settings_repository.dart';
import '../../data/repositories/period_repository.dart';
import '../../domain/services/period_service.dart';
import '../../presentation/calendar/view_models/calendar_view_model.dart';
import '../../localization/app_localizations.dart';
import 'onboarding_period_length_screen.dart';
import 'onboarding_progress.dart';
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
      FixedExtentScrollController(
        initialItem: 28 - CycleSettingsRepository.minCycleLength,
      );
  // "Bilmiyorum" ile aynı başlangıç: ikisi farklı sayı verince tekerleğe
  // dokunmayan kullanıcı 27, "bilmiyorum" diyen 28 alıyordu.
  int _selectedDays = 28;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final cycleSettingsRepo = CycleSettingsRepository();
    final periodRepo = PeriodRepository();
    final prefs = await SharedPreferences.getInstance();

    // Regl süresi artık soruluyor. Önceden burada sabit 5 yazıyordu ve bu
    // sayı hem kaydın açık mı kapalı mı kurulacağına karar veriyor hem de
    // `completedLength` üzerinden ortalama regl süresi hesabına giriyordu:
    // kullanıcının söylemediği bir değer kendi verisiymiş gibi geri
    // okunuyordu. Soru atlanırsa yine varsayılana düşülüyor.
    final periodLength =
        prefs.getInt(OnboardingPeriodLengthScreen.prefsKey) ??
        OnboardingPeriodLengthScreen.defaultDays;

    // 1. Döngü ayarlarını kaydet (ilk kurulum)
    await cycleSettingsRepo.saveInitialSettings(
      cycleLength: _selectedDays,
      periodLength: periodLength,
    );

    // 2. Onboarding'de seçilen son regl tarihini oku
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
        // Kaydı servis kuruyor: "beklenen süre dolmadıysa dönem sürüyor"
        // kuralı takvimdeki gün işaretlemeyle aynı olmak zorunda.
        final periodLog = PeriodService().recordFromStart(
          startDate,
          expectedLength: periodLength,
        );
        await periodRepo.savePeriodLogs([periodLog]);
      }

      // Geçici veriyi temizle
      await prefs.remove('onboarding_last_period_date');
    }
    await prefs.remove(OnboardingPeriodLengthScreen.prefsKey);

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
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () => onboardingBack(context),
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

              const OnboardingStepDots(step: OnboardingStep.cycleLength),

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
                                  onboardingHighlightAlpha(isDark),
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
                                      index +
                                      CycleSettingsRepository.minCycleLength;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount:
                                    CycleSettingsRepository.maxCycleLength -
                                    CycleSettingsRepository.minCycleLength +
                                    1,
                                builder: (context, index) {
                                  final isSelected =
                                      index +
                                          CycleSettingsRepository
                                              .minCycleLength ==
                                      _selectedDays;
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
                                      child: Text(
                                        context.tr(
                                          'onb_days_count',
                                          params: {
                                            'n':
                                                '${index + CycleSettingsRepository.minCycleLength}',
                                          },
                                        ),
                                      ),
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
