import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../localization/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../domain/view_models/user_view_model.dart';
import '../../design_system/app_colors.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? AppColors.backgroundDeepDark : Colors.white;
    final textColor = isDark
        ? const Color(0xFFF9F1F2)
        : const Color(0xFF181114);
    final textSecondaryColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final primaryColor =
        theme.colorScheme.primary; // Often #f04299 based on provided HTML
    final subtlePink = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFF9F1F2).withValues(alpha: 0.5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
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
                    'FLOWELL',
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
                      color: Colors.grey[400],
                      onPressed: () => _completeOnboarding(context),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Expanded(
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
                                    color: Colors.black.withValues(alpha: 0.02),
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
                                          primaryColor.withValues(alpha: 0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Network Image (falling back to Icon if offline)
                                  Image.network(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDOU43gg-EGAuvUdNtmc9JMDMAVOlOaYV4s4npYSY03mUaCd60MoyCoFfzuZGtsNnwld1Ed8FpLEvJWhzqxy5BBBmDjCsAZGO2Ycv2puOjkXNjC6bmHI6wz6s8OxV3kKLMqZv1bhJhUoqjV0iJ9CFDeNeDmoixqpEjzq1EoejeMi7cm9tXEDDa2Nm3SC6CG4sPugLRwReAgQ42CCI1RxcUglK2G49v-UlNOOgfRtcpwOYCCYgvbQLHUfMC7Mq6o6K5a_vD_RGGwbg4',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.white.withValues(alpha: 0.1),
                                    colorBlendMode: BlendMode.lighten,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.local_florist,
                                          size: 100,
                                          color: primaryColor.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      );
                                    },
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
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF221019)
                                        : const Color(0xFFF8F6F7),
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
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
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
                              context.tr('onboarding_success_desc'),
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
                      Icon(Icons.lock, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('onboarding_success_privacy'),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
                      foregroundColor: Colors.white,
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
    );
  }
}
