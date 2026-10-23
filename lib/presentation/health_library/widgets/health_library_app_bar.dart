import 'package:flutter/material.dart';

import '../../../design_system/app_decor.dart';
import '../../widgets/profile_avatar_button.dart';

/// Kütüphane sekmesinin üst çubuğu: logo, "Nilu" ve profil düğmesi.
///
/// Sekme kökleri aynı marka çubuğunu paylaşıyor; sayfanın kendi başlığı
/// içerikte, serif ve büyük.
class HealthLibraryAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const HealthLibraryAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: AppBrandBar(trailing: ProfileAvatarButton()),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
