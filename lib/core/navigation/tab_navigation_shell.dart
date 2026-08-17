import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/home/widgets/custom_bottom_nav.dart';

/// Kalıcı alt menüyü (Bottom Navigation) barındıran kabuk yapısı.
/// Bu sayede sekmeler arası geçişte her sekmenin kendi ayrı stack'i korunur.
class TabNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TabNavigationShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
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
