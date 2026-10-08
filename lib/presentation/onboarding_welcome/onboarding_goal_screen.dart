import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import 'onboarding_progress.dart';

/// Kurulumun yol ayrımı: döngü takibi mi, gebelik mi?
///
/// Uygulamayı zaten hamileyken indiren kullanıcı önce üç regl sorusundan
/// geçip sonra Profil'den gebeliğini işaretlemek zorundaydı: kendisine
/// uymayan sorular, ardından bir süre regl tahminli bir ana ekran.
///
/// Seçenekler dokununca ilerliyor; iki seçenekli bir soruda ayrı bir "Devam"
/// düğmesi yalnızca fazladan bir dokunuş olurdu.
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.background,
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
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: t.text),
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () => onboardingBack(context),
                    ),
                  ],
                ),
              ),
              const OnboardingStepDots(step: OnboardingStep.goal),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      Text(
                        context.tr('onb_goal_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: t.text,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('onb_goal_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: t.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _Secenek(
                        key: const Key('onboarding_goal_cycle'),
                        icon: Icons.water_drop_outlined,
                        title: context.tr('onb_goal_cycle'),
                        body: context.tr('onb_goal_cycle_body'),
                        onTap: () =>
                            context.pushNamed(RouteNames.onboardingLastPeriod),
                      ),
                      const SizedBox(height: 16),
                      _Secenek(
                        key: const Key('onboarding_goal_pregnancy'),
                        icon: Icons.pregnant_woman,
                        title: context.tr('onb_goal_pregnancy'),
                        body: context.tr('onb_goal_pregnancy_body'),
                        onTap: () => _hamileyim(context),
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

class _Secenek extends StatelessWidget {
  const _Secenek({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final renk = Theme.of(context).colorScheme.primary;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Material(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: t.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: t.brandTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: renk),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: t.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: t.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
