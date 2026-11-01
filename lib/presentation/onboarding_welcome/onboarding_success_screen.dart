import 'package:flutter/material.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/brand_lotus.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../localization/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../domain/models/life_stage.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../../design_system/app_layout.dart';
import '../../localization/date_names.dart';
import '../calendar/view_models/calendar_view_model.dart';
import 'widgets/onboarding_chrome.dart';
import '../tour/app_tour.dart';

class OnboardingSuccessScreen extends StatelessWidget {
  const OnboardingSuccessScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    final userViewModel = context.read<UserViewModel>();
    final stage = context.read<PregnancyViewModel>().stage;

    // Normal kullanıcı girişinde partner modunu sıfırla
    await userViewModel.resetPartnerState();

    // Bayrağı doğrudan SharedPreferences'a yazmıyoruz: ViewModel üzerinden
    // yazmak bellek içi durumu da güncelliyor, aksi hâlde router eski değeri
    // görmeye devam ediyordu.
    await userViewModel.markOnboardingComplete();
    // Ana ekrana ilk girişte neyin nerede olduğunu anlatan tur. Tur döngü
    // takibinin ana ekranını anlatıyor; gebelik ve lohusalık panolarında
    // onun hedefleri yok, işaret orada asılı kalıp sonra döngüye
    // dönüldüğünde beklenmedik bir anda açılırdı.
    if (stage == LifeStage.cycle) await AppTour.requestAfterOnboarding();

    if (context.mounted) {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final primary = theme.colorScheme.primary;

    // Açıklama seçilen yola göre: "Hamileyim" ve "doğum yaptım" yollarında
    // ayarlanan bir döngü yok; "bebek istiyorum" yolunda var, ayrıca
    // planlama hatırlatıcıları.
    final gebelik = context.watch<PregnancyViewModel>();
    final aciklama = switch (gebelik.stage) {
      LifeStage.pregnancy => 'onboarding_success_desc_pregnancy',
      LifeStage.postpartum => 'onboarding_success_desc_postpartum',
      LifeStage.cycle =>
        gebelik.conception != null
            ? 'onboarding_success_desc_conception'
            : 'onboarding_success_desc',
    };

    return Scaffold(
      backgroundColor: t.background,
      body: AmbientBackground(
        child: AppContentWidth(
          child: SafeArea(
            child: Column(
              children: [
                AppBrandBar(
                  trailing: IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).closeButtonTooltip,
                    icon: const Icon(Icons.close),
                    color: t.textMuted,
                    onPressed: () => _completeOnboarding(context),
                  ),
                ),

                // Tek ekran: sığdığında ortalanıyor, sığmadığında (en küçük
                // telefon) orantılı küçülüyor; kaydırma yok.
                Expanded(
                  child: AppFitToScreen(
                    fitKey: const Key('onboarding_fit'),
                    child: OnboardingStagger(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 12),
                        const _Medallion(),
                        const SizedBox(height: 28),
                        Semantics(
                          header: true,
                          child: Text(
                            context.tr('onboarding_success_title'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontSize: 32,
                              color: primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Text(
                            context.tr(aciklama),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 15,
                              height: 1.5,
                              color: t.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _PrivacyPill(),
                        if (gebelik.stage == LifeStage.cycle) ...[
                          const SizedBox(height: 24),
                          const _CycleSummary(),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                OnboardingBottomBar(
                  child: AppGradientButton(
                    label: context.tr('onboarding_success_cta'),
                    onPressed: () => _completeOnboarding(context),
                    radius: AppRadius.pill,
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

/// Lotus madalyonu ve onay rozeti; kurulumun sonu küçük bir kutlama.
///
/// Onboarding markanın lotusuyla açılıyor; aynı işaretle kapanıyor:
/// karşılamadaki ışıyan daire büyüyerek geliyor, ardından tik rozeti
/// beliriyor ve çevresinden bir halka dalgası yayılıyor. "Hareketi azalt"
/// açıksa son hâli doğrudan çiziliyor.
class _Medallion extends StatefulWidget {
  const _Medallion();

  @override
  State<_Medallion> createState() => _MedallionState();
}

class _MedallionState extends State<_Medallion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mark = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
    );
    final badge = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.4, 0.75, curve: Curves.elasticOut),
    );
    final wave = CurvedAnimation(
      parent: _c,
      curve: const Interval(0.45, 1, curve: Curves.easeOutCubic),
    );

    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            // Dış hale.
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [t.surface, t.brandTint],
                ),
                boxShadow: AppCard.shadow(t),
              ),
            ),
            // Rozetle birlikte yayılıp sönen halka.
            if (wave.value > 0 && wave.value < 1)
              Transform.scale(
                scale: 0.62 + 0.38 * wave.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: t.secondary.withAlpha(
                        (110 * (1 - wave.value)).round(),
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),
            // İç halka.
            Padding(
              padding: const EdgeInsets.all(18),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: t.secondary.withAlpha(40)),
                ),
              ),
            ),
            // Işıyan logo dairesi: karşılamadakiyle aynı.
            Transform.scale(
              scale: mark.value,
              child: Container(
                width: 116,
                height: 116,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppGradients.mark(context),
                  boxShadow: [
                    BoxShadow(
                      color: t.markStart.withAlpha(dark ? 120 : 70),
                      blurRadius: 40,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const BrandLotus(
                  color: AppGradients.onMark,
                  sideOpacity: 0.8,
                ),
              ),
            ),
            // Onay rozeti.
            Positioned(
              right: 8,
              bottom: 14,
              child: Transform.scale(
                scale: badge.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppGradients.mark(context),
                    boxShadow: AppShadows.floating(context),
                    border: Border.all(color: t.surface, width: 3),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppGradients.onMark,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Sağlık verilerin cihazında şifreli olarak saklanır."
class _PrivacyPill extends StatelessWidget {
  const _PrivacyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.tokens.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const OnboardingPrivacyNote(),
    );
  }
}

/// Az önce kurulan döngünün özeti: süre, regl süresi, sonraki regl.
///
/// Uydurma değil: kurulumun son adımı ayarları kaydedip takvimi yeniledi,
/// değerler oradan okunuyor. Döngü süresi henüz kullanıcıdan gelmiyorsa
/// (ör. eski bir kurulum yarıda kalmışsa) kart hiç gösterilmiyor.
class _CycleSummary extends StatelessWidget {
  const _CycleSummary();

  @override
  Widget build(BuildContext context) {
    final takvim = context.watch<CalendarViewModel>();
    if (!takvim.cycleLengthKnown) return const SizedBox.shrink();
    final info = takvim.cycleInfo;
    final sonraki = info.predictedNextPeriod;

    String gun(int n) => context.tr('cycle_settings_days', params: {'n': '$n'});

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Stat(
              label: context.tr('cycle_settings_length'),
              value: gun(info.averageCycleLength),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Stat(
              label: context.tr('cycle_settings_period'),
              // Kurulumda girilen süre; tek kayıttan ortalama çıkmaz.
              value: gun(info.plannedPeriodLength),
            ),
          ),
          if (sonraki != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _Stat(
                label: context.tr('prediction_info_next'),
                value:
                    '${sonraki.day} ${context.shortMonthName(sonraki.month)}',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppCard.borderColor(t)),
        boxShadow: AppShadows.soft(context),
      ),
      child: Column(
        children: [
          Text(
            context.upper(label),
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: t.textMuted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
