import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';

/// Partner ekranlarının üst çubuğu: geri, serif başlık, isteğe bağlı ayar.
///
/// Eşleşme, davet kodu ve paylaşım ayarları aynı çubuğu kullanıyor.
class PartnerMatchAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const PartnerMatchAppBar({
    super.key,
    this.titleKey = 'partner_match_title',
    this.showSettings = true,
  });

  final String titleKey;

  /// Sağda paylaşım ayarlarının simgesi (yalnızca eşleşme ekranında).
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final primary = theme.colorScheme.primary;

    return Material(
      color: t.background,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            // Düğmeler 48 pt: iOS'un önerdiği 44'ün üstünde.
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: () {
                    if (context.canPop()) context.pop();
                  },
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  // Büyük yazıda başlık kısalıyor; düğmeler yerinde kalıyor.
                  child: Text(
                    context.tr(titleKey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: primary,
                    ),
                  ),
                ),
                if (showSettings)
                  IconButton(
                    tooltip: context.tr('profile_partner_settings'),
                    onPressed: () =>
                        context.pushNamed(RouteNames.partnerShareSettings),
                    icon: Icon(Icons.tune_rounded, color: primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
