import '../pregnancy/return_to_cycle.dart';
import '../pregnancy/due_date_sheet.dart';
import '../../localization/date_names.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../domain/models/conception_intent.dart';
import '../../domain/models/life_stage.dart';
import 'package:flutter/material.dart';
import '../health_check/heavy_bleeding_screen.dart';
import '../../design_system/app_tokens.dart';
import 'package:go_router/go_router.dart';
import '../../localization/app_localizations.dart';
import '../../core/navigation/route_names.dart';
import 'package:provider/provider.dart';
import '../../domain/view_models/account_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import 'widgets/premium_banner.dart';
import 'widgets/settings_group.dart';
import '../../design_system/app_layout.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            color: context.tokens.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [SizedBox(width: 48)],
        centerTitle: true,
      ),
      body: AppContentWidth(
        child: SingleChildScrollView(
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
                    // İsteğe bağlı hesap ve bulut yedeği.
                    SettingsItem(
                      title: context.tr('profile_cloud_account'),
                      subtitle: context.tr(switch (context
                          .watch<AccountViewModel>()) {
                        AccountViewModel(isSignedIn: false) =>
                          'account_signed_out_short',
                        AccountViewModel(syncEnabled: true) =>
                          'account_sync_on_short',
                        _ => 'account_sync_off_short',
                      }),
                      icon: Icons.cloud_outlined,
                      iconColor: Theme.of(context).colorScheme.primary,
                      iconBgColor: context.tokens.brandTint,
                      onTap: () {
                        context.pushNamed(RouteNames.account);
                      },
                    ),
                  ],
                ),
              if (!context.watch<UserViewModel>().isPartner)
                const SizedBox(height: 24),

              // Gebelik bölümü (yalnızca kendi kaydını tutan kullanıcı).
              //
              // Giriş noktası burada ve kasten sakin: gecikmede ana ekranda
              // gebelik önermek her gecikmede rahatsız edici olurdu
              // (bkz. `PREGNANCY_MODE.md` §5).
              if (!context.watch<UserViewModel>().isPartner) ...[
                const _GebelikBolumu(),
                const SizedBox(height: 24),
              ],

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

              // Group 3: Security & Support
              SettingsGroup(
                title: context.tr('profile_other'),
                items: [
                  // Genel bildirimler ve Apple Sağlık partnere gösterilmiyor.
                  //
                  // İkisi de cihazın **kendi** döngü verisine dayanıyor;
                  // partnerin öyle bir verisi yok. Genel bildirim anahtarları
                  // yalnızca `ReminderSync`'i besliyor ve o partner modunda
                  // çalışmıyor — partner açıp kapattığı hâlde hiçbir şeyin
                  // değişmediği anahtarlar görüyordu. Sağlık içe aktarma da
                  // aktaracak bir şey bulamazdı.
                  //
                  // Partnerin kendi bildirim ayarları yukarıdaki "Partner
                  // Ayarları" grubunda.
                  if (!context.watch<UserViewModel>().isPartner) ...[
                    SettingsItem(
                      title: context.tr('profile_notifications'),
                      icon: Icons.notifications_none_outlined,
                      iconColor: Theme.of(context).colorScheme.primary,
                      iconBgColor: context.tokens.brandTint,
                      onTap: () {
                        context.pushNamed(RouteNames.notificationSettings);
                      },
                    ),
                    // Ana ekran widget'ı uygulamada var ama onu tanıtan ekran
                    // hiçbir yerden açılmıyordu: rota tanımlıydı, kapısı yoktu.
                    SettingsItem(
                      title: context.tr('widgets_title'),
                      icon: Icons.widgets_outlined,
                      iconColor: Theme.of(context).colorScheme.primary,
                      iconBgColor: context.tokens.brandTint,
                      onTap: () {
                        context.pushNamed(RouteNames.widgetsPreview);
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
                  ],
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

              // Version Info
              Text(
                "v1.0.0",
                style: TextStyle(color: context.tokens.textFaint, fontSize: 12),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _GebelikBolumu extends StatelessWidget {
  const _GebelikBolumu();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PregnancyViewModel>();
    final renk = Theme.of(context).colorScheme.primary;
    final zemin = context.tokens.brandTint;
    final g = vm.current;

    final List<SettingsItem> satirlar = switch (vm.stage) {
      LifeStage.cycle => [
        SettingsItem(
          title: context.tr('profile_preg_mark'),
          icon: Icons.pregnant_woman,
          iconColor: renk,
          iconBgColor: zemin,
          onTap: () => context.pushNamed(RouteNames.pregnancySetup),
        ),
        SettingsItem(
          title: context.tr('profile_preg_ttc'),
          subtitle: context.tr('profile_preg_ttc_body'),
          icon: Icons.spa_outlined,
          iconColor: renk,
          iconBgColor: zemin,
          onTap: () => vm.setConception(vm.conception == null),
          trailing: Switch(
            key: const Key('profile_ttc_switch'),
            value: vm.conception != null,
            onChanged: vm.setConception,
          ),
        ),
        // Hekime danışma önerisi bu günden sayılıyor; yanlış girildiyse
        // düzeltilebilmeli.
        if (vm.conception case final niyet?)
          SettingsItem(
            title: context.tr('profile_preg_ttc_since'),
            subtitle:
                '${niyet.since.day} ${context.monthName(niyet.since.month)} '
                '${niyet.since.year}',
            icon: Icons.event_outlined,
            iconColor: renk,
            iconBgColor: zemin,
            onTap: () async {
              final bugun = DateTime.now();
              final secilen = await showDatePicker(
                context: context,
                initialDate: niyet.since,
                firstDate: DateTime(bugun.year - ConceptionIntent.maxYearsBack),
                lastDate: bugun,
              );
              if (secilen != null) await vm.setConceptionSince(secilen);
            },
          ),
      ],
      LifeStage.pregnancy => [
        SettingsItem(
          title: context.tr('profile_preg_due'),
          subtitle: g == null
              ? null
              : '${g.estimatedDueDate.day} '
                    '${context.monthName(g.estimatedDueDate.month)} '
                    '${g.estimatedDueDate.year}',
          icon: Icons.event_outlined,
          iconColor: renk,
          iconBgColor: zemin,
          onTap: () => showDueDateSheet(context),
        ),
        SettingsItem(
          title: context.tr('profile_preg_care'),
          icon: Icons.event_note_outlined,
          iconColor: renk,
          iconBgColor: zemin,
          onTap: () => context.pushNamed(RouteNames.careList),
        ),
        SettingsItem(
          title: context.tr('care_summary_title'),
          icon: Icons.summarize_outlined,
          iconColor: renk,
          iconBgColor: zemin,
          onTap: () => context.pushNamed(RouteNames.careSummary),
        ),
        SettingsItem(
          title: context.tr('profile_preg_end'),
          icon: Icons.stop_circle_outlined,
          iconColor: renk,
          iconBgColor: zemin,
          onTap: () => context.pushNamed(RouteNames.endPregnancy),
        ),
      ],
      LifeStage.postpartum => [
        SettingsItem(
          title: context.tr('profile_preg_care'),
          icon: Icons.event_note_outlined,
          iconColor: renk,
          iconBgColor: zemin,
          onTap: () => context.pushNamed(RouteNames.careList),
        ),
        SettingsItem(
          title: context.tr('care_summary_title'),
          icon: Icons.summarize_outlined,
          iconColor: renk,
          iconBgColor: zemin,
          onTap: () => context.pushNamed(RouteNames.careSummary),
        ),
        SettingsItem(
          title: context.tr('pp_return_to_cycle'),
          subtitle: context.tr('pp_return_subtitle'),
          icon: Icons.water_drop_outlined,
          iconColor: renk,
          iconBgColor: zemin,
          onTap: () => confirmReturnToCycle(context),
        ),
      ],
    };

    return SettingsGroup(
      title: context.tr('profile_preg_section'),
      items: [
        ...satirlar,
        // Biten gebeliklerin kaydı her evrede açılabilmeli; yalnızca varsa.
        if (vm.pastPregnancies.isNotEmpty)
          SettingsItem(
            title: context.tr('past_preg_title'),
            icon: Icons.history,
            iconColor: renk,
            iconBgColor: zemin,
            onTap: () => context.pushNamed(RouteNames.pastPregnancies),
          ),
      ],
    );
  }
}
