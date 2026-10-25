import '../pregnancy/return_to_cycle.dart';
import '../pregnancy/due_date_sheet.dart';
import '../../localization/date_names.dart';
import '../../domain/view_models/pregnancy_view_model.dart';
import '../../domain/models/conception_intent.dart';
import '../../domain/models/cycle_info.dart';
import '../../domain/models/life_stage.dart';
import 'package:flutter/material.dart';
import '../health_check/heavy_bleeding_screen.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/content_illustration.dart';
import 'package:go_router/go_router.dart';
import '../../localization/app_localizations.dart';
import '../../core/navigation/route_names.dart';
import '../../core/platform/app_platform.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/view_models/account_view_model.dart';
import '../../domain/view_models/theme_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../calendar/view_models/calendar_view_model.dart';
import '../widgets/profile_avatar_button.dart';
import 'widgets/premium_banner.dart';
import 'widgets/settings_group.dart';
import 'widgets/settings_surface.dart';
import '../../design_system/app_layout.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  static const _repository = ProfileRepository();

  String? _name;
  String? _email;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    final name = await _repository.getName();
    final email = await _repository.getEmail();
    if (!mounted) return;
    setState(() {
      _name = name?.trim();
      _email = email?.trim();
    });
  }

  /// Kişisel bilgiler ekranı; dönüşte kimlik kartı yenileniyor — yoksa
  /// kart, az önce değiştirilen adı göstermeye devam ederdi.
  Future<void> _openPersonalInfo() async {
    await context.pushNamed(RouteNames.personalInfo);
    if (mounted) await _loadIdentity();
  }

  @override
  Widget build(BuildContext context) {
    final isPartner = context.watch<UserViewModel>().isPartner;
    final primary = Theme.of(context).colorScheme.primary;
    final tint = context.tokens.brandTint;

    return Scaffold(
      body: AmbientBackground(
        child: SizedBox.expand(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Sekme kökü: üstte marka çubuğu.
                const AppContentWidth(
                  child: AppBrandBar(trailing: ProfileAvatarButton()),
                ),
                Expanded(
                  child: AppContentWidth(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _IdentityCard(
                            name: _name,
                            email: _email,
                            isPartner: isPartner,
                            onEdit: isPartner ? null : _openPersonalInfo,
                          ),
                          const SizedBox(height: 20),
                          const PremiumBanner(),
                          const SizedBox(height: 28),

                          // Group 1: Account (Only for standard users)
                          if (!isPartner) ...[
                            SettingsGroup(
                              title: context.tr('profile_account'),
                              items: [
                                SettingsItem(
                                  title: context.tr('profile_personal_info'),
                                  icon: Icons.person_rounded,
                                  iconColor: primary,
                                  iconBgColor: tint,
                                  onTap: _openPersonalInfo,
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
                                  icon: Icons.cloud_sync_outlined,
                                  iconColor: primary,
                                  iconBgColor: tint,
                                  onTap: () {
                                    context.pushNamed(RouteNames.account);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],

                          // Gebelik bölümü (yalnızca kendi kaydını tutan
                          // kullanıcı).
                          //
                          // Giriş noktası burada ve kasten sakin: gecikmede
                          // ana ekranda gebelik önermek her gecikmede
                          // rahatsız edici olurdu (bkz. `PREGNANCY_MODE.md`
                          // §5).
                          if (!isPartner) ...[
                            const _GebelikBolumu(),
                            const SizedBox(height: 28),
                          ],

                          // Group 2: Application (Standard users only)
                          if (!isPartner) ...[
                            SettingsGroup(
                              title: context.tr('profile_application'),
                              items: [
                                SettingsItem(
                                  title: context.tr('profile_cycle_settings'),
                                  icon: Icons.spa_rounded,
                                  iconColor: primary,
                                  iconBgColor: tint,
                                  onTap: () {
                                    context.pushNamed(RouteNames.cycleSettings);
                                  },
                                ),
                                // Yoğun kanama kendini değerlendirme aracı.
                                //
                                // Uygulama akış yoğunluğunu zaten soruyordu
                                // ama "ağır" herkes için farklı bir şey;
                                // NHS'in somut ölçütleri karşılaştırılabilir
                                // bir zemin veriyor.
                                SettingsItem(
                                  title: context.tr('profile_bleeding_check'),
                                  icon: Icons.water_drop_rounded,
                                  iconColor: context.tokens.secondary,
                                  iconBgColor: tint,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const HeavyBleedingScreen(),
                                    ),
                                  ),
                                ),
                                // Dynamic Partner Settings Item
                                if (context.watch<UserViewModel>().hasPartner)
                                  SettingsItem(
                                    title: context.tr(
                                      'profile_partner_settings',
                                    ),
                                    icon: Icons.favorite_rounded,
                                    iconColor: primary,
                                    iconBgColor: tint,
                                    onTap: () {
                                      context.pushNamed(
                                        RouteNames.partnerShareSettings,
                                      );
                                    },
                                  )
                                else
                                  SettingsItem(
                                    title: context.tr(
                                      'profile_partner_connect',
                                    ),
                                    icon: Icons.person_add_alt_1_outlined,
                                    iconColor: primary,
                                    iconBgColor: tint,
                                    onTap: () {
                                      context.pushNamed(RouteNames.partner);
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 28),
                          ],

                          // Group 3: Security & Support
                          SettingsGroup(
                            title: context.tr('profile_other'),
                            items: [
                              // Genel bildirimler ve Apple Sağlık partnere
                              // gösterilmiyor.
                              //
                              // İkisi de cihazın **kendi** döngü verisine
                              // dayanıyor; partnerin öyle bir verisi yok.
                              // Genel bildirim anahtarları yalnızca
                              // `ReminderSync`'i besliyor ve o partner
                              // modunda çalışmıyor — partner açıp kapattığı
                              // hâlde hiçbir şeyin değişmediği anahtarlar
                              // görüyordu. Sağlık içe aktarma da aktaracak
                              // bir şey bulamazdı.
                              //
                              // Partnerin kendi bildirim ayarları yukarıdaki
                              // "Partner Ayarları" grubunda.
                              if (!isPartner) ...[
                                SettingsItem(
                                  title: context.tr('profile_notifications'),
                                  icon: Icons.notifications_active_outlined,
                                  iconColor: primary,
                                  iconBgColor: tint,
                                  onTap: () {
                                    context.pushNamed(
                                      RouteNames.notificationSettings,
                                    );
                                  },
                                ),
                                // Ana ekran widget'ı uygulamada var ama onu
                                // tanıtan ekran hiçbir yerden açılmıyordu:
                                // rota tanımlıydı, kapısı yoktu. Android'de
                                // widget (ve Sağlık eşitlemesi) henüz yok.
                                if (AppPlatform.homeWidget)
                                  SettingsItem(
                                    title: context.tr('widgets_title'),
                                    icon: Icons.widgets_outlined,
                                    iconColor: primary,
                                    iconBgColor: tint,
                                    onTap: () {
                                      context.pushNamed(
                                        RouteNames.widgetsPreview,
                                      );
                                    },
                                  ),
                                if (AppPlatform.healthSync)
                                  SettingsItem(
                                    title: context.tr('health_sync_title'),
                                    icon: Icons.monitor_heart_outlined,
                                    iconColor: primary,
                                    iconBgColor: tint,
                                    onTap: () {
                                      context.pushNamed(RouteNames.healthSync);
                                    },
                                  ),
                              ],
                              SettingsItem(
                                title: context.tr('appearance_title'),
                                // Seçili temanın adı: gerçek durum.
                                subtitle: context.tr(
                                  context
                                      .watch<ThemeViewModel>()
                                      .flavor
                                      .labelKey,
                                ),
                                icon: Icons.palette_outlined,
                                iconColor: context.tokens.accent,
                                iconBgColor: context.tokens.accentTint,
                                onTap: () {
                                  context.pushNamed(RouteNames.appearance);
                                },
                              ),
                              SettingsItem(
                                title: context.tr('profile_privacy_security'),
                                icon: Icons.lock_outline_rounded,
                                iconColor: primary,
                                iconBgColor: tint,
                                onTap: () {
                                  context.pushNamed(RouteNames.privacySecurity);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Group 4: Legal
                          SettingsGroup(
                            title: context.tr('profile_legal'),
                            items: [
                              SettingsItem(
                                title: context.tr('privacy_policy_title'),
                                icon: Icons.policy_outlined,
                                iconColor: primary,
                                iconBgColor: tint,
                                onTap: () {
                                  context.pushNamed(RouteNames.privacyPolicy);
                                },
                              ),
                              SettingsItem(
                                title: context.tr('terms_of_service_title'),
                                icon: Icons.description_outlined,
                                iconColor: primary,
                                iconBgColor: tint,
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
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: context.tokens.textFaint,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profilin başındaki kimlik kartı: ekran başlığı, adın baş harfi, ad,
/// e-posta ve bugünün döngü günü.
///
/// Fotoğraf yok: uygulama kullanıcıdan fotoğraf istemiyor. Abonelik rozeti
/// de yok — durum hemen alttaki Premium kartında yazıyor.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.email,
    required this.isPartner,
    required this.onEdit,
  });

  final String? name;
  final String? email;
  final bool isPartner;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final hasName = name != null && name!.isNotEmpty;
    final hasEmail = email != null && email!.isNotEmpty;
    final dongu = isPartner ? null : _cycleLine(context);

    return SettingsCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              context.tr('profile_title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          // Partnere kişisel bilgi ekranı kapalı; adı da yoksa boş bir
          // satır göstermenin anlamı yok.
          if (!isPartner || hasName) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                InitialAvatar(name: name, size: 64),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Ad girilmemişse alanın kendi etiketi. "Kişisel
                        // Bilgiler" yazmak, aşağıdaki satırın metnini
                        // ekranda ikinci kez göstermek olurdu.
                        hasName ? name! : context.tr('personal_info_name'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: hasName ? t.text : t.textFaint,
                        ),
                      ),
                      if (hasEmail) ...[
                        const SizedBox(height: 2),
                        Text(
                          email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: t.textMuted,
                          ),
                        ),
                      ],
                      if (dongu != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.calendar_month_outlined,
                                size: 14,
                                color: t.secondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                dongu,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: t.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (onEdit != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: context.tr('profile_personal_info'),
                    onPressed: onEdit,
                    style: IconButton.styleFrom(
                      backgroundColor: t.brandTint,
                      foregroundColor: theme.colorScheme.primary,
                      minimumSize: const Size(44, 44),
                    ),
                    // `edit_outlined` değil: tarih seçicinin "elle yaz"
                    // düğmesi o simgeyi kullanıyor.
                    icon: const Icon(Icons.edit_rounded, size: 18),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// "Döngü günü 18 · Luteal Faz" — ana ekrandaki başlıkla aynı kaynaktan.
  ///
  /// Yalnızca döngü evresinde ve gün biliniyorsa. Gecikmede evre adı yok:
  /// beklenen regl geçtikten sonra döngünün nerede olduğu bilinmiyor.
  static String? _cycleLine(BuildContext context) {
    if (context.watch<PregnancyViewModel>().stage != LifeStage.cycle) {
      return null;
    }
    final info = context.watch<CalendarViewModel>().cycleInfo;
    final day = info.currentCycleDay;
    if (day == null) return null;
    final gun = context.tr('home_headline_cycle_day', params: {'n': '$day'});
    if (info.daysLateAt(DateTime.now()) > 0) return gun;
    final evre = switch (info.currentPhase) {
      CyclePhase.menstruation => 'phase_title_menstruation',
      CyclePhase.follicular => 'phase_title_follicular',
      CyclePhase.ovulation => 'phase_title_ovulation',
      CyclePhase.luteal => 'phase_title_luteal',
      CyclePhase.suppressed || CyclePhase.unknown => null,
    };
    return evre == null ? gun : '$gun · ${context.tr(evre)}';
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
          icon: Icons.yard_outlined,
          iconColor: context.tokens.accent,
          iconBgColor: context.tokens.accentTint,
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
