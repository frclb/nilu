import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/route_names.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import '../../widgets/profile_avatar_button.dart';

/// İçgörüler sekmesinin üst çubuğu: logo, "Nilu" ve profil düğmesi.
///
/// Burada eskiden üç sekme vardı — Genel / Aktivite / Beslenme — ama yalnızca
/// ilki bir şey gösteriyordu; diğer ikisi "yakında eklenecek" uyarısı basıyordu.
/// Var olmayan bölümleri sekme olarak göstermek kullanıcıya olmayan bir içerik
/// vaat ediyordu, kaldırıldı.
///
/// Geri düğmesi de yok: ekran alt menüdeki kök sekmelerden biri, geri
/// gidilecek bir yer yok. Sekme kökleri aynı marka çubuğunu paylaşıyor.
class InsightsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const InsightsAppBar({super.key});

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

/// Sayfa başlığı ve "Verine sor" girişi.
///
/// Soru sorma girişi burada: sorular zaten bu ekranın hesapladığı sayılarla
/// cevaplanıyor. Bir sohbet robotu değil — simgesi ve dili de öyle
/// davranmıyor.
class InsightsHeader extends StatelessWidget {
  const InsightsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    // Büyük yazıda düğme başlığın altına iniyor; yan yana sıkıştırmak
    // başlığı "İçg…" diye kesiyordu.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconTile(
              icon: Icons.insights,
              size: 38,
              circle: true,
              background: t.surfaceAlt,
            ),
            const SizedBox(width: 10),
            Semantics(
              header: true,
              child: Text(
                context.tr('insights_title'),
                maxLines: 1,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: 28,
                  height: 1.15,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        AppGradientButton(
          key: const Key('insights_ask_data'),
          label: context.tr('assistant_title'),
          icon: Icons.auto_awesome,
          expand: false,
          height: 44,
          radius: AppRadius.pill,
          gradient: LinearGradient(
            colors: [t.secondary, theme.colorScheme.primary],
          ),
          onPressed: () => context.pushNamed(RouteNames.assistant),
        ),
      ],
    );
  }
}
