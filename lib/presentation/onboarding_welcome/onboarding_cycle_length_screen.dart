import 'package:flutter/material.dart';
import '../../design_system/app_decor.dart';
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
import 'widgets/onboarding_chrome.dart';
import 'widgets/onboarding_day_wheel.dart';
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

  /// "Bilmiyorum": standart 28 gün.
  void _resetToDefault() {
    setState(() {
      _selectedDays = 28; // Standard fallback
      _scrollController.animateToItem(
        7,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.background,
      bottomNavigationBar: OnboardingBottomBar(
        child: AppGradientButton(
          label: context.tr('onb_finish_setup'),
          onPressed: _completeOnboarding,
          radius: AppRadius.pill,
        ),
      ),
      body: AmbientBackground(
        child: AppContentWidth(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                OnboardingTopBar(
                  trailing: OnboardingSkipButton(
                    onPressed: _completeOnboarding,
                  ),
                ),
                const OnboardingStepDots(step: OnboardingStep.cycleLength),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OnboardingHeading(
                          tag: context.tr('cycle_settings_title'),
                          tagIcon: Icons.calendar_today_outlined,
                          title: context.tr('onb_cycle_length_title'),
                          description: context.tr('onb_cycle_length_desc'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        OnboardingDayWheel(
                          controller: _scrollController,
                          min: CycleSettingsRepository.minCycleLength,
                          max: CycleSettingsRepository.maxCycleLength,
                          selected: _selectedDays,
                          onSelected: (days) =>
                              setState(() => _selectedDays = days),
                          label: context.tr('cycle_settings_length'),
                          icon: Icons.autorenew,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OnboardingDontKnowButton(onPressed: _resetToDefault),
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
}
