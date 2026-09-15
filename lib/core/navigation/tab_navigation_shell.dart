import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/app_layout.dart';
import '../../presentation/home/widgets/custom_bottom_nav.dart';
import '../../presentation/home/widgets/side_nav_rail.dart';

/// Kalıcı gezinme menüsünü barındıran kabuk yapısı.
/// Bu sayede sekmeler arası geçişte her sekmenin kendi ayrı stack'i korunur.
///
/// Menü genişliğe göre yer değiştiriyor: dar ekranda altta, geniş ekranda
/// yanda. İkisi de [navDestinations] listesinden besleniyor, dolayısıyla
/// hedefler tek yerde tanımlı.
class TabNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TabNavigationShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final useRail = context.layoutClass == LayoutClass.expanded;

    if (!useRail) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: CustomBottomNav(
          selectedIndex: navigationShell.currentIndex,
          onTap: (index) => _onTap(context, index),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // Yan menü çentik/ada boşluğunu kendi yiyor; gövde onun sağında
          // temiz bir dikdörtgen olarak kalıyor.
          SafeArea(
            right: false,
            child: SideNavRail(
              selectedIndex: navigationShell.currentIndex,
              onTap: (index) => _onTap(context, index),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    /// Eğer tıklandığında mevcut branch aynıysa kök rotaya dönülmesini sağlaması için initialLocation true yapılır
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
