import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../widgets/profile_avatar_button.dart';

/// Takvim sekmesinin üst çubuğu: logo ve "Nilu", sağda profil düğmesi.
///
/// Diğer sekme kökleriyle aynı çubuk; ekranın kendi başlığı ve ayar düğmesi
/// içerikle birlikte kayıyor (bkz. [CalendarTitleRow]). Sabit kalsalardı
/// küçük telefonda takvime ayrılan yükseklik iki çubuk kadar daralırdı.
class CalendarAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CalendarAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppBrandBar(trailing: ProfileAvatarButton());
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

/// Ekranın başlığı ("Takvimim") ve döngü ayarlarına giden düğme.
class CalendarTitleRow extends StatelessWidget {
  const CalendarTitleRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          // Başlık ortada kalsın diye sağdaki düğme kadar boşluk.
          const SizedBox(width: 48),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                context.tr('calendar_title'),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 26,
                  color: primary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: context.tr('cycle_settings_title'),
            onPressed: () => context.pushNamed(RouteNames.cycleSettings),
            icon: const Icon(Icons.tune, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: t.brandTint,
              foregroundColor: primary,
              fixedSize: const Size(40, 40),
              minimumSize: const Size(40, 40),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
