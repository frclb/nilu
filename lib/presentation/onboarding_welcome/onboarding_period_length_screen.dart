import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';
import 'onboarding_progress.dart';
import 'widgets/onboarding_chrome.dart';
import 'widgets/onboarding_day_wheel.dart';

/// "Regliniz kaç gün sürüyor?"
///
/// Bu soru eskiden hiç sorulmuyordu; regl süresi sessizce 5 varsayılıyordu.
/// İki yerde zarar veriyordu:
///
/// * Onboarding'de girilen son regl tarihinden kayıt kurulurken dönemin
///   hâlâ sürüp sürmediğine bu süreyle karar veriliyor. Beş günü kısa olan
///   biri için dönem gereğinden uzun açık kalıyordu.
/// * Uydurulan bu 5, `completedLength` üzerinden **ortalama regl süresi**
///   hesabına giriyordu: kullanıcının söylemediği bir sayı kendi verisiymiş
///   gibi geri okunuyordu.
///
/// Cevap verilmezse yine 5 kullanılıyor — ama artık bu bir varsayılan,
/// kullanıcının verisi değil.
class OnboardingPeriodLengthScreen extends StatefulWidget {
  const OnboardingPeriodLengthScreen({super.key});

  /// Seçilebilen en kısa ve en uzun süre.
  static const int minDays = 2;
  static const int maxDays = 10;

  /// Cevap verilmediğinde kullanılan değer.
  static const int defaultDays = 5;

  /// Cevabın onboarding boyunca taşındığı geçici anahtar; kurulumu bitiren
  /// ekran bunu okuyup ayarlara yazıyor.
  static const String prefsKey = 'onboarding_period_length';

  @override
  State<OnboardingPeriodLengthScreen> createState() =>
      _OnboardingPeriodLengthScreenState();
}

class _OnboardingPeriodLengthScreenState
    extends State<OnboardingPeriodLengthScreen> {
  static const int _min = OnboardingPeriodLengthScreen.minDays;
  static const int _max = OnboardingPeriodLengthScreen.maxDays;
  static const int _default = OnboardingPeriodLengthScreen.defaultDays;

  final FixedExtentScrollController _scrollController =
      FixedExtentScrollController(initialItem: _default - _min);
  int _selectedDays = _default;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(OnboardingPeriodLengthScreen.prefsKey, _selectedDays);
    if (!mounted) return;
    context.pushNamed(RouteNames.onboardingCycleLength);
  }

  /// "Bilmiyorum": varsayılana dön ve devam et. Kayıt yine yazılıyor ki
  /// sonraki ekran "cevap verilmedi" ile "5 seçildi"yi ayırt etmek zorunda
  /// kalmasın.
  void _resetToDefault() {
    setState(() {
      _selectedDays = _default;
      _scrollController.animateToItem(
        _default - _min,
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
                OnboardingTopBar(
                  trailing: OnboardingSkipButton(onPressed: _continue),
                ),
                const OnboardingStepDots(step: OnboardingStep.periodLength),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OnboardingHeading(
                          tag: context.tr('cycle_settings_title'),
                          tagIcon: Icons.calendar_today_outlined,
                          title: context.tr('onb_period_length_title'),
                          description: context.tr('onb_period_length_desc'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        OnboardingDayWheel(
                          controller: _scrollController,
                          min: _min,
                          max: _max,
                          selected: _selectedDays,
                          onSelected: (days) =>
                              setState(() => _selectedDays = days),
                          label: context.tr('cycle_settings_period'),
                          icon: Icons.water_drop_outlined,
                          highlight: LinearGradient(
                            colors: [t.flow, t.secondary],
                          ),
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
