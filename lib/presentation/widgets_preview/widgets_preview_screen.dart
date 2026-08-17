import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../localization/app_localizations.dart';
import '../../design_system/app_colors.dart';

class WidgetsPreviewScreen extends StatelessWidget {
  const WidgetsPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Base colors matching HTML
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final primaryColor = AppColors.primaryLight; // #551b26 HTML
    final accentSoft = isDark
        ? const Color(0xFF3B1A20)
        : const Color(0xFFF8E7E9); // #F8E7E9 HTML

    final textMainColor = isDark ? Colors.white : Colors.black87;

    // Card background
    final cardBgColor = isDark
        ? AppColors.textMainSlate
        : Colors.white; // dark:bg-slate-900 HTML
    final borderColor = isDark
        ? accentSoft.withValues(alpha: 0.1)
        : accentSoft.withValues(alpha: 0.3);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('widgets_title'),
          style: TextStyle(
            color: textMainColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.15,
          ),
        ),
        actions: const [
          SizedBox(width: 48), // For centering title accurately
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSmallWidgetSection(
                context,
                primaryColor,
                accentSoft,
                cardBgColor,
                borderColor,
              ),
              const SizedBox(height: 32),
              _buildMediumWidgetSection(
                context,
                primaryColor,
                accentSoft,
                cardBgColor,
                borderColor,
              ),
              const SizedBox(height: 32),
              _buildPartnerWidgetSection(
                context,
                primaryColor,
                accentSoft,
                cardBgColor,
                borderColor,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: primaryColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSmallWidgetSection(
    BuildContext context,
    Color primaryColor,
    Color accentSoft,
    Color cardBgColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          context.tr('widgets_small_title'),
          primaryColor,
        ),
        Center(
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 96,
                  width: 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular background progress
                      Transform.rotate(
                        angle: -math.pi / 2,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 6,
                          color: accentSoft,
                        ),
                      ),
                      // Circular actual progress
                      Transform.rotate(
                        angle: -math.pi / 2,
                        child: CircularProgressIndicator(
                          value: 14 / 28, // Example logic
                          strokeWidth: 6,
                          color: primaryColor,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "14",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                          Text(
                            context.tr('widgets_days_uppercase'),
                            style: TextStyle(
                              color: primaryColor.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr('widgets_phase_example'),
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediumWidgetSection(
    BuildContext context,
    Color primaryColor,
    Color accentSoft,
    Color cardBgColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          context.tr('widgets_medium_title'),
          primaryColor,
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('widgets_next_period_uppercase'),
                        style: TextStyle(
                          color: primaryColor.withValues(alpha: 0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "8",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.tr('widgets_days_left'),
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentSoft.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                width: double.infinity,
                color: accentSoft.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentSoft.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.lightbulb,
                        color: primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('widgets_daily_tip_uppercase'),
                            style: TextStyle(
                              color: primaryColor.withValues(alpha: 0.6),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            context.tr('widgets_daily_tip_example'),
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerWidgetSection(
    BuildContext context,
    Color primaryColor,
    Color accentSoft,
    Color cardBgColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          context.tr('widgets_partner_title'),
          primaryColor,
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
                spreadRadius: -2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                height: 56,
                width: 56,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                      child: const CircleAvatar(
                        backgroundImage: NetworkImage(
                          "https://lh3.googleusercontent.com/aida-public/AB6AXuCvAmnum8sjWAUqeVu2wdX7pMwGpFgSo7nL1scC28Y23hhBkjVPa-HcrtIG__IeH0hOuGsEDxkc5ciTeh51ZBN8Wj8rZ9p-QaEeyiMB4OkHu-RgVzSQ65Go6SdfgqBf7y36R-WZlUzuWyxLm-3zpIzELUyeb3DXfRHkEbDnyuo3XJJqH4DatPCNhxZABFwsmBplIiINN_adZSXAWhgb5OgRTBmBDQYY5gaurLQmNkvGtikUF-hYgdnbdnvQ5sVPCPTteRQqV9i3kgw",
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        height: 20,
                        width: 20,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? AppColors.textMainSlate
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Ayşe",
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            context.tr('widgets_partner_phase_example'),
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('widgets_partner_tip_example'),
                      style: TextStyle(
                        color: primaryColor.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
