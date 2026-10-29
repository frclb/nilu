import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../data/datasources/remote/account_auth.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/brand_lotus.dart';
import '../../design_system/sign_in_buttons.dart';
import '../../domain/view_models/account_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../../localization/app_localizations.dart';
import 'email_sign_in_sheet.dart';
import 'sign_in_notice.dart';

/// Giriş bitti: kaldığı yerden devam — kurulum ya da ana ekran.
///
/// Giriş, e-posta doğrulama ve şifre yenileme ekranları birlikte
/// kullanıyor. E-posta hesabı doğrulanmadıysa yönlendirme oradan doğrulama
/// ekranına geçiriyor.
void continueAfterSignIn(BuildContext context) {
  // Kimlik girişte tazelendi; yönlendirme artık geçiyor.
  final router = GoRouter.of(context);
  if (context.read<UserViewModel>().onboardingComplete) {
    router.goNamed(RouteNames.home);
  } else if (router.canPop()) {
    // Karşılama altta kalsın: kurulumun geri düğmesi oraya dönüyor.
    router.pushReplacementNamed(RouteNames.onboardingGoal);
  } else {
    router.goNamed(RouteNames.onboardingGoal);
  }
}

/// Apple, Google ya da e-postayla giriş: uygulama hesapla kullanılıyor.
///
/// Karşılama sayfalarından sonra, kurulumdan önce geliyor; çıkış yapan ya
/// da hesabını silen kullanıcı da buraya düşüyor (bkz. `resolveRedirect`).
/// Giriş bitince kaldığı yerden devam: kurulum ya da ana ekran.
///
/// Giriş tek başına sağlık verisi göndermiyor: kayıtlar cihazda kalıyor,
/// bulut yedeği ayrı bir rızayla açılıyor (Profil → Hesap ve bulut yedeği).
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  Future<void> _signIn(BuildContext context, AccountProvider provider) async {
    final sonuc = await context.read<AccountViewModel>().signIn(provider);
    if (!context.mounted) return;
    switch (sonuc.status) {
      case SignInStatus.signedIn:
        _continue(context);
      case SignInStatus.cancelled:
        break;
      case SignInStatus.failed:
        AppSnack.error(context, context.tr('account_sign_in_failed'));
      case SignInStatus.unavailable:
        AppSnack.error(context, context.tr('account_unavailable'));
    }
  }

  /// Hatalar sayfanın içinde; buraya yalnızca giriş olunca dönülüyor.
  Future<void> _signInWithEmail(BuildContext context) async {
    if (await showEmailSignInSheet(context) && context.mounted) {
      _continue(context);
    }
  }

  void _continue(BuildContext context) => continueAfterSignIn(context);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = context.watch<AccountViewModel>().busy;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        child: SafeArea(
          child: AppContentWidth(
            child: ListView(
              key: const Key('sign_in'),
              padding: const EdgeInsets.fromLTRB(24, AppSpacing.xl, 24, 24),
              children: [
                Center(
                  child: Container(
                    width: 104,
                    height: 104,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.surface,
                      boxShadow: AppShadows.soft(context),
                    ),
                    child: BrandLotus(
                      color: scheme.primary,
                      sideColor: t.secondary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.tr('sign_in_title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 30,
                    height: 1.15,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr('sign_in_body'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    color: t.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: AppCard.decoration(t),
                  child: Column(
                    children: [
                      const _Point(
                        icon: Icons.phone_iphone_rounded,
                        textKey: 'sign_in_point_device',
                      ),
                      Divider(height: 1, color: AppCard.dividerColor(t)),
                      const _Point(
                        icon: Icons.verified_user_outlined,
                        textKey: 'sign_in_point_no_health',
                      ),
                      Divider(height: 1, color: AppCard.dividerColor(t)),
                      const _Point(
                        icon: Icons.auto_delete_outlined,
                        textKey: 'sign_in_point_delete',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                // Apple önce ve en az Google kadar belirgin (Yönergeler 4.8).
                SignInButton.apple(
                  key: const Key('sign_in_apple'),
                  label: context.tr('account_continue_apple'),
                  onPressed: busy
                      ? null
                      : () => _signIn(context, AccountProvider.apple),
                ),
                const SizedBox(height: AppSpacing.md),
                SignInButton.google(
                  key: const Key('sign_in_google'),
                  label: context.tr('account_continue_google'),
                  onPressed: busy
                      ? null
                      : () => _signIn(context, AccountProvider.google),
                ),
                const SizedBox(height: AppSpacing.md),
                EmailSignInButton(
                  key: const Key('sign_in_email'),
                  label: context.tr('account_continue_email'),
                  onPressed: busy ? null : () => _signInWithEmail(context),
                ),
                if (busy) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const Center(child: CircularProgressIndicator()),
                ],
                const SizedBox(height: AppSpacing.lg),
                const SignInNotice(),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () =>
                          context.pushNamed(RouteNames.privacyPolicy),
                      style: TextButton.styleFrom(
                        foregroundColor: t.textMuted,
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(context.tr('privacy_policy_title')),
                    ),
                    TextButton(
                      onPressed: () =>
                          context.pushNamed(RouteNames.termsOfService),
                      style: TextButton.styleFrom(
                        foregroundColor: t.textMuted,
                        minimumSize: const Size(0, 44),
                      ),
                      child: Text(context.tr('terms_of_service_title')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.textKey});

  final IconData icon;
  final String textKey;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(
            icon: icon,
            size: 34,
            circle: true,
            background: t.secondaryTint,
            color: t.secondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.tr(textKey),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: t.text, height: 1.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
