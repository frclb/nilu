import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../design_system/app_layout.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../../localization/app_localizations.dart';
import 'custom_bottom_nav.dart';

/// Geniş ekranlarda alt menünün yerini alan yan menü.
///
/// iPad yatayda alt menü çubuğu 1366 pt'ye geriliyor, beş simge arasında
/// 250 pt boşluk kalıyor ve başparmağın ulaşamayacağı bir yerde duruyordu.
/// Yan menü hem bu boşluğu yiyor hem de içeriğe dikey alan bırakıyor.
///
/// Hedefler [navDestinations] ile alt menüyle **aynı** kaynaktan geliyor;
/// partner modunun dal atlaması iki yerde ayrı ayrı yazılmıyor.
class SideNavRail extends StatelessWidget {
  const SideNavRail({super.key, this.selectedIndex = 0, this.onTap});

  /// Seçili `StatefulShellRoute` dalı — listedeki sıra değil.
  final int selectedIndex;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPartner = context.watch<UserViewModel>().isPartner;
    final destinations = navDestinations(isPartner: isPartner);

    // Dal sırasından liste sırasına. Eşleşme yoksa (dal menüde görünmüyorsa)
    // hiçbir şey seçili görünmez — alt menüdeki davranışın aynısı.
    final position = destinations.indexWhere(
      (d) => d.branchIndex == selectedIndex,
    );

    return NavigationRail(
      selectedIndex: position < 0 ? null : position,
      onDestinationSelected: (index) {
        final destination = destinations[index];
        if (destination.branchIndex == selectedIndex) {
          HapticFeedback.selectionClick();
        } else {
          HapticFeedback.lightImpact();
        }
        onTap?.call(destination.branchIndex);
      },
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: theme.colorScheme.secondary,
      minWidth: AppLayout.railWidth,
      groupAlignment: -0.85,
      labelType: NavigationRailLabelType.all,
      destinations: [
        for (final destination in destinations)
          NavigationRailDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.activeIcon),
            // Etiket alt menüdeki gibi ölçekleniyor ama bir yere kadar: yan
            // menü sabit genişlikte, en büyük erişilebilirlik ayarında metin
            // taşardı.
            label: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Text(context.tr(destination.labelKey)),
            ),
          ),
      ],
    );
  }
}
