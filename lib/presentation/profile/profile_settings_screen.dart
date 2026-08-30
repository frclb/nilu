import 'package:flutter/material.dart';
import '../../design_system/app_theme.dart';
import '../health_check/heavy_bleeding_screen.dart';
import '../../design_system/app_tokens.dart';
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
                    iconColor: Theme.of(context).colorScheme.primary,
                    iconBgColor: context.tokens.brandTint,
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
                    iconColor: Theme.of(context).colorScheme.primary,
                    iconBgColor: context.tokens.brandTint,
                    onTap: () {
                      context.pushNamed(RouteNames.cycleSettings);
                    },
                  ),
                  // Yoğun kanama kendini değerlendirme aracı.
                  //
                  // Uygulama akış yoğunluğunu zaten soruyordu ama "ağır"
                  // herkes için farklı bir şey; NHS'in somut ölçütleri
                  // karşılaştırılabilir bir zemin veriyor.
                  SettingsItem(
                    title: context.tr('profile_bleeding_check'),
                    icon: Icons.monitor_heart_outlined,
                    iconColor: Theme.of(context).colorScheme.primary,
                    iconBgColor: context.tokens.brandTint,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HeavyBleedingScreen(),
                      ),
                    ),
                  ),
                  // Dynamic Partner Settings Item
                  if (context.watch<UserViewModel>().hasPartner)
                    SettingsItem(
                      title: context.tr('profile_partner_settings'),
                      icon: Icons.favorite_border,
                      iconColor: Theme.of(context).colorScheme.primary,
                      iconBgColor: context.tokens.brandTint,
                      onTap: () {
                        context.pushNamed(RouteNames.partnerShareSettings);
                      },
                    )
                  else
                    SettingsItem(
                      title: context.tr('profile_partner_connect'),
                      icon: Icons.person_add_alt_1_outlined,
                      iconColor: Theme.of(context).colorScheme.primary,
                      iconBgColor: context.tokens.brandTint,
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
                    iconColor: Theme.of(context).colorScheme.primary,
                    iconBgColor: context.tokens.brandTint,
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
                  iconColor: Theme.of(context).colorScheme.primary,
                  iconBgColor: context.tokens.brandTint,
                  onTap: () {
                    context.pushNamed(RouteNames.notificationSettings);
                  },
                ),
                SettingsItem(
                  title: context.tr('health_sync_title'),
                  icon: Icons.favorite_outline,
                  iconColor: Theme.of(context).colorScheme.primary,
                  iconBgColor: context.tokens.brandTint,
                  onTap: () {
                    context.pushNamed(RouteNames.healthSync);
                  },
                ),
                SettingsItem(
                  title: context.tr('appearance_title'),
                  icon: Icons.palette_outlined,
                  iconColor: context.tokens.accent,
                  iconBgColor: context.tokens.accentTint,
                  onTap: () {
                    context.pushNamed(RouteNames.appearance);
                  },
                ),
                SettingsItem(
                  title: context.tr('profile_privacy_security'),
                  icon: Icons.lock_outline,
                  iconColor: Theme.of(context).colorScheme.primary,
                  iconBgColor: context.tokens.brandTint,
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
                  iconColor: Theme.of(context).colorScheme.primary,
                  iconBgColor: context.tokens.brandTint,
                  onTap: () {
                    context.pushNamed(RouteNames.privacyPolicy);
                  },
                ),
                SettingsItem(
                  title: context.tr('terms_of_service_title'),
                  icon: Icons.gavel_outlined,
                  iconColor: Theme.of(context).colorScheme.primary,
                  iconBgColor: context.tokens.brandTint,
                  onTap: () {
                    context.pushNamed(RouteNames.termsOfService);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            TextButton.icon(
              onPressed: () => _confirmAndSignOut(context),
              // Kırmızıydı. Çıkış yıkıcı bir işlem değil — oturum kapanıyor,
              // kayıtlı veri cihazda kalıyor. Kırmızı, hesap silmeye ait.
              icon: Icon(Icons.logout, size: 20, color: context.tokens.text),
              label: Text(
                context.tr('profile_logout'),
                style: TextStyle(
                  color: context.tokens.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: Colors.transparent,
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
                  // Biçimler `dialogTheme`'den; burada elle beyaz/siyah ve
                  // gri tonlar yazılıydı ve temayı takip etmiyorlardı.
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(context.tr('clear_cache_title')),
                      content: Text(context.tr('clear_cache_desc')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(context.tr('cancel')),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: AppTheme.dialogAction().copyWith(
                            backgroundColor: WidgetStatePropertyAll(
                              context.tokens.danger,
                            ),
                            foregroundColor: const WidgetStatePropertyAll(
                              Colors.white,
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
                // Yumurtlama rengindeydi; önbellek temizlemenin döngüyle
                // ilgisi yok ve mor buraya anlam yüklüyordu.
                color: context.tokens.textMuted,
              ),
              label: Text(
                context.tr('profile_clear_cache'),
                style: TextStyle(
                  color: context.tokens.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                backgroundColor: context.tokens.surfaceAlt,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Version Info
            Text(
              "v1.0.0",
              style: TextStyle(color: context.tokens.textFaint, fontSize: 12),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Onay alır ve gerçekten oturumu kapatır.
  ///
  /// Eskiden bu düğme yalnızca `/onboarding`'e gidiyordu: uzak oturum açık
  /// kalıyor, `onboarding_complete` bayrağı true kalıyordu. Sonuç olarak
  /// uygulama yeniden açıldığında doğruca ana ekrana dönülüyor, hatta durum
  /// her değiştiğinde kullanıcı ana ekrana geri sıçrıyordu.
  Future<void> _confirmAndSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // Başlık ve gövde biçimleri `dialogTheme`'den geliyor; burada elle
        // beyaz/siyah ve gri tonlar yazılıydı, tema değişse de sabit
        // kalıyorlardı.
        title: Text(dialogContext.tr('logout_confirm_title')),
        content: Text(dialogContext.tr('logout_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('cancel')),
          ),
          // Ham `Colors.red` idi. Çıkış yıkıcı bir işlem değil — metnin
          // kendisi "kayıtlı sağlık verileriniz cihazda kalır" diyor. Kırmızı
          // burada olduğundan ağır bir uyarı veriyordu; hesap silmeye
          // saklandı.
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: AppTheme.dialogAction(),
            child: Text(dialogContext.tr('profile_logout')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Oturumu kapat. Router `refreshListenable` üzerinden durumu görüp
    // kullanıcıyı onboarding'e yönlendirir — elle gezinmeye gerek yok.
    await context.read<UserViewModel>().signOut();
  }
}
