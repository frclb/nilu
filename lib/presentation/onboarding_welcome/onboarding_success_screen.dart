import 'package:flutter/material.dart';
import '../../core/app_info.dart';
import '../../design_system/app_scrim.dart';
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

class OnboardingSuccessScreen extends StatelessWidget {
  const OnboardingSuccessScreen({super.key});

  Future<void> _completeOnboarding(BuildContext context) async {
    final userViewModel = context.read<UserViewModel>();

    // Normal kullanıcı girişinde partner modunu sıfırla
    await userViewModel.resetPartnerState();

    // Bayrağı doğrudan SharedPreferences'a yazmıyoruz: ViewModel üzerinden
    // yazmak bellek içi durumu da güncelliyor, aksi hâlde router eski değeri
    // görmeye devam ediyordu.
    await userViewModel.markOnboardingComplete();

    if (context.mounted) {
      context.goNamed(RouteNames.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = context.tokens.surface;
    final textColor = context.tokens.text;
    final textSecondaryColor = context.tokens.textMuted;
    final primaryColor =
        theme.colorScheme.primary; // Often #f04299 based on provided HTML
    final subtlePink = context.tokens.brandTint;
    // Kurulumda "Hamileyim" seçildiyse ayarlanan bir döngü yok.
    final gebe =
        context.watch<PregnancyViewModel>().stage == LifeStage.pregnancy;

    return Scaffold(
      backgroundColor: bgColor,
      body: AppContentWidth(
        child: SafeArea(
          child: Column(
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // Empty space for balance
                    Text(
                      AppInfo.displayName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        color: context.tokens.textFaint,
                        onPressed: () => _completeOnboarding(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content Area
              //
              // Sığdığında ortalanır, sığmadığında kayar.
              //
              // Yalnızca `SingleChildScrollView` yetmiyordu: kaydırma görünümü
              // çocuğunu kendi içeriği kadar yapıyor, `Stack` da görünümü
              // doldurmayı bırakıyor. `Alignment.center` işlevsiz kalıyor,
              // içerik yukarı toplanıp altta büyük bir boşluk bırakıyordu —
              // uzun ekranlı telefonlarda açıkça görünüyor. `minHeight` yığına
              // eski yüksekliğini geri veriyor.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Decorative Background Blob
                          Positioned(
                            top: MediaQuery.of(context).size.height * 0.15,
                            child: Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.1),
                              ),
                            ),
                          ),

                          // Illustration Container
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 280,
                                height: 280,
                                margin: const EdgeInsets.only(bottom: 32),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: subtlePink,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppScrim.veil(5),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        children: [
                                          // Gradient overlay
                                          Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topRight,
                                                end: Alignment.bottomLeft,
                                                colors: [
                                                  primaryColor.withValues(
                                                    alpha: 0.2,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Onboarding markanın lotusuyla
                                          // açılıyor; aynı çiçekle kapanmalı.
                                          // Burada `Icons.local_florist`
                                          // vardı — Material'in genel çiçeği,
                                          // markanınkinden başka bir şekil.
                                          Center(
                                            child: FractionallySizedBox(
                                              widthFactor: 0.42,
                                              child: BrandLotus(
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Floating checkmark badge
                                    Positioned(
                                      bottom: 24,
                                      right: 24,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppScrim.veil(26),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          border: Border.all(
                                            color: context.tokens.surfaceAlt,
                                            width: 4,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.check_circle,
                                          color: primaryColor,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Text Content
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      context.tr('onboarding_success_title'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: textColor,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      context.tr(
                                        gebe
                                            ? 'onboarding_success_desc_pregnancy'
                                            : 'onboarding_success_desc',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: textSecondaryColor,
                                        height: 1.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Action Area
              Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                width: double.infinity,
                decoration: BoxDecoration(color: bgColor),
                child: Column(
                  children: [
                    // Privacy Note
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 16,
                          color: context.tokens.textMuted,
                        ),
                        const SizedBox(width: 8),
                        // Esnek: uzun çeviride ve büyük yazıda satıra sığmayıp
                        // sağdan taşıyordu.
                        Flexible(
                          child: Text(
                            context.tr('onboarding_success_privacy'),
                            style: TextStyle(
                              color: context.tokens.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Primary Action Button
                    ElevatedButton(
                      onPressed: () => _completeOnboarding(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: primaryColor.withValues(alpha: 0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('onboarding_success_cta'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, size: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
