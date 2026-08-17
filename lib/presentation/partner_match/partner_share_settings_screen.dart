import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../../core/navigation/route_names.dart';
import '../../design_system/app_colors.dart';

class PartnerShareSettingsScreen extends StatefulWidget {
  const PartnerShareSettingsScreen({super.key});

  @override
  State<PartnerShareSettingsScreen> createState() =>
      _PartnerShareSettingsScreenState();
}

class _PartnerShareSettingsScreenState
    extends State<PartnerShareSettingsScreen> {
  // Toggle states based on HTML design
  bool _phaseInfoEnabled = true;
  bool _symptomDetailsEnabled = true;
  bool _moodEnabled = false;
  bool _predictionsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final userViewModel = context.watch<UserViewModel>();

    // Custom colors from HTML design
    final primaryColor = const Color(0xFF135BEC);
    final bgColor = isDark
        ? AppColors.backgroundNavyDark
        : AppColors.backgroundLightAlt;
    final surfaceColor = isDark ? AppColors.surfaceNavyDark : Colors.white;
    final textMainColor = isDark ? Colors.white : AppColors.textMainSlate;
    final textMutedColor = isDark
        ? AppColors.textMutedSlateDark
        : AppColors.textMutedSlate;
    final borderColor = isDark
        ? Colors.white.withAlpha(12)
        : AppColors.borderSlateLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? bgColor.withAlpha(204)
            : bgColor.withAlpha(229),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textMainColor, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('partner_share_title'),
          style: TextStyle(
            color: textMainColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: borderColor, height: 1.0),
        ),
      ),
      body: !userViewModel.hasPartner
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off, size: 64, color: textMutedColor),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('partner_none_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textMainColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('partner_none_desc'),
                    style: TextStyle(fontSize: 14, color: textMutedColor),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 24.0,
                      ),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(
                            context,
                            isDark,
                            primaryColor,
                            textMainColor,
                            textMutedColor,
                            bgColor,
                          ),
                          const SizedBox(height: 32),
                          _buildSettingsGroup(
                            context,
                            isDark,
                            primaryColor,
                            surfaceColor,
                            textMainColor,
                            textMutedColor,
                            borderColor,
                          ),
                          const SizedBox(height: 32),
                          _buildSecurityInfo(
                            context,
                            isDark,
                            primaryColor,
                            surfaceColor,
                            textMainColor,
                            textMutedColor,
                            borderColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomAction(context, isDark, textMutedColor),
                ],
              ),
            ),
    );
  }

  // ── Profile Header ──
  Widget _buildProfileHeader(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color textMainColor,
    Color textMutedColor,
    Color bgColor,
  ) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: ClipOval(
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuB65IMTKrrECbjyWOIhOLB1goFUIuwxpRKSVkitQdhkYlN9H9qmh_MXJzi5TB4zvZDM9HB-ZDCPUtuCI34t2P3kndZwBunG4stjPZDEJjQzeNjanNFHS0-wT_A9Gwzgx0rFIgMhrKhGNq6vuKd9njPkjU3oBCYtbX9KI2sbzsCUt_5FhW5egbz4NwLJbFurIj9ZWuh9rXSHHRm-wF_4jsjq4MVUDoJ3hQ46qXqA7TeMAlWuLb_IiGhzoqD9HQyuwL1FwTYqM-7IBBU',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: isDark
                          ? Colors.white.withAlpha(25)
                          : Colors.grey[200],
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: textMutedColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E), // green-500
                shape: BoxShape.circle,
                border: Border.all(color: bgColor, width: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          context.watch<UserViewModel>().partnerId != null &&
                  context.watch<UserViewModel>().partnerId!.isNotEmpty
              ? context.watch<UserViewModel>().partnerId!
              : "Partner", // Using partnerId for now, ideally would fetch resolved name
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textMainColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.tr('partner_share_status'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textMutedColor,
          ),
        ),
      ],
    );
  }

  // ── Settings Group (Toggles) ──
  Widget _buildSettingsGroup(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color surfaceColor,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            (context.tr('partner_share_visible_data')).toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: textMutedColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              _buildSwitchTile(
                icon: Icons.bedtime,
                title: context.tr('partner_share_phase_info'),
                subtitle: context.tr('partner_share_phase_info_desc'),
                value: _phaseInfoEnabled,
                onChanged: (val) => setState(() => _phaseInfoEnabled = val),
                primaryColor: primaryColor,
                textMainColor: textMainColor,
                textMutedColor: textMutedColor,
                showBorder: true,
                borderColor: borderColor,
              ),
              _buildSwitchTile(
                icon: Icons.healing,
                title: context.tr('partner_share_symptom_details'),
                subtitle: context.tr('partner_share_symptom_details_desc'),
                value: _symptomDetailsEnabled,
                onChanged: (val) =>
                    setState(() => _symptomDetailsEnabled = val),
                primaryColor: primaryColor,
                textMainColor: textMainColor,
                textMutedColor: textMutedColor,
                showBorder: true,
                borderColor: borderColor,
              ),
              _buildSwitchTile(
                icon: Icons.sentiment_satisfied,
                title: context.tr('partner_share_mood'),
                subtitle: context.tr('partner_share_mood_desc'),
                value: _moodEnabled,
                onChanged: (val) => setState(() => _moodEnabled = val),
                primaryColor: primaryColor,
                textMainColor: textMainColor,
                textMutedColor: textMutedColor,
                showBorder: true,
                borderColor: borderColor,
              ),
              _buildSwitchTile(
                icon: Icons.calendar_month,
                title: context.tr('partner_share_predictions'),
                subtitle: context.tr('partner_share_predictions_desc'),
                value: _predictionsEnabled,
                onChanged: (val) => setState(() => _predictionsEnabled = val),
                primaryColor: primaryColor,
                textMainColor: textMainColor,
                textMutedColor: textMutedColor,
                showBorder: false,
                borderColor: borderColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color primaryColor,
    required Color textMainColor,
    required Color textMutedColor,
    required bool showBorder,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: showBorder
            ? Border(bottom: BorderSide(color: borderColor))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textMainColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: textMutedColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // iOS Style Switch
          CupertinoSwitch(
            value: value,
            activeTrackColor: primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ── Security Info Box ──
  Widget _buildSecurityInfo(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color surfaceColor,
    Color textMainColor,
    Color textMutedColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? surfaceColor : primaryColor.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? borderColor : primaryColor.withAlpha(25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.lock, color: primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "${context.tr('partner_share_data_security')}: ",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textMainColor,
                    ),
                  ),
                  TextSpan(
                    text: context.tr('partner_share_security_desc'),
                    style: TextStyle(color: textMutedColor),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action (Disconnect) ──
  Widget _buildBottomAction(
    BuildContext context,
    bool isDark,
    Color textMutedColor,
  ) {
    final redColor = const Color(0xFFDC2626); // red-600
    final redBgColor = isDark
        ? redColor.withAlpha(25)
        : const Color(0xFFFEF2F2); // red-50
    final redBorderColor = isDark
        ? redColor.withAlpha(76)
        : const Color(0xFFFECACA); // red-200

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final userViewModel = context.read<UserViewModel>();
                // In actual logic, this sets states false
                await userViewModel.setHasPartner(false);
                await userViewModel.setPartnerState(
                  isPartner: false,
                  partnerId: null,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr('partner_share_stop_access_desc'),
                      ),
                    ),
                  );
                  // Partner yetkisini kaldırıp app'in giriş (onboarding) paneline yönlendir
                  context.goNamed(RouteNames.onboarding);
                }
              },
              icon: Icon(Icons.link_off, size: 20, color: redColor),
              label: Text(
                context.tr('partner_share_stop_access'),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: redColor,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: redBgColor,
                foregroundColor: redColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: redBorderColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('partner_share_stop_access_desc'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: textMutedColor.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }
}
