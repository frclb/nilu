import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import 'onboarding_progress.dart';

/// "Yakın zamanda doğum yaptım" yolu: doğum günü.
///
/// Lohusalık yalnızca bir gebelik açıp "doğum" diye bitirerek
/// kurulabiliyordu; doğumdan sonra uygulamayı indiren anne önce gebelik
/// sorularından geçmek zorundaydı.
///
/// Seçim lohusalık süresiyle sınırlı: daha eski bir doğumla lohusalık
/// evresi hiç başlamaz, kullanıcı boş bir lohusa ekranı yerine döngü
/// takibine yönlendiriliyor (ekrandaki not).
class OnboardingBirthScreen extends StatefulWidget {
  const OnboardingBirthScreen({super.key});

  @override
  State<OnboardingBirthScreen> createState() => _OnboardingBirthScreenState();
}

class _OnboardingBirthScreenState extends State<OnboardingBirthScreen> {
  final DateTime _bugun = DateTime.now().plusDays(0);
  late DateTime _dogum = _bugun;
  bool _kaydediliyor = false;

  /// Lohusalık evresinin hâlâ sürdüğü en eski doğum günü.
  DateTime get _enEski => _bugun.plusDays(-(LifeStage.postpartumDays - 1));

  Future<void> _devam() async {
    if (_kaydediliyor) return;
    setState(() => _kaydediliyor = true);
    // Bakım şablonu yalnızca Türkçe'de (bkz. `PregnancySetupScreen`).
    final sablon = Localizations.localeOf(context).languageCode == 'tr'
        ? 'tr'
        : null;
    await context.read<PregnancyViewModel>().recordBirth(
      birthDate: _dogum,
      careTemplate: sablon,
    );
    if (!mounted) return;
    context.goNamed(RouteNames.onboardingSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: t.background,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border(top: BorderSide(color: t.surfaceAlt)),
        ),
        child: AppContentWidth(
          child: SafeArea(
            top: false,
            child: ElevatedButton(
              key: const Key('onboarding_birth_continue'),
              onPressed: _kaydediliyor ? null : _devam,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      context.tr('onb_continue'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward),
                ],
              ),
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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      Text(
                        context.tr('onb_birth_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: t.text,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr('onb_birth_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: t.textMuted,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        decoration: BoxDecoration(
                          color: t.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: t.border),
                        ),
                        child: CalendarDatePicker(
                          key: const Key('onboarding_birth_calendar'),
                          initialDate: _dogum,
                          firstDate: _enEski,
                          lastDate: _bugun,
                          onDateChanged: (gun) => setState(() => _dogum = gun),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('onb_birth_older'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: t.textMuted,
                          height: 1.5,
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
