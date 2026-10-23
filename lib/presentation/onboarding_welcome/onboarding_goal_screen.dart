import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import 'onboarding_progress.dart';
import 'widgets/onboarding_chrome.dart';
import 'widgets/onboarding_option.dart';

/// Kurulumun yol ayrımı: döngü, gebe kalmaya çalışma, gebelik, lohusalık.
///
/// Uygulamayı zaten hamileyken indiren kullanıcı önce üç regl sorusundan
/// geçip sonra Profil'den gebeliğini işaretlemek zorundaydı: kendisine
/// uymayan sorular, ardından bir süre regl tahminli bir ana ekran. Yeni
/// doğum yapmış kullanıcı için durum daha da kötüydü: lohusalık ancak bir
/// gebelik açıp "doğum" diye bitirerek kurulabiliyordu.
///
/// Seçenekler dokununca ilerliyor; ayrı bir "Devam" düğmesi yalnızca
/// fazladan bir dokunuş olurdu.
class OnboardingGoalScreen extends StatelessWidget {
  const OnboardingGoalScreen({super.key});

  void _hamileyim(BuildContext context) {
    // Süren bir gebelik zaten kayıtlıysa (gebeliği başlatıp son ekranda
    // uygulamayı kapatan kullanıcı) tarihleri yeniden sormak anlamsız: ikinci gebelik açılmıyor,
    // girilenler sessizce yok sayılırdı (bkz. `PregnancyViewModel._start`).
    if (context.read<PregnancyViewModel>().stage == LifeStage.pregnancy) {
      context.goNamed(RouteNames.onboardingSuccess);
      return;
    }
    context.pushNamed(RouteNames.onboardingPregnancy);
  }

  /// Yalnızca döngü takibi. "Bebek istiyorum"dan geri dönüp bunu seçen
  /// kullanıcının niyeti kalmasın: folik asit hatırlatması istemediği
  /// hâlde gelirdi.
  Future<void> _dongu(BuildContext context) async {
    final vm = context.read<PregnancyViewModel>();
    if (vm.conception != null) await vm.setConception(false);
    if (context.mounted) context.pushNamed(RouteNames.onboardingLastPeriod);
  }

  void _dogumYaptim(BuildContext context) {
    // Doğum zaten kayıtlıysa (son ekranda uygulamayı kapatan kullanıcı)
    // tarihi yeniden sormuyoruz.
    if (context.read<PregnancyViewModel>().stage == LifeStage.postpartum) {
      context.goNamed(RouteNames.onboardingSuccess);
      return;
    }
    context.pushNamed(RouteNames.onboardingBirth);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: t.background,
      body: AmbientBackground(
        child: AppContentWidth(
          child: SafeArea(
            child: Column(
              children: [
                const OnboardingTopBar(),
                const OnboardingStepDots(step: OnboardingStep.goal),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OnboardingHeading(
                          title: context.tr('onb_goal_title'),
                          description: context.tr('onb_goal_desc'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        OnboardingOption(
                          key: const Key('onboarding_goal_cycle'),
                          icon: Icons.water_drop_outlined,
                          iconColor: t.flow,
                          iconBackground: t.flowTint,
                          title: context.tr('onb_goal_cycle'),
                          body: context.tr('onb_goal_cycle_body'),
                          onTap: () => _dongu(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OnboardingOption(
                          key: const Key('onboarding_goal_ttc'),
                          icon: Icons.spa_outlined,
                          iconColor: primary,
                          iconBackground: t.brandTint,
                          title: context.tr('onb_goal_ttc'),
                          body: context.tr('onb_goal_ttc_body'),
                          onTap: () => context.pushNamed(
                            RouteNames.onboardingConception,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OnboardingOption(
                          key: const Key('onboarding_goal_pregnancy'),
                          icon: Icons.pregnant_woman,
                          iconColor: t.accent,
                          iconBackground: t.accentTint,
                          title: context.tr('onb_goal_pregnancy'),
                          body: context.tr('onb_goal_pregnancy_body'),
                          onTap: () => _hamileyim(context),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OnboardingOption(
                          key: const Key('onboarding_goal_postpartum'),
                          icon: Icons.child_friendly_outlined,
                          iconColor: t.secondary,
                          iconBackground: t.secondaryTint,
                          title: context.tr('onb_goal_postpartum'),
                          body: context.tr('onb_goal_postpartum_body'),
                          onTap: () => _dogumYaptim(context),
                        ),
                        const SizedBox(height: AppSpacing.xl),
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
