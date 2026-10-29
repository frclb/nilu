import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../data/datasources/remote/account_auth.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/view_models/account_view_model.dart';
import '../../localization/app_localizations.dart';
import 'email_sign_in_sheet.dart';
import 'sign_in_screen.dart';

/// E-postadaki şifre yenileme bağlantısı uygulamayı açtı: yeni şifre burada
/// belirleniyor ve hesaba o şifreyle giriliyor.
///
/// Önceden bağlantı Firebase'in kendi sayfasını (`…firebaseapp.com`)
/// açıyordu; kullanıcı tanımadığı bir adreste şifre yazıyor, sonra
/// uygulamaya dönüp yeniden giriş yapıyordu. Bağlantı başka bir cihazda
/// açılırsa Nilu'nun sitesindeki sayfa aynı işi yapıyor
/// (`tool/build_site.dart`).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.code});

  /// Firebase'in tek kullanımlık kodu (`oobCode`).
  final String? code;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

enum _Durum { checking, form, invalid }

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  _Durum _durum = _Durum.checking;
  bool _started = false;
  bool _hidden = true;
  String? _email;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startWhenReady();
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  /// Bağlantı uygulamayı soğuk başlattıysa Firebase biraz sonra hazır
  /// oluyor; kod o zaman denetleniyor.
  void _startWhenReady() {
    final vm = context.read<AccountViewModel>();
    if (_started || !vm.isAvailable) return;
    _started = true;
    final kod = widget.code;
    if (kod == null || kod.isEmpty) {
      _durum = _Durum.invalid;
      return;
    }
    vm.checkPasswordResetCode(kod).then((email) {
      if (!mounted) return;
      setState(() {
        _email = email;
        _durum = email == null ? _Durum.invalid : _Durum.form;
      });
    });
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final vm = context.read<AccountViewModel>();
    final snack = AppSnack.of(context);
    final tamam = context.tr('reset_password_done');
    final sonuc = await vm.resetPassword(
      widget.code!,
      email: _email!,
      newPassword: _password.text,
    );
    if (!mounted) return;
    switch (sonuc) {
      case PasswordResetResult.done:
        snack.success(tamam);
        _leave(vm);
      case PasswordResetResult.invalidLink:
        setState(() => _durum = _Durum.invalid);
      case PasswordResetResult.weakPassword:
        setState(() => _error = 'email_error_weak_password');
      case PasswordResetResult.failed:
        setState(() => _error = 'reset_password_failed');
    }
  }

  /// Oturum varsa kaldığı yerden; yoksa giriş ekranına.
  void _leave(AccountViewModel vm) {
    if (vm.isSignedIn) {
      continueAfterSignIn(context);
    } else {
      context.goNamed(RouteNames.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    // İzlemek Firebase hazır olunca `didChangeDependencies`'i yeniden
    // çağırıyor; denetim orada başlıyor.
    final vm = context.watch<AccountViewModel>();

    final t = context.tokens;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final List<Widget> govde = switch (_durum) {
      _Durum.checking => [
        const SizedBox(height: AppSpacing.xl),
        const Center(child: CircularProgressIndicator()),
      ],
      _Durum.invalid => [
        Text(
          context.tr('reset_password_invalid'),
          key: const Key('reset_password_invalid'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: t.text,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppGradientButton(
          key: const Key('reset_password_back'),
          label: context.tr('reset_password_back'),
          onPressed: () => _leave(vm),
        ),
      ],
      _Durum.form => [
        Text(
          context.tr('reset_password_for', params: {'email': _email ?? ''}),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: t.text,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _form,
          child: AutofillGroup(
            child: TextFormField(
              key: const Key('reset_password_field'),
              controller: _password,
              enabled: !vm.busy,
              obscureText: _hidden,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: context.tr('email_password_label'),
                helperText: context.tr('email_password_hint'),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  tooltip: context.tr(
                    _hidden ? 'email_password_show' : 'email_password_hide',
                  ),
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
              ),
              validator: (v) =>
                  (v ?? '').length < EmailSignInSheet.minPasswordLength
                  ? context.tr('email_error_password_short')
                  : null,
            ),
          ),
        ),
        if (_error case final key?) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr(key),
            key: const Key('reset_password_error'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: t.danger),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppGradientButton(
          key: const Key('reset_password_submit'),
          label: context.tr('reset_password_button'),
          busy: vm.busy,
          onPressed: _submit,
        ),
      ],
    };

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        child: SafeArea(
          child: AppContentWidth(
            child: ListView(
              key: const Key('reset_password'),
              padding: const EdgeInsets.fromLTRB(24, AppSpacing.xl, 24, 24),
              children: [
                Center(
                  child: AppIconTile(
                    icon: Icons.lock_reset_rounded,
                    size: 96,
                    circle: true,
                    background: t.brandTint,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  context.tr('reset_password_title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 28,
                    height: 1.15,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...govde,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
