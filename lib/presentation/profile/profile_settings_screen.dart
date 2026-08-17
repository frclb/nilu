import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_colors.dart';
import '../../core/navigation/route_names.dart';
import 'package:provider/provider.dart';
import '../../domain/view_models/user_view_model.dart';
import 'widgets/premium_banner.dart';
import 'widgets/settings_group.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor.withAlpha(204),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text(
          context.tr('profile_title'),
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textMainLight,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [SizedBox(width: 48)],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const PremiumBanner(),
            const SizedBox(height: 24),

            // Group 1: Account (Only for standard users)
            if (!context.watch<UserViewModel>().isPartner)
              SettingsGroup(
                title: context.tr('profile_account'),
                items: [
                  SettingsItem(
                    title: context.tr('profile_personal_info'),
                    icon: Icons.person_outline,
                    iconColor: isDark
                        ? const Color(0xFFF9A8D4)
                        : AppColors.primaryLight,
                    iconBgColor: isDark
                        ? AppColors.primaryLight.withAlpha(127)
                        : AppColors.primaryLight.withAlpha(25),
                    onTap: () {
                      context.pushNamed(RouteNames.personalInfo);
                    },
                  ),
                ],
              ),
            if (!context.watch<UserViewModel>().isPartner)
              const SizedBox(height: 24),

            // Group 2: Application (Standard users only)
            if (!context.watch<UserViewModel>().isPartner)
              SettingsGroup(
                title: context.tr('profile_application'),
                items: [
                  SettingsItem(
                    title: context.tr('profile_cycle_settings'),
                    icon: Icons.water_drop_outlined,
                    iconColor: isDark
                        ? const Color(0xFFFB7185)
                        : AppColors.accentRose,
                    iconBgColor: isDark
                        ? const Color(0xFF881337).withAlpha(76)
                        : const Color(0xFFFFF1F2),
                    onTap: () {
                      context.pushNamed(RouteNames.cycleSettings);
                    },
                  ),
                  // Dynamic Partner Settings Item
                  if (context.watch<UserViewModel>().hasPartner)
                    SettingsItem(
                      title: context.tr('profile_partner_settings'),
                      icon: Icons.favorite_border,
                      iconColor: isDark
                          ? const Color(0xFFC084FC)
                          : const Color(0xFF9333EA),
                      iconBgColor: isDark
                          ? const Color(0xFF581C87).withAlpha(76)
                          : const Color(0xFFFAF5FF),
                      onTap: () {
                        context.pushNamed(RouteNames.partnerShareSettings);
                      },
                    )
                  else
                    SettingsItem(
                      title: context.tr('profile_partner_connect'),
                      icon: Icons.person_add_alt_1_outlined,
                      iconColor: isDark
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF2563EB),
                      iconBgColor: isDark
                          ? const Color(0xFF1E3A8A).withAlpha(76)
                          : const Color(0xFFEFF6FF),
                      onTap: () {
                        context.pushNamed(RouteNames.partner);
                      },
                    ),
                ],
              ),
            if (!context.watch<UserViewModel>().isPartner)
              const SizedBox(height: 24),

            // Partner-Specific Settings (Only for Partner users)
            if (context.watch<UserViewModel>().isPartner)
              SettingsGroup(
                title: context.tr('profile_partner_settings'),
                items: [
                  SettingsItem(
                    title: context.tr('profile_notification_settings'),
                    icon: Icons.notifications_active_outlined,
                    iconColor: isDark
                        ? const Color(0xFFC084FC)
                        : const Color(0xFF9333EA),
                    iconBgColor: isDark
                        ? const Color(0xFF581C87).withAlpha(76)
                        : const Color(0xFFFAF5FF),
                    onTap: () {
                      context.pushNamed(RouteNames.partnerNotificationSettings);
                    },
                  ),
                ],
              ),
            if (context.watch<UserViewModel>().isPartner)
              const SizedBox(height: 24),

            // Group 3: Security & Support
            SettingsGroup(
              title: context.tr('profile_other'),
              items: [
                SettingsItem(
                  title: context.tr('profile_notifications'),
                  icon: Icons.notifications_none_outlined,
                  iconColor: isDark
                      ? const Color(0xFFFBBF24)
                      : AppColors.accentAmber,
                  iconBgColor: isDark
                      ? const Color(0xFF78350F).withAlpha(76)
                      : const Color(0xFFFFFBEB),
                  onTap: () {
                    context.pushNamed(RouteNames.notificationSettings);
                  },
                ),
                SettingsItem(
                  title: context.tr('profile_privacy_security'),
                  icon: Icons.lock_outline,
                  iconColor: isDark
                      ? const Color(0xFF2DD4BF)
                      : const Color(0xFF0D9488),
                  iconBgColor: isDark
                      ? const Color(0xFF134E4A).withAlpha(76)
                      : const Color(0xFFF0FDFA),
                  onTap: () {
                    context.pushNamed(RouteNames.privacySecurity);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Group 4: Legal
            SettingsGroup(
              title: context.tr('profile_legal'),
              items: [
                SettingsItem(
                  title: context.tr('privacy_policy_title'),
                  icon: Icons.description_outlined,
                  iconColor: isDark
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFF3B82F6),
                  iconBgColor: isDark
                      ? const Color(0xFF1E3A8A).withAlpha(76)
                      : const Color(0xFFEFF6FF),
                  onTap: () {
                    context.pushNamed(RouteNames.privacyPolicy);
                  },
                ),
                SettingsItem(
                  title: context.tr('terms_of_service_title'),
                  icon: Icons.gavel_outlined,
                  iconColor: isDark
                      ? const Color(0xFFA78BFA)
                      : const Color(0xFF7C3AED),
                  iconBgColor: isDark
                      ? const Color(0xFF4C1D95).withAlpha(76)
                      : const Color(0xFFF5F3FF),
                  onTap: () {
                    context.pushNamed(RouteNames.termsOfService);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            TextButton.icon(
              onPressed: () {
                context.goNamed(RouteNames.onboarding);
              },
              icon: Icon(
                Icons.logout,
                size: 20,
                color: isDark ? const Color(0xFFF87171) : Colors.grey[500],
              ),
              label: Text(
                context.tr('profile_logout'),
                style: TextStyle(
                  color: isDark ? const Color(0xFFF87171) : Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: isDark
                    ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clear Cache Button
            TextButton.icon(
              onPressed: () async {
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    final isDarkDialog =
                        Theme.of(context).brightness == Brightness.dark;
                    return AlertDialog(
                      title: Text(
                        context.tr('clear_cache_title'),
                        style: TextStyle(
                          color: isDarkDialog ? Colors.white : Colors.black,
                        ),
                      ),
                      content: Text(
                        context.tr('clear_cache_desc'),
                        style: TextStyle(
                          color: isDarkDialog
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),
                      backgroundColor: isDarkDialog
                          ? const Color(0xFF2C2C2E)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            context.tr('cancel'),
                            style: TextStyle(
                              color: isDarkDialog
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(context.tr('delete')),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('cache_cleared'))),
                    );
                  }
                }
              },
              icon: Icon(
                Icons.cleaning_services_outlined,
                size: 20,
                color: isDark ? Colors.blue[300] : Colors.blue[600],
              ),
              label: Text(
                context.tr('profile_clear_cache'),
                style: TextStyle(
                  color: isDark ? Colors.blue[300] : Colors.blue[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: isDark
                    ? Colors.blue[900]!.withValues(alpha: 0.2)
                    : Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Version Info
            Text(
              "v1.0.0",
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
