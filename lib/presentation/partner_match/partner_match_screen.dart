import 'package:flutter/material.dart';
import 'widgets/pairing_requests_section.dart';
import 'package:go_router/go_router.dart';
import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_colors.dart';
import 'widgets/partner_match_app_bar.dart';
import 'widgets/partner_match_hero.dart';
import 'widgets/shared_info_section.dart';
import 'widgets/privacy_control_section.dart';
import '../../../localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../domain/view_models/user_view_model.dart';
import 'partner_dashboard_screen.dart';

class PartnerMatchScreen extends StatelessWidget {
  const PartnerMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();

    if (userViewModel.isPartner) {
      return const PartnerDashboardScreen();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const PartnerMatchAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: 20,
              ),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  PartnerMatchHero(),

                  // Bekleyen istekler en üstte: erişimi vermek sahibin
                  // kararı ve bekleyen bir istek varsa ilk görülmesi
                  // gereken şey o.
                  PairingRequestsSection(),

                  SizedBox(height: 32),
                  SharedInfoSection(),
                  SizedBox(height: 32),
                  PrivacyControlSection(),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Fixed Bottom Action Area
          Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withAlpha(12)
                      : Colors.grey.shade200,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.pushNamed(RouteNames.partnerQrGen);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: theme.colorScheme.primary.withAlpha(76),
                  ),
                  icon: const Icon(Icons.qr_code_2, size: 20),
                  label: Text(
                    context.tr('partner_match_invite_button'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    context.pushNamed(RouteNames.partnerScan);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: theme.colorScheme.primary.withAlpha(127),
                    ),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: Text(
                    context.tr('partner_match_scan_button'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    _showHowItWorksDialog(context);
                  },
                  child: Text(
                    context.tr('partner_match_how_it_works'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade500,
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

  void _showHowItWorksDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceWarmDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.tr('partner_match_how_it_works'),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStep(
              context,
              '1',
              context.tr('partner_step_qr_title'),
              context.tr('partner_step_qr_desc'),
              Icons.qr_code_2,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildStep(
              context,
              '2',
              context.tr('partner_step_scan_title'),
              context.tr('partner_step_scan_desc'),
              Icons.qr_code_scanner,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildStep(
              context,
              '3',
              context.tr('partner_step_track_title'),
              context.tr('partner_step_track_desc'),
              Icons.favorite,
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.tr('got_it'),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    String number,
    String title,
    String desc,
    IconData icon,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
