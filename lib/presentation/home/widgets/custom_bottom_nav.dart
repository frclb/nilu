import 'package:flutter/material.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/app_scrim.dart';
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
List<NavDestination> navDestinations({required bool isPartner}) =>
    isPartner ? _partnerDestinations : _standardDestinations;

/// Etiketler kısa tutulur: bunlar sekme adı, ekran başlığı değil. Eskiden
/// 3. sekme `health_library_title` ("Sağlık Kütüphanesi") kullanıyordu; iki
/// satıra taşıp diğer etiketlerle hizasını bozuyordu.
const List<NavDestination> _standardDestinations = [
  NavDestination(
    branchIndex: 0,
    icon: Icons.home_outlined,
    activeIcon: Icons.home_filled,
    labelKey: 'nav_home',
  ),
  NavDestination(
    branchIndex: 1,
    icon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month,
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
    icon: Icons.auto_stories_outlined,
    activeIcon: Icons.auto_stories,
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
    final destinations = navDestinations(isPartner: isPartner);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withAlpha(127),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppScrim.veil(31),
            blurRadius: 15,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
    final primary = theme.colorScheme.primary;
    final muted = theme.textTheme.labelLarge?.color ?? context.tokens.textMuted;
    final color = isActive ? primary : muted;
    final label = context.tr(destination.labelKey);

    return Semantics(
      // Ekran okuyucu "sekme, seçili" diye okusun. Önce yalnızca bir
      // GestureDetector vardı: ne düğme olduğu ne de hangisinin seçili
      // olduğu duyuruluyordu.
      button: true,
      selected: isActive,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: () {
          if (isActive) {
            // Seçili sekmeye tekrar basmak kök ekrana döner; bu bir gezinme
            // değil, o yüzden hafif geri bildirim.
            HapticFeedback.selectionClick();
          } else {
            HapticFeedback.lightImpact();
          }
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 56,
                height: 30,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.secondary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isActive ? destination.activeIcon : destination.icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              // Etiket sistem yazı ölçeğiyle büyüyor ama bir yere kadar:
              // ölçeksiz bırakılırsa en büyük erişilebilirlik ayarında satır
              // taşıyor, tamamen sabitlenirse düşük görmeyen kullanıcı için
              // okunmuyor.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
