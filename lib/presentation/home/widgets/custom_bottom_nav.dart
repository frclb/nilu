import '../../../domain/models/life_stage.dart';
import '../../../domain/view_models/pregnancy_view_model.dart';
import 'package:flutter/material.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';

/// Alt menüdeki tek bir hedef.
///
/// [branchIndex] `StatefulShellRoute` dalının sırasıdır, listedeki sırası
/// değil. İkisi ayrı olmak zorunda: partner modu İçgörüler dalını atlar, yani
/// listedeki 3. öğe 4 numaralı dala gider.
class NavDestination {
  final int branchIndex;
  final IconData icon;

  /// Seçiliyken kullanılan dolu varyant. Simgeyi yalnızca renkle ayırmak
  /// renk körlüğünde ayırt edilemiyordu.
  final IconData activeIcon;

  /// Lokalizasyon anahtarı. Çözülmüş metin değil: hedef listesi widget ağacı
  /// kurmadan test edilebilsin diye `BuildContext` gerektirmiyor.
  final String labelKey;

  const NavDestination({
    required this.branchIndex,
    required this.icon,
    required this.activeIcon,
    required this.labelKey,
  });
}

/// Alt menüdeki hedefler.
///
/// Saf fonksiyon: dal eşlemesi (özellikle partner modunun 2 numaralı dalı
/// atlaması) burada test edilir.
List<NavDestination> navDestinations({
  required bool isPartner,
  LifeStage stage = LifeStage.cycle,
}) {
  if (isPartner) return _partnerDestinations;
  if (stage == LifeStage.cycle) return _standardDestinations;
  // Gebelik ve lohusalıkta 3. sekme randevular (bkz. `app_router.dart`):
  // aynı dal, farklı ekran — etiket de onunla birlikte değişmeli.
  return [
    for (final d in _standardDestinations)
      d.branchIndex == 2 ? _careDestination : d,
  ];
}

const NavDestination _careDestination = NavDestination(
  branchIndex: 2,
  icon: Icons.event_note_outlined,
  activeIcon: Icons.event_note,
  labelKey: 'nav_care',
);

/// Etiketler kısa tutulur: bunlar sekme adı, ekran başlığı değil. Eskiden
/// 3. sekme `health_library_title` ("Sağlık Kütüphanesi") kullanıyordu; iki
/// satıra taşıp diğer etiketlerle hizasını bozuyordu.
const List<NavDestination> _standardDestinations = [
  NavDestination(
    branchIndex: 0,
    icon: Icons.spa_outlined,
    activeIcon: Icons.spa,
    labelKey: 'nav_home',
  ),
  NavDestination(
    branchIndex: 1,
    icon: Icons.calendar_today_outlined,
    activeIcon: Icons.calendar_today,
    labelKey: 'nav_calendar',
  ),
  NavDestination(
    branchIndex: 2,
    icon: Icons.insights_outlined,
    activeIcon: Icons.insights,
    labelKey: 'nav_insights',
  ),
  NavDestination(
    branchIndex: 3,
    icon: Icons.local_library_outlined,
    activeIcon: Icons.local_library,
    labelKey: 'nav_library',
  ),
  NavDestination(
    branchIndex: 4,
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    labelKey: 'nav_profile',
  ),
];

/// Partner modunda takvim (1) ve İçgörüler (2) dalları atlanır.
///
/// Partnerin cihazında gösterilecek kendi döngü verisi yok. Takip edilen
/// kişinin döngü verisi de partnere **hiç gitmiyor**: paylaşım kanalı
/// yalnızca yakınlık durumunu taşıyor. Takvim sekmesi bu yüzden sabit
/// tarihler gösteren bir maket ekrana bağlıydı — partnerin vücudu hakkında
/// uydurma veri. Sekme, arkasında gerçek bir şey olmadığı için kaldırıldı.
const List<NavDestination> _partnerDestinations = [
  NavDestination(
    branchIndex: 0,
    icon: Icons.favorite_border,
    activeIcon: Icons.favorite,
    labelKey: 'partner_nav_dashboard',
  ),
  NavDestination(
    branchIndex: 3,
    icon: Icons.handshake_outlined,
    activeIcon: Icons.handshake,
    labelKey: 'partner_nav_support',
  ),
  NavDestination(
    branchIndex: 4,
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    labelKey: 'nav_profile',
  ),
];

/// Kalıcı alt menü çubuğu.
class CustomBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  const CustomBottomNav({super.key, this.selectedIndex = 0, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPartner = context.watch<UserViewModel>().isPartner;
    final destinations = navDestinations(
      isPartner: isPartner,
      stage: context.watch<PregnancyViewModel>().stage,
    );

    final t = context.tokens;
    final dark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: t.surface.withAlpha(dark ? 255 : 235),
        border: Border(top: BorderSide(color: t.border.withAlpha(110))),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(dark ? 0 : 8),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              for (final destination in destinations)
                Expanded(
                  child: _NavItem(
                    destination: destination,
                    isActive: selectedIndex == destination.branchIndex,
                    onTap: () => onTap?.call(destination.branchIndex),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavDestination destination;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = context.tokens.textMuted;
    final color = isActive ? scheme.onPrimary : muted;
    final label = context.tr(destination.labelKey);

    return Semantics(
      // Ekran okuyucu "sekme, seçili" diye okusun. Önce yalnızca bir
      // GestureDetector vardı: ne düğme olduğu ne de hangisinin seçili
      // olduğu duyuruluyordu.
      button: true,
      selected: isActive,
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () {
              if (isActive) {
                // Seçili sekmeye tekrar basmak kök ekrana döner; bu bir
                // gezinme değil, o yüzden hafif geri bildirim.
                HapticFeedback.selectionClick();
              } else {
                HapticFeedback.lightImpact();
              }
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            // Seçili sekme dolu bir erik hap: yalnızca renkle değil şekille
            // de ayrışıyor.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: isActive ? AppGradients.mark(context) : null,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: scheme.primary.withAlpha(64),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? destination.activeIcon : destination.icon,
                    color: color,
                    size: 21,
                  ),
                  const SizedBox(height: 2),
                  // Etiket sistem yazı ölçeğiyle büyüyor ama bir yere kadar:
                  // ölçeksiz bırakılırsa en büyük erişilebilirlik ayarında
                  // satır taşıyor, tamamen sabitlenirse düşük görmeyen
                  // kullanıcı için okunmuyor.
                  MediaQuery.withClampedTextScaling(
                    maxScaleFactor: 1.3,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
