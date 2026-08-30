import 'package:flutter/material.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/route_names.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_colors.dart';

class PartnerImportantDaysScreen extends StatelessWidget {
  const PartnerImportantDaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Base colors from HTML
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textMainColor = isDark ? Colors.white : Colors.black87;
    final textMutedColor = isDark ? Colors.grey[400] : Colors.grey[500];

    // Card background and border colors
    final summaryBgColor = isDark
        ? primaryColor.withValues(alpha: 0.2)
        : primaryColor.withValues(alpha: 0.1);
    final summaryBorderColor = primaryColor.withValues(alpha: 0.2);
    final eventBgColor = isDark
        ? primaryColor.withValues(alpha: 0.1)
        : Colors.white;
    final eventBorderColor = isDark
        ? primaryColor.withValues(alpha: 0.1)
        : Colors.grey[200]!;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textMainColor),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Text(
          context.tr('partner_important_days_title'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: textMainColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: primaryColor.withValues(alpha: 0.1),
            height: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSummaryCard(
                context,
                summaryBgColor,
                summaryBorderColor,
                primaryColor,
                textMainColor,
                textMutedColor!,
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  context.tr('partner_important_days_upcoming'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: textMutedColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Period Start Event (Red)
              _buildEventItem(
                context: context,
                icon: Icons.water_drop_outlined,
                iconBgColor: primaryColor,
                iconColor: Colors.white,
                title: context.tr('partner_notif_period_start_short'),
                dateText: "14 Eyl",
                dateBgColor: isDark
                    ? primaryColor.withValues(alpha: 0.3)
                    : primaryColor.withValues(alpha: 0.1),
                dateTextColor: context.tokens.danger,
                relativeTimeText: context.tr('partner_important_days_est_2'),
                tipText: context.tr('partner_important_days_tip_1'),
                bgColor: eventBgColor,
                borderColor: eventBorderColor,
                textMainColor: textMainColor,
                textMutedColor: textMutedColor,
              ),
              const SizedBox(height: 16),
              // Fertility Window Event (Orange)
              _buildEventItem(
                context: context,
                icon: Icons.auto_awesome_outlined, // Sparkles approximation
                iconBgColor: context.tokens.warning.withAlpha(51),
                iconColor: context.tokens.warning,
                title: context.tr('partner_important_days_fertility'),
                dateText: "17 Eyl",
                dateBgColor: isDark
                    ? primaryColor.withValues(alpha: 0.3)
                    : Colors.grey[200]!,
                dateTextColor: textMutedColor,
                relativeTimeText: context.tr('partner_important_days_est_5'),
                tipText: context.tr('partner_important_days_tip_2'),
                bgColor: eventBgColor,
                borderColor: eventBorderColor,
                textMainColor: textMainColor,
                textMutedColor: textMutedColor,
              ),
              const SizedBox(height: 16),
              // Ovulation Day Event (Blue)
              _buildEventItem(
                context: context,
                icon: Icons.favorite_border, // Heart approximation
                iconBgColor: context.tokens.ovulation.withAlpha(51),
                iconColor: context.tokens.ovulation,
                title: context.tr('partner_important_days_ovulation'),
                dateText: "22 Eyl",
                dateBgColor: isDark
                    ? primaryColor.withValues(alpha: 0.3)
                    : Colors.grey[200]!,
                dateTextColor: textMutedColor,
                relativeTimeText: context.tr('partner_important_days_est_10'),
                tipText: context.tr('partner_important_days_tip_3'),
                bgColor: eventBgColor,
                borderColor: eventBorderColor,
                textMainColor: textMainColor,
                textMutedColor: textMutedColor,
              ),
              const SizedBox(height: 32),
              _buildSettingsButton(context, primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    Color bgColor,
    Color borderColor,
    Color primaryColor,
    Color textMainColor,
    Color textMutedColor,
  ) {
    final iconColor = context.tokens.danger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Text(
                context.tr('partner_important_days_summary_title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textMainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('partner_important_days_summary_desc'),
            style: TextStyle(fontSize: 14, color: textMutedColor, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem({
    required BuildContext context,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String dateText,
    required Color dateBgColor,
    required Color dateTextColor,
    required String relativeTimeText,
    required String tipText,
    required Color bgColor,
    required Color borderColor,
    required Color textMainColor,
    required Color textMutedColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textMainColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: dateBgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dateText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dateTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  relativeTimeText,
                  style: TextStyle(fontSize: 14, color: textMutedColor),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tipText,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, Color primaryColor) {
    return ElevatedButton(
      onPressed: () {
        context.pushNamed(RouteNames.partnerNotificationSettings);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 20),
          const SizedBox(width: 8),
          Text(
            context.tr('partner_important_days_settings_btn'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
