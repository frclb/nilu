import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/navigation/route_names.dart';
import '../../../domain/view_models/user_view_model.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';
import 'widgets/connected_partner_card.dart';
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
    final user = context.watch<UserViewModel>();
    final connected = user.hasPartner && !user.isPartner;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: t.text, size: 20),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.tr('partner_share_title'),
          style: TextStyle(
            color: t.text,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: AppContentWidth(
        child: connected
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  ConnectedPartnerCard(),
                  SizedBox(height: 32),
                  PrivacyControlSection(),
                  SizedBox(height: 32),
                  SharedInfoSection(),
                ],
              )
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link_off, size: 64, color: t.textMuted),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('partner_none_title'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('partner_none_desc'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: t.textMuted),
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
