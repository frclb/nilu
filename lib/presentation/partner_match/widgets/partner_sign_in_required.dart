import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/datasources/remote/account_auth.dart';
import '../../../design_system/app_decor.dart';
import '../../../design_system/app_snack.dart';
import '../../../design_system/app_tokens.dart';
import '../../../design_system/sign_in_buttons.dart';
import '../../../domain/view_models/account_view_model.dart';
import '../../../localization/app_localizations.dart';
import '../../account/email_sign_in_sheet.dart';

/// Partner eşleşmesi hesap istiyor: Apple, Google ya da e-postayla giriş.
///
/// Eşleşme eskiden anonim bir Firebase kimliğiyle kuruluyordu. Artık hesap
/// şart: eşleşme ve paylaşılan durum hesaba bağlı kalıyor ve "Hesabı sil"
/// hepsini birlikte kaldırıyor. Giriş tek başına hiçbir sağlık verisi
/// göndermiyor; bulut eşitleme ayrı bir rızayla açılıyor.
class PartnerSignInRequired extends StatelessWidget {
  const PartnerSignInRequired({super.key, required this.onSignedIn});

  /// Giriş tamamlandı: ekran kimliği yeniden okusun.
  final VoidCallback onSignedIn;

  Future<void> _signIn(BuildContext context, AccountProvider provider) async {
    final sonuc = await context.read<AccountViewModel>().signIn(provider);
    if (!context.mounted) return;
    switch (sonuc.status) {
      case SignInStatus.signedIn:
        onSignedIn();
      case SignInStatus.cancelled:
        break;
      case SignInStatus.failed:
        AppSnack.error(context, context.tr('account_sign_in_failed'));
      case SignInStatus.unavailable:
        AppSnack.error(context, context.tr('account_unavailable'));
    }
  }

  Future<void> _signInWithEmail(BuildContext context) async {
    if (await showEmailSignInSheet(context)) onSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AccountViewModel>().busy;
    final t = context.tokens;
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          key: const Key('partner_sign_in_required'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: AppIconTile(
                icon: Icons.account_circle_outlined,
                size: 80,
                circle: true,
                background: t.brandTint,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('partner_sign_in_title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr('partner_sign_in_body'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 28),
            // Apple önce ve en az Google kadar belirgin (Yönergeler 4.8).
            SignInButton.apple(
              key: const Key('partner_sign_in_apple'),
              label: context.tr('account_continue_apple'),
              onPressed: busy
                  ? null
                  : () => _signIn(context, AccountProvider.apple),
            ),
            const SizedBox(height: 12),
            SignInButton.google(
              key: const Key('partner_sign_in_google'),
              label: context.tr('account_continue_google'),
              onPressed: busy
                  ? null
                  : () => _signIn(context, AccountProvider.google),
            ),
            const SizedBox(height: 12),
            EmailSignInButton(
              key: const Key('partner_sign_in_email'),
              label: context.tr('account_continue_email'),
              onPressed: busy ? null : () => _signInWithEmail(context),
            ),
            if (busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
