import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_colors.dart';
import '../../core/navigation/route_names.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Gradient AppBar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primary,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primary,
                      primary.withAlpha(200),
                      const Color(0xFFD946EF),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.diamond,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('premium_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('premium_subtitle'),
                        style: TextStyle(
                          color: Colors.white.withAlpha(204),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Features
                const SizedBox(height: 8),
                _buildFeatureItem(
                  context,
                  Icons.insights,
                  context.tr('premium_feature_1_title'),
                  context.tr('premium_feature_1_desc'),
                ),
                _buildFeatureItem(
                  context,
                  Icons.favorite,
                  context.tr('premium_feature_2_title'),
                  context.tr('premium_feature_2_desc'),
                ),
                _buildFeatureItem(
                  context,
                  Icons.shield,
                  context.tr('premium_feature_3_title'),
                  context.tr('premium_feature_3_desc'),
                ),
                _buildFeatureItem(
                  context,
                  Icons.notifications_active,
                  context.tr('premium_feature_4_title'),
                  context.tr('premium_feature_4_desc'),
                ),
                _buildFeatureItem(
                  context,
                  Icons.palette,
                  context.tr('premium_feature_5_title'),
                  context.tr('premium_feature_5_desc'),
                ),

                const SizedBox(height: 32),

                // Plan Seçimi
                Text(
                  context.tr('premium_choose_plan'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 16),

                // Yıllık Plan (Önerilen)
                _buildPlanCard(
                  context,
                  isRecommended: true,
                  title: context.tr('premium_plan_yearly'),
                  price: context.tr('premium_plan_yearly_price'),
                  subPrice: context.tr('premium_plan_yearly_monthly'),
                  savingBadge: context.tr('premium_plan_yearly_save'),
                  onTap: () => _handlePurchase(context, 'yearly'),
                ),
                const SizedBox(height: 12),

                // Aylık Plan
                _buildPlanCard(
                  context,
                  isRecommended: false,
                  title: context.tr('premium_plan_monthly'),
                  price: context.tr('premium_plan_monthly_price'),
                  subPrice: '',
                  onTap: () => _handlePurchase(context, 'monthly'),
                ),
                const SizedBox(height: 12),

                // Haftalık Plan
                _buildPlanCard(
                  context,
                  isRecommended: false,
                  title: context.tr('premium_plan_weekly'),
                  price: context.tr('premium_plan_weekly_price'),
                  subPrice: '',
                  onTap: () => _handlePurchase(context, 'weekly'),
                ),

                const SizedBox(height: 24),

                // Satın Al Butonu
                ElevatedButton(
                  onPressed: () => _handlePurchase(context, 'yearly'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: primary.withAlpha(100),
                  ),
                  child: Text(
                    context.tr('premium_subscribe_button'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Restore purchases
                TextButton(
                  onPressed: () => _handleRestore(context),
                  child: Text(
                    context.tr('premium_restore_purchases'),
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Legal links
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () {
                        context.pushNamed(RouteNames.privacyPolicy);
                      },
                      child: Text(
                        context.tr('premium_privacy'),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.pushNamed(RouteNames.termsOfService);
                      },
                      child: Text(
                        context.tr('premium_terms'),
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Auto-renewal disclaimer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    context.tr('premium_disclaimer'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          (isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight)
                              .withAlpha(150),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withAlpha(isDark ? 40 : 20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textMainLight,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required bool isRecommended,
    required String title,
    required String price,
    required String subPrice,
    String? savingBadge,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended
                ? primary
                : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
            width: isRecommended ? 2 : 1,
          ),
          boxShadow: isRecommended
              ? [
                  BoxShadow(
                    color: primary.withAlpha(30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white
                              : AppColors.textMainLight,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (savingBadge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            savingBadge,
                            style: const TextStyle(
                              color: AppColors.accentGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subPrice.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subPrice,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePurchase(BuildContext context, String planType) {
    // TODO: StoreKit / RevenueCat ile gerçek satın alma işlemi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('premium_purchase_coming_soon')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleRestore(BuildContext context) {
    // TODO: Satın alım geri yükleme
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('premium_restore_checking')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
