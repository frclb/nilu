import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/conception_intent.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import 'onboarding_progress.dart';
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Column(
                    children: [
                      Text(
                        context.tr('onb_ttc_title'),
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
                        context.tr('onb_ttc_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: t.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      OnboardingOption(
                        key: const Key('onboarding_ttc_now'),
                        icon: Icons.today_outlined,
                        title: context.tr('onb_ttc_now'),
                        body: context.tr('onb_ttc_now_body'),
                        onTap: () => _kaydet(context, _bugun),
                      ),
                      const SizedBox(height: 16),
                      OnboardingOption(
                        key: const Key('onboarding_ttc_since'),
                        icon: Icons.event_outlined,
                        title: context.tr('onb_ttc_since'),
                        body: context.tr('onb_ttc_since_body'),
                        onTap: () => _tarihSec(context),
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
