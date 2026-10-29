import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/remote/account_auth.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/view_models/account_view_model.dart';
import '../../localization/app_localizations.dart';

/// E-posta ve şifreyle giriş ya da yeni hesap.
///
/// Apple ve Google'ın yanında üçüncü yol. Hatalar sayfanın içinde
/// gösteriliyor; giriş olunca sayfa `true` ile kapanıyor ve sonrasına
/// çağıran karar veriyor (kurulum, geri yükleme, partner ekranı).
///
/// Şifre sıfırlama ve doğrulama e-postalarını Firebase gönderiyor; bkz.
/// [FirebaseAccountAuth].
Future<bool> showEmailSignInSheet(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const EmailSignInSheet(),
    ) ??
    false;

class EmailSignInSheet extends StatefulWidget {
  const EmailSignInSheet({super.key});

  /// Yeni şifrenin en kısa uzunluğu. Firebase'in kendi alt sınırı 6.
  static const int minPasswordLength = 8;

  /// Kaba bir biçim denetimi; asıl karar Firebase'in.
  static final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  State<EmailSignInSheet> createState() => _EmailSignInSheetState();
}

class _EmailSignInSheetState extends State<EmailSignInSheet> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _create = false;
  bool _hidden = true;

  /// Sayfanın altındaki hata ya da bilgi (metin anahtarı).
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _checkEmail(String? v) =>
      EmailSignInSheet.emailPattern.hasMatch((v ?? '').trim())
      ? null
      : context.tr('email_error_invalid_email');

  String? _checkPassword(String? v) {
    final sifre = v ?? '';
    if (sifre.isEmpty) return context.tr('email_error_password_empty');
    if (_create && sifre.length < EmailSignInSheet.minPasswordLength) {
      return context.tr('email_error_password_short');
    }
    return null;
  }

  static String _errorKey(SignInResult r) =>
      r.status == SignInStatus.unavailable
      ? 'account_unavailable'
      : switch (r.emailError) {
          EmailAuthError.invalidCredential => 'email_error_invalid_credential',
          EmailAuthError.emailInUse => 'email_error_in_use',
          EmailAuthError.weakPassword => 'email_error_weak_password',
          EmailAuthError.invalidEmail => 'email_error_invalid_email',
          EmailAuthError.tooManyRequests => 'email_error_too_many',
          EmailAuthError.network => 'email_error_network',
          null => 'account_sign_in_failed',
        };

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _notice = null;
    });
    if (!_form.currentState!.validate()) return;
    final dil = Localizations.localeOf(context).languageCode;
    final sonuc = await context.read<AccountViewModel>().signInWithEmail(
      _email.text,
      _password.text,
      create: _create,
      languageCode: dil,
    );
    if (!mounted) return;
    if (sonuc.status == SignInStatus.signedIn) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = _errorKey(sonuc));
    }
  }

  Future<void> _forgot() async {
    final adres = _email.text.trim();
    setState(() {
      _error = null;
      _notice = null;
    });
    if (!EmailSignInSheet.emailPattern.hasMatch(adres)) {
      setState(() => _error = 'email_reset_need_email');
      return;
    }
    final dil = Localizations.localeOf(context).languageCode;
    final gitti = await context.read<AccountViewModel>().sendPasswordReset(
      adres,
      languageCode: dil,
    );
    if (!mounted) return;
    setState(() {
      if (gitti) {
        _notice = 'email_reset_sent';
      } else {
        _error = 'email_reset_failed';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final busy = context.watch<AccountViewModel>().busy;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.9;

    Widget not(String key, {required bool error}) => Container(
      key: Key(error ? 'email_error' : 'email_notice'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: error ? t.danger.withAlpha(24) : t.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.mark_email_read_outlined,
            size: 18,
            color: error ? t.danger : t.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(key),
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
                color: t.text,
              ),
            ),
          ),
        ],
      ),
    );

    return Padding(
      // Klavye açılınca sayfa onun üstüne çıksın.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        key: const Key('email_sign_in_sheet'),
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.textFaint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                  child: Form(
                    key: _form,
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.tr('email_sheet_title'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SegmentedButton<bool>(
                            key: const Key('email_mode'),
                            showSelectedIcon: false,
                            segments: [
                              ButtonSegment(
                                value: false,
                                label: Text(context.tr('email_mode_sign_in')),
                              ),
                              ButtonSegment(
                                value: true,
                                label: Text(context.tr('email_mode_create')),
                              ),
                            ],
                            selected: {_create},
                            onSelectionChanged: busy
                                ? null
                                : (s) => setState(() {
                                    _create = s.first;
                                    _error = null;
                                    _notice = null;
                                  }),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            key: const Key('email_field'),
                            controller: _email,
                            enabled: !busy,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: const [
                              AutofillHints.email,
                              AutofillHints.username,
                            ],
                            decoration: InputDecoration(
                              labelText: context.tr('email_field_label'),
                              prefixIcon: const Icon(
                                Icons.mail_outline_rounded,
                              ),
                            ),
                            validator: _checkEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const Key('password_field'),
                            controller: _password,
                            enabled: !busy,
                            obscureText: _hidden,
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: [
                              _create
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: context.tr('email_password_label'),
                              helperText: _create
                                  ? context.tr('email_password_hint')
                                  : null,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: context.tr(
                                  _hidden
                                      ? 'email_password_show'
                                      : 'email_password_hide',
                                ),
                                icon: Icon(
                                  _hidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _hidden = !_hidden),
                              ),
                            ),
                            validator: _checkPassword,
                          ),
                          if (_error case final key?) ...[
                            const SizedBox(height: 14),
                            not(key, error: true),
                          ],
                          if (_notice case final key?) ...[
                            const SizedBox(height: 14),
                            not(key, error: false),
                          ],
                          const SizedBox(height: 20),
                          AppGradientButton(
                            key: const Key('email_submit'),
                            label: context.tr(
                              _create
                                  ? 'email_create_button'
                                  : 'email_sign_in_button',
                            ),
                            busy: busy,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 8),
                          if (_create)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                context.tr('email_create_note'),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  height: 1.45,
                                  color: t.textMuted,
                                ),
                              ),
                            )
                          else
                            TextButton(
                              key: const Key('email_forgot'),
                              onPressed: busy ? null : _forgot,
                              style: TextButton.styleFrom(
                                foregroundColor: t.textMuted,
                                minimumSize: const Size(0, 44),
                              ),
                              child: Text(context.tr('email_forgot')),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
