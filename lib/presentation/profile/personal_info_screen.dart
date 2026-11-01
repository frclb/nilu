import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../data/datasources/remote/account_auth.dart';
import '../../data/repositories/profile_repository.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/content_illustration.dart';
import '../../domain/view_models/account_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/date_names.dart';
import 'widgets/settings_surface.dart';

/// Kişisel bilgiler: ad, e-posta ve doğum tarihi.
///
/// Önce üçü de serbest metin alanıydı ve istenildiği kadar
/// değiştirilebiliyordu; hesapta bir ad, uygulamada başka bir ad durabiliyordu.
/// Artık ad ve e-posta giriş yönteminden (Apple, Google, e-posta) geliyor ve
/// burada yalnızca gösteriliyor (bkz. `AccountViewModel._applyIdentity`).
/// Hesapsız kullanımda ad yok; ekran girişe davet ediyor.
///
/// Doğum tarihini hiçbir sağlayıcı vermiyor: bir kez giriliyor ve sonra
/// kilitleniyor (hekime danışma zamanı ona göre hesaplanıyor).
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  static const ProfileRepository _repository = ProfileRepository();

  DateTime? _savedBirthDate;
  DateTime? _pickedBirthDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final birthDate = await _repository.getBirthDate();
    if (!mounted) return;
    setState(() {
      _savedBirthDate = birthDate;
      _isLoading = false;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickedBirthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _pickedBirthDate = picked);
  }

  /// Doğum tarihi geri alınamaz biçimde kaydediliyor: önce soruluyor.
  Future<void> _saveBirthDate() async {
    final date = _pickedBirthDate;
    if (date == null) return;
    final snack = AppSnack.of(context);
    final saved = context.tr('personal_info_saved');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('personal_info_birthdate_confirm_title')),
        content: Text(
          ctx.tr(
            'personal_info_birthdate_confirm_body',
            params: {'date': ctx.dayMonthYear(date)},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            style: AppTheme.dialogAction(),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('save')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _repository.save(birthDate: date);
    if (!mounted) return;
    setState(() => _savedBirthDate = date);
    snack.success(saved);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final account = context.watch<AccountViewModel>().account;
    final name = account?.displayName?.trim() ?? '';

    return Scaffold(
      appBar: SettingsAppBar(
        title: context.tr('personal_info_title'),
        onBack: () => context.pop(),
      ),
      body: AmbientBackground(
        child: AppContentWidth(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    ExcludeSemantics(
                      child: Center(child: InitialAvatar(name: name, size: 88)),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      name.isNotEmpty
                          ? name
                          : context.tr('personal_info_guest_title'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.3,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (account != null) ...[
                      if (name.isEmpty) ...[
                        const _AddNameCard(),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      SettingsCard(
                        child: Column(
                          children: [
                            _InfoRow(
                              key: const Key('personal_info_name'),
                              label: context.tr('personal_info_name'),
                              value: name,
                              icon: Icons.badge_outlined,
                            ),
                            Divider(height: 1, color: AppCard.dividerColor(t)),
                            _InfoRow(
                              key: const Key('personal_info_email'),
                              label: context.tr('personal_info_email'),
                              value: account.email ?? '',
                              icon: Icons.alternate_email,
                            ),
                            Divider(height: 1, color: AppCard.dividerColor(t)),
                            _InfoRow(
                              label: context.tr('personal_info_method'),
                              value: context.tr(switch (account.provider) {
                                AccountProvider.apple =>
                                  'account_provider_apple',
                                AccountProvider.google =>
                                  'account_provider_google',
                                AccountProvider.email =>
                                  'account_provider_email',
                              }),
                              icon: Icons.verified_user_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SettingsNote(
                        icon: Icons.lock_outline_rounded,
                        text: context.tr('personal_info_identity_note'),
                      ),
                    ] else
                      _GuestCard(
                        onSignIn: () => context.pushNamed(RouteNames.account),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    SettingsCard(
                      child: switch (_savedBirthDate) {
                        final saved? => _InfoRow(
                          key: const Key('personal_info_birthdate'),
                          label: context.tr('personal_info_birthdate'),
                          value: context.dayMonthYear(saved),
                          icon: Icons.cake_outlined,
                        ),
                        null => _BirthDatePicker(
                          value: _pickedBirthDate,
                          onPick: _pickBirthDate,
                        ),
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SettingsNote(
                      icon: Icons.event_available_outlined,
                      text: context.tr('personal_info_birthdate_locked'),
                    ),
                    if (_savedBirthDate == null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      AppGradientButton(
                        key: const Key('personal_info_save_birthdate'),
                        label: context.tr('save'),
                        icon: Icons.done_all_rounded,
                        onPressed: _pickedBirthDate == null
                            ? null
                            : _saveBirthDate,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Değiştirilemeyen bir bilgi: etiket, değer ve kilit.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          AppIconTile(
            icon: icon,
            size: 36,
            circle: true,
            background: t.secondaryTint,
            color: t.secondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontSize: 12.5,
                    color: t.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    color: t.text,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_outline_rounded, size: 18, color: t.textFaint),
        ],
      ),
    );
  }
}

/// Doğum tarihi henüz girilmedi: seçme alanı.
class _BirthDatePicker extends StatelessWidget {
  const _BirthDatePicker({required this.value, required this.onPick});

  final DateTime? value;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final picked = value;
    return InkWell(
      key: const Key('personal_info_pick_birthdate'),
      onTap: onPick,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            AppIconTile(
              icon: Icons.cake_outlined,
              size: 36,
              circle: true,
              background: t.secondaryTint,
              color: t.secondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('personal_info_birthdate'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 12.5,
                      color: t.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    picked == null
                        ? context.tr('personal_info_birthdate_hint')
                        : context.dayMonthYear(picked),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      color: picked == null ? t.textFaint : t.text,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 20, color: t.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Hesabında adı olmayan kullanıcı adını bir kez ekliyor; ad hesaba
/// yazılıyor (bkz. `AccountViewModel.addMissingName`).
class _AddNameCard extends StatefulWidget {
  const _AddNameCard();

  @override
  State<_AddNameCard> createState() => _AddNameCardState();
}

class _AddNameCardState extends State<_AddNameCard> {
  final _controller = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    final vm = context.read<AccountViewModel>();
    final snack = AppSnack.of(context);
    final saved = context.tr('personal_info_saved');
    final failed = context.tr('account_sign_in_failed');
    final ad = _controller.text.trim();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.tr('personal_info_add_name_confirm_title')),
        content: Text(
          ctx.tr('personal_info_add_name_confirm_body', params: {'name': ad}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.tr('cancel')),
          ),
          FilledButton(
            style: AppTheme.dialogAction(),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.tr('save')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    (await vm.addMissingName(ad)) ? snack.success(saved) : snack.error(failed);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final busy = context.watch<AccountViewModel>().busy;
    return SettingsCard(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('personal_info_add_name_body'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14.5,
                height: 1.45,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('personal_info_add_name_field'),
              controller: _controller,
              enabled: !busy,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(
                labelText: context.tr('email_name_label'),
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => (v ?? '').trim().length < 2
                  ? context.tr('email_error_name_empty')
                  : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const Key('personal_info_add_name_save'),
              onPressed: busy ? null : _save,
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hesapsız kullanım: ad ve e-posta yok, girişe davet.
class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SettingsCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('personal_info_guest_body'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 14.5,
              height: 1.45,
              color: t.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            key: const Key('personal_info_sign_in'),
            onPressed: onSignIn,
            icon: const Icon(Icons.login_rounded, size: 18),
            label: Text(context.tr('personal_info_sign_in')),
          ),
        ],
      ),
    );
  }
}
