import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/route_names.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';
import 'widgets/connected_partner_card.dart';
import 'widgets/partner_match_app_bar.dart';
import 'widgets/privacy_control_section.dart';
import 'widgets/shared_info_section.dart';

/// Profil → Partner Ayarları.
///
/// Önceden sabit bir "Bağlı Partner • Aktif" yazıyor, partnerin adı yerine
/// ham kimliğini gösteriyor ve paylaşım anahtarını rızasız açıp
/// kapatıyordu. Partner sekmesindeki bağlı görünümle aynı parçalar.
class PartnerShareSettingsScreen extends StatelessWidget {
  const PartnerShareSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final user = context.watch<UserViewModel>();
    final connected = user.hasPartner && !user.isPartner;

    return Scaffold(
      backgroundColor: t.background,
      appBar: const PartnerMatchAppBar(
        titleKey: 'partner_share_title',
        showSettings: false,
      ),
      body: AppContentWidth(
        child: connected
            ? ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: const [
                  ConnectedPartnerCard(),
                  SizedBox(height: 28),
                  PrivacyControlSection(),
                  SizedBox(height: 28),
                  SharedInfoSection(),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIconTile(
                        icon: Icons.link_off_rounded,
                        size: 80,
                        circle: true,
                        background: t.brandTint,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.tr('partner_none_title'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('partner_none_desc'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                          color: t.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!user.isPartner)
                        FilledButton(
                          onPressed: () =>
                              context.pushReplacementNamed(RouteNames.partner),
                          child: Text(context.tr('profile_partner_connect')),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
