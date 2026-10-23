import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/conception_intent.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import 'widgets/onboarding_chrome.dart';
import 'widgets/onboarding_option.dart';

/// "Bebek istiyorum" yolunun ilk sorusu: ne zamandır deneniyor?
///
/// Hekime danışma önerisi (ASRM: 35 yaş altında 12, üstünde 6 ay) bu günden
/// sayılıyor. Niyet önceden yalnızca Profil'deki anahtarla, açıldığı günle
/// kurulabiliyordu: bir yıldır deneyen kullanıcıya öneri bir yıl sonra
/// gelirdi.
///
/// Süre aralıkları ("6–12 ay") sorulmuyor: aralığın ortasını seçmek
/// kullanıcının söylemediği bir tarihi onun verisi gibi saklamak olurdu.
/// Tarih seçilmezse "yeni başlıyorum", yani bugün.
///
/// Sonrası döngü soruları; doğurganlık penceresi oradan geliyor.
class OnboardingConceptionScreen extends StatelessWidget {
  const OnboardingConceptionScreen({super.key});

  /// Bugünün gece yarısı: seçici saat taşıyan bir tarihle açılmasın.
  static DateTime get _bugun => DateTime.now().plusDays(0);

  Future<void> _kaydet(BuildContext context, DateTime since) async {
    await context.read<PregnancyViewModel>().setConceptionSince(since);
    if (context.mounted) context.pushNamed(RouteNames.onboardingLastPeriod);
  }

  Future<void> _tarihSec(BuildContext context) async {
    final bugun = _bugun;
    final mevcut = context.read<PregnancyViewModel>().conception?.since;
    final secilen = await showDatePicker(
      context: context,
      initialDate: mevcut ?? bugun,
      firstDate: DateTime(
        bugun.year - ConceptionIntent.maxYearsBack,
        bugun.month,
        bugun.day,
      ),
      lastDate: bugun,
      helpText: context.tr('onb_ttc_since_body'),
    );
    if (secilen == null || !context.mounted) return;
    await _kaydet(context, secilen);
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bu adım "Bebek istiyorum" yolunun içinde: etiket
                        // hangi yolda olunduğunu hatırlatıyor.
                        OnboardingHeading(
                          tag: context.tr('onb_goal_ttc'),
                          tagIcon: Icons.spa_outlined,
                          title: context.tr('onb_ttc_title'),
                          description: context.tr('onb_ttc_desc'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        OnboardingOption(
                          key: const Key('onboarding_ttc_now'),
                          icon: Icons.spa_outlined,
                          iconColor: primary,
                          iconBackground: t.brandTint,
                          title: context.tr('onb_ttc_now'),
                          body: context.tr('onb_ttc_now_body'),
                          onTap: () => _kaydet(context, _bugun),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OnboardingOption(
                          key: const Key('onboarding_ttc_since'),
                          icon: Icons.calendar_month_outlined,
                          iconColor: t.secondary,
                          iconBackground: t.secondaryTint,
                          title: context.tr('onb_ttc_since'),
                          body: context.tr('onb_ttc_since_body'),
                          onTap: () => _tarihSec(context),
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
