import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';
import 'onboarding_progress.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = context.tokens.text;
    final textSecondaryColor = context.tokens.textMuted;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: context.tokens.background,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: context.tokens.surface,
          border: Border(top: BorderSide(color: context.tokens.surfaceAlt)),
        ),
        child: AppContentWidth(
          child: ElevatedButton(
            onPressed: _continue,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: theme.colorScheme.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: primaryColor.withAlpha(76),
            ),
            child: Text(
              context.tr('onb_continue'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: Column(
            children: [
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
                      onPressed: _continue,
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                      child: Text(
                        context.tr('onboarding_skip'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const OnboardingStepDots(step: OnboardingStep.periodLength),

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
                        context.tr('onb_period_length_title'),
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
                        context.tr('onb_period_length_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondaryColor,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
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
                            ListWheelScrollView.useDelegate(
                              controller: _scrollController,
                              itemExtent: 60,
                              perspective: 0.005,
                              diameterRatio: 2.0,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (index) {
                                setState(() => _selectedDays = index + _min);
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: _max - _min + 1,
                                builder: (context, index) {
                                  final days = index + _min;
                                  final isSelected = days == _selectedDays;
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
                                          params: {'n': '$days'},
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

                      TextButton(
                        onPressed: _resetToDefault,
                        style: TextButton.styleFrom(
                          foregroundColor: textSecondaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: Text(
                          context.tr('onb_dont_know'),
                          style: const TextStyle(
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
