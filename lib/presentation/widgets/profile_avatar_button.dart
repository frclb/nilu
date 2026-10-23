import 'package:flutter/material.dart';

import '../../core/navigation/navigation_service.dart';
import '../../core/navigation/route_names.dart';
import '../../data/repositories/profile_repository.dart';
import '../../design_system/content_illustration.dart';
import '../../localization/app_localizations.dart';

/// Sekme köklerinin sağ üstündeki profil düğmesi: adın baş harfi, dokununca
/// Profil sekmesi.
///
/// Ad cihazdaki profilden okunuyor; girilmemişse kişi simgesi. Fotoğraf
/// yok: uygulama uzak görsel yüklemiyor ve kullanıcıdan fotoğraf istemiyor.
class ProfileAvatarButton extends StatefulWidget {
  const ProfileAvatarButton({super.key, this.size = 38});

  final double size;

  @override
  State<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<ProfileAvatarButton> {
  String? _name;

  @override
  void initState() {
    super.initState();
    const ProfileRepository().getName().then((name) {
      if (mounted) setState(() => _name = name);
    });
  }

  @override
  Widget build(BuildContext context) {
    // VoiceOver'da "Profil, düğme": baş harf tek başına bir şey söylemiyor.
    return Semantics(
      button: true,
      label: context.tr('nav_profile'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => NavigationService().go(RouteNames.profile),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: InitialAvatar(name: _name, size: widget.size),
          ),
        ),
      ),
    );
  }
}
