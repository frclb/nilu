import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/models/calendar_day.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import 'widgets/onboarding_chrome.dart';

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
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    // Lohusalık ana ekranıyla aynı sayım: doğum günü 0, ertesi gün 1.
    final gun = _bugun.daysSince(_dogum);

    return Scaffold(
      backgroundColor: t.background,
      bottomNavigationBar: OnboardingBottomBar(
        child: AppGradientButton(
          key: const Key('onboarding_birth_continue'),
          label: context.tr('onb_continue'),
          onPressed: _kaydediliyor ? null : _devam,
          busy: _kaydediliyor,
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OnboardingHeading(
                          tag: context.tr(
                            'pp_days_total',
                            params: {'n': '${LifeStage.postpartumDays}'},
                          ),
                          tagIcon: Icons.child_friendly_outlined,
                          title: context.tr('onb_birth_title'),
                          description: context.tr('onb_birth_desc'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            decoration: AppCard.decoration(t),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                CalendarDatePicker(
                                  key: const Key('onboarding_birth_calendar'),
                                  initialDate: _dogum,
                                  firstDate: _enEski,
                                  lastDate: _bugun,
                                  onDateChanged: (gun) =>
                                      setState(() => _dogum = gun),
                                ),
                                // Seçilen gün ve lohusalığın kaçıncı günü:
                                // tarihin ne anlama geldiği seçerken belli
                                // olsun.
                                Container(
                                  margin: const EdgeInsets.fromLTRB(
                                    12,
                                    0,
                                    12,
                                    12,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: t.brandTint,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AppIconTile(
                                        icon: Icons.event_outlined,
                                        size: 36,
                                        circle: true,
                                        background: t.surface,
                                        color: primary,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Text(
                                          '${_dogum.day} '
                                          '${context.monthName(_dogum.month)} '
                                          '${_dogum.year}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: primary,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Flexible(
                                        child: AppTag(
                                          label: gun == 0
                                              ? context.tr('pp_day_birth')
                                              : context.tr(
                                                  'pp_day',
                                                  params: {'n': '$gun'},
                                                ),
                                          background: primary,
                                          foreground:
                                              theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OnboardingNote(
                          icon: Icons.info_outline,
                          text: context.tr('onb_birth_older'),
                        ),
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
