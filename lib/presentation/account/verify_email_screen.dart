import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/view_models/account_view_model.dart';
import '../../localization/app_localizations.dart';
import 'sign_in_screen.dart';

/// E-postayla açılan hesap: adres doğrulanana kadar uygulama burada.
///
/// Yönlendirme doğrulanmamış hesabı buraya getiriyor (`resolveRedirect`).
/// E-postadaki bağlantıya dokununca uygulama açılıp kodu uyguluyor
/// (`AuthActionLink`); bağlantı başka bir cihazda açıldıysa sayfa
/// doğrulamayı kendisi bitiriyor ve kullanıcı uygulamaya dönünce burası
/// hesabı yeniden okuyor. Doğrulanınca ekran kaldığı yerden devam ettiriyor.
///
/// Kod yerine bağlantı: Firebase'in ücretsiz planı e-postaya kod koyamıyor;
/// kod için sunucu ve e-posta servisi gerekirdi.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  /// Tekrar gönderme arasında beklenen süre: Firebase de sık isteği
  /// reddediyor.
  static const Duration resendCooldown = Duration(seconds: 60);

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _continued = false;
  bool _notYet = false;

  /// Tekrar gönderdikten sonra düğme bir süre kapalı.
  Timer? _cooldown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldown?.cancel();
    super.dispose();
  }

  /// E-postadan uygulamaya dönüldü: bağlantı başka yerde açılmış olabilir.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check(quiet: true);
  }

  Future<void> _check({bool quiet = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    final dogrulandi = await context
        .read<AccountViewModel>()
        .checkEmailVerified();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _notYet = !dogrulandi && !quiet;
    });
  }

  Future<void> _resend() async {
    final snack = AppSnack.of(context);
    final gonderildi = context.tr('verify_email_resent');
    final olmadi = context.tr('verify_email_resend_failed');
    final dil = Localizations.localeOf(context).languageCode;
    setState(() {
      _cooldown = Timer(VerifyEmailScreen.resendCooldown, () {
        if (mounted) setState(() => _cooldown = null);
      });
    });
    final ok = await context.read<AccountViewModel>().resendEmailVerification(
      languageCode: dil,
    );
    if (ok) {
      snack.success(gonderildi);
    } else {
      snack.error(olmadi);
    }
  }

  bool get _canResend => _cooldown == null;

  /// Doğrulandı: bir kez devam.
  void _continueOnce(AccountViewModel vm) {
    if (_continued || !vm.isSignedIn || vm.needsEmailVerification) return;
    _continued = true;
    final snack = AppSnack.of(context);
    final metin = context.tr('verify_email_done');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      snack.success(metin);
      continueAfterSignIn(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountViewModel>();
    _continueOnce(vm);

    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final email = vm.account?.email ?? '';

    return Scaffold(
      backgroundColor: t.background,
      body: AmbientBackground(
        child: SafeArea(
          child: AppContentWidth(
            child: ListView(
              key: const Key('verify_email'),
              padding: const EdgeInsets.fromLTRB(24, AppSpacing.xl, 24, 24),
              children: [
                Center(
                  child: AppIconTile(
                    icon: Icons.mark_email_unread_outlined,
                    size: 96,
                    circle: true,
                    background: t.brandTint,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.tr('verify_email_title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    height: 1.15,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.tr('verify_email_body', params: {'email': email}),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    color: t.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.tr('verify_email_spam'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    height: 1.45,
                    color: t.textMuted,
                  ),
                ),
                if (_notYet) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    key: const Key('verify_email_not_yet'),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: t.surfaceAlt,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      context.tr('verify_email_not_yet'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                        color: t.text,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                AppGradientButton(
                  key: const Key('verify_email_check'),
                  label: context.tr('verify_email_check'),
                  icon: Icons.check_rounded,
                  busy: _checking,
                  onPressed: _check,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  key: const Key('verify_email_resend'),
                  onPressed: _canResend ? _resend : null,
                  style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
                  child: Text(context.tr('verify_email_resend')),
                ),
                TextButton(
                  key: const Key('verify_email_other_account'),
                  onPressed: vm.busy ? null : vm.signOut,
                  style: TextButton.styleFrom(
                    foregroundColor: t.textMuted,
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(context.tr('verify_email_other_account')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
