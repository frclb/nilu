import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../data/datasources/remote/account_auth.dart';
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

/// Apple, Google ya da e-postayla giriş — isteğe bağlı.
///
/// Karşılama sayfalarından sonra, kurulumdan önce bir kez geliyor (bkz.
/// `resolveRedirect`); "Hesap olmadan devam et" ile geçiliyor. Giriş ya da
/// geçiş bitince kaldığı yerden devam: kurulum ya da ana ekran.
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

  /// Hesapsız devam: giriş ekranı bir daha zorla açılmıyor.
  Future<void> _skip(BuildContext context) async {
    await context.read<UserViewModel>().skipSignIn();
    if (context.mounted) continueAfterSignIn(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final busy = context.watch<AccountViewModel>().busy;

    // Tek ekran: kaydırma yok. Önce bir liste vardı; küçük telefonda
    // "Hesap olmadan devam et" ve şartlar katlamanın altında kalıyordu,
    // isteğe bağlı olduğu söylenen girişin atlanma yolu görünmüyordu.
    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        child: SafeArea(
          child: AppContentWidth(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final d = FitDensity.of(constraints.maxHeight);
                final gap = d.pick(12.0, 18.0, 24.0);
                return AppFitToScreen(
                  key: const Key('sign_in'),
                  fitKey: const Key('sign_in_fit'),
                  maxHeight: 880,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      // Geri düğmesinin satırı zaten güvenli alanda:
                      // `extendBodyBehindAppBar` üst çubuğu boşluğa ekliyor.
                      d.pick(0.0, 4.0, 8.0),
                      24,
                      8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        // En küçük telefonda logo yok: başlık ve bilgi
                        // sığsın diye süs çıkıyor, bilgi kalıyor.
                        if (d != FitDensity.compact) ...[
                          Center(child: _Mark(size: d.pick(0.0, 60.0, 84.0))),
                          SizedBox(height: d.pick(0.0, 14.0, 20.0)),
                        ],
                        Text(
                          context.tr('sign_in_title'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: d.pick(25.0, 28.0, 30.0),
                            height: 1.15,
                            color: scheme.primary,
                          ),
                        ),
                        SizedBox(height: d.pick(6.0, 10.0, 12.0)),
                        Text(
                          context.tr('sign_in_body'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 14,
                            height: 1.4,
                            color: t.textMuted,
                          ),
                        ),
                        SizedBox(height: gap),
                        const Spacer(),
                        // Güvenceler kartsız, sıkı satırlar: kart ve
                        // geniş satırlar ekranın dörtte birini alıyordu.
                        const _Point(
                          icon: Icons.phone_iphone_rounded,
                          textKey: 'sign_in_point_device',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _Point(
                          icon: Icons.verified_user_outlined,
                          textKey: 'sign_in_point_no_health',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _Point(
                          icon: Icons.auto_delete_outlined,
                          textKey: 'sign_in_point_delete',
                        ),
                        SizedBox(height: gap),
                        const Spacer(),
                        // Apple önce ve en az Google kadar belirgin
                        // (Yönergeler 4.8).
                        SignInButton.apple(
                          key: const Key('sign_in_apple'),
                          label: context.tr('account_continue_apple'),
                          onPressed: busy
                              ? null
                              : () => _signIn(context, AccountProvider.apple),
                        ),
                        const SizedBox(height: 10),
                        SignInButton.google(
                          key: const Key('sign_in_google'),
                          label: context.tr('account_continue_google'),
                          onPressed: busy
                              ? null
                              : () => _signIn(context, AccountProvider.google),
                        ),
                        const SizedBox(height: 10),
                        EmailSignInButton(
                          key: const Key('sign_in_email'),
                          label: context.tr('account_continue_email'),
                          onPressed: busy
                              ? null
                              : () => _signInWithEmail(context),
                        ),
                        const SizedBox(height: 4),
                        // Hesap isteğe bağlı (App Store 5.1.1(v)): takip
                        // hesapsız çalışıyor, kayıtlar cihazda kalıyor.
                        // Giriş sürerken düğmenin yerinde gösterge: ekran
                        // zıplamasın.
                        SizedBox(
                          height: 48,
                          child: busy
                              ? const Center(
                                  child: SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : TextButton(
                                  key: const Key('sign_in_skip'),
                                  onPressed: () => _skip(context),
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(0, 48),
                                  ),
                                  child: Text(context.tr('sign_in_skip')),
                                ),
                        ),
                        const SignInNotice(),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () =>
                                  context.pushNamed(RouteNames.privacyPolicy),
                              style: TextButton.styleFrom(
                                foregroundColor: t.textMuted,
                                minimumSize: const Size(44, 44),
                              ),
                              child: Text(context.tr('privacy_policy_title')),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.pushNamed(RouteNames.termsOfService),
                              style: TextButton.styleFrom(
                                foregroundColor: t.textMuted,
                                minimumSize: const Size(44, 44),
                              ),
                              child: Text(context.tr('terms_of_service_title')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo: marka degradesinde beyaz lotus, arkasında kendi renginde ışıma.
class _Mark extends StatelessWidget {
  const _Mark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.22),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.mark(context),
        boxShadow: [
          BoxShadow(
            color: t.markStart.withAlpha(dark ? 110 : 60),
            blurRadius: size * 0.5,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: const BrandLotus(color: AppGradients.onMark, sideOpacity: 0.8),
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
    return Row(
      children: [
        AppIconTile(
          icon: icon,
          size: 30,
          circle: true,
          background: t.secondaryTint,
          color: t.secondary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            context.tr(textKey),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13.5,
              color: t.text,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
