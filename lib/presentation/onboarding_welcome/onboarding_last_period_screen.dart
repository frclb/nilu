import 'package:flutter/material.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/route_names.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localizations.dart';
import 'onboarding_progress.dart';
import 'widgets/onboarding_calendar.dart';
import 'widgets/onboarding_chrome.dart';
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
                  child: AppFitToScreen(
                    fitKey: const Key('onboarding_fit'),
                    child: OnboardingStagger(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OnboardingHeading(
                          tag: context.tr('cycle_settings_title'),
                          tagIcon: Icons.calendar_today_outlined,
                          title: context.tr('onb_last_period_title'),
                          description: context.tr('onb_last_period_desc'),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const Spacer(),
                        Center(
                          child: OnboardingCalendar(
                            key: const Key('onboarding_last_period_calendar'),
                            selected: _selectedDate,
                            // Son regl ileride olamaz.
                            lastDate: DateTime.now(),
                            onSelected: (d) =>
                                setState(() => _selectedDate = d),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // İpucu kart değil, takvimin altında tek satır:
                        // kart ekranı kaydırmaya zorluyordu.
                        OnboardingHint(
                          text: context.tr('onb_last_period_hint'),
                        ),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.md),
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
}
