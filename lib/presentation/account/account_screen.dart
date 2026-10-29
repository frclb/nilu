import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../data/datasources/remote/account_auth.dart';
import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_layout.dart';
import '../../design_system/app_snack.dart';
import '../../design_system/app_theme.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/sign_in_buttons.dart';
import '../../domain/services/sync_engine.dart';
import '../../domain/view_models/account_view_model.dart';
import '../../domain/view_models/user_view_model.dart';
import '../../localization/app_localizations.dart';
import '../../localization/relative_time.dart';
import 'email_sign_in_sheet.dart';
import 'sync_consent_sheet.dart';

/// Hesap ve bulut yedeği.
///
/// Hesap isteğe bağlı: takip, kayıt ve analizler girişsiz çalışıyor. Giriş
/// kayıtları buluta koyup başka bir cihazda geri almak ve partnerle
/// eşleşmek için; giriş tek başına hiçbir sağlık verisi göndermiyor —
/// eşitleme ayrı bir açık rızayla açılıyor (bkz. [showSyncConsentSheet]).
///
/// [restore]: karşılama ekranından, kurulumdan önce açıldı. Giriş ve rızadan
/// sonra bulutta kayıt varsa kurulum atlanıp ana ekrana geçiliyor; yoksa
/// kurulum kaldığı yerden sürüyor.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key, this.restore = false});

  final bool restore;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountViewModel>();
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.background,
      // Başlık sayfanın içinde, serif ve büyük; çubukta yalnızca geri.
      // Gövde çubuğun arkasına uzanıyor ki üstteki ışıma çubukta kesilmesin.
      appBar: AppBar(backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: AmbientBackground(
        child: SafeArea(
          bottom: false,
          child: AppContentWidth(
            child: ListView(
              // Altta ana ekran çubuğunun payı: liste sonuna kaydırılınca
              // "Hesabı sil" onun altında kalmasın.
              padding: EdgeInsets.fromLTRB(
                20,
                AppSpacing.sm,
                20,
                AppSpacing.xxl + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                // Akışlar bu ekranın bağlamıyla yürüyor, bölümünkiyle değil:
                // giriş ya da çıkış bölümü değiştirince eski bölüm ağaçtan
                // kalkıyor ve kendi bağlamıyla süren akış (rıza, geri
                // yükleme, "hesabın silindi" bildirimi) yarıda kalıyordu.
                if (vm.isSignedIn)
                  _SignedIn(host: context, restore: restore)
                else
                  _SignedOut(host: context, restore: restore),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ortak işler ───

/// Rıza alıp eşitlemeyi açar. Geri yüklemede sonuca göre ilerler.
Future<void> _enableSync(BuildContext context, {required bool restore}) async {
  final vm = context.read<AccountViewModel>();
  if (!await showSyncConsentSheet(context)) return;
  if (!context.mounted) return;
  final sonuc = await vm.enableSync();
  if (!context.mounted) return;
  if (restore) {
    await _finishRestore(context, sonuc);
  } else if (vm.status == SyncStatus.failed) {
    AppSnack.error(context, context.tr('account_sync_failed'));
  }
}

/// Geri yükleme bitti: kayıt geldiyse kurulum atlanıyor.
Future<void> _finishRestore(BuildContext context, SyncOutcome? sonuc) async {
  final vm = context.read<AccountViewModel>();
  final user = context.read<UserViewModel>();
  final router = GoRouter.of(context);
  final done = context.tr('account_restore_done');
  final empty = context.tr('account_restore_empty');
  final failed = context.tr('account_restore_failed');

  if (sonuc == null || vm.status == SyncStatus.failed) {
    AppSnack.error(context, failed);
    return;
  }
  if (await vm.hasLocalData()) {
    await user.resetPartnerState();
    await user.markOnboardingComplete();
    if (!context.mounted) return;
    AppSnack.success(context, done);
    router.goNamed(RouteNames.home);
  } else {
    if (!context.mounted) return;
    AppSnack.show(context, empty);
    router.pushReplacementNamed(RouteNames.onboardingGoal);
  }
}

/// Sayfanın serif başlığı.
class _Title extends StatelessWidget {
  const _Title(this.text, {this.center = false});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: theme.textTheme.headlineMedium?.copyWith(
          fontSize: 30,
          height: 1.15,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

// ─── Giriş yapılmamış ───

class _SignedOut extends StatelessWidget {
  const _SignedOut({required this.host, required this.restore});

  /// Ekranın bağlamı: bölüm değişse de ağaçta kalıyor.
  final BuildContext host;
  final bool restore;

  Future<void> _signIn(BuildContext context, AccountProvider provider) async {
    final vm = context.read<AccountViewModel>();
    final sonuc = await vm.signIn(provider);
    if (!context.mounted) return;

    switch (sonuc.status) {
      case SignInStatus.signedIn:
        await _signedIn(context, vm);
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
    final vm = context.read<AccountViewModel>();
    if (await showEmailSignInSheet(context) && context.mounted) {
      await _signedIn(context, vm);
    }
  }

  Future<void> _signedIn(BuildContext context, AccountViewModel vm) async {
    if (!restore) return;
    // Geri yüklemede bir sonraki adım zaten belli: rıza ve indirme.
    if (vm.syncEnabled) {
      final s = await vm.syncNow();
      if (context.mounted) await _finishRestore(context, s);
    } else {
      await _enableSync(context, restore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountViewModel>();
    final t = context.tokens;
    final theme = Theme.of(context);
    final busy = vm.busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kahraman: degrade kutuda bulut, altında serif başlık ve açıklama.
        const SizedBox(height: AppSpacing.sm),
        Center(child: _CloudMark(restore: restore)),
        const SizedBox(height: AppSpacing.xl - 4),
        _Title(
          context.tr(restore ? 'account_restore_title' : 'account_title'),
          center: true,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.tr(restore ? 'account_restore_intro' : 'account_intro'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            color: t.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl + 4),

        // Giriş ve eşitleme hakkında üç gerçek: rıza ayrı, kapatınca silinir,
        // uçtan uca şifreli değil.
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm + 2),
          child: AppSectionLabel(
            context.tr('profile_privacy_security'),
            color: t.secondary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: AppCard.decoration(t),
          child: const Column(
            children: [
              _Point(
                icon: Icons.verified_user_outlined,
                textKey: 'account_point_consent',
              ),
              _PointDivider(),
              _Point(
                icon: Icons.auto_delete_outlined,
                textKey: 'account_point_delete',
              ),
              _PointDivider(),
              _Point(
                icon: Icons.lock_outline,
                textKey: 'account_point_encryption',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl + 4),
        if (!vm.isAvailable)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: t.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_off_outlined, size: 20, color: t.textMuted),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    context.tr('account_unavailable'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: t.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else ...[
          SignInButton.apple(
            key: const Key('account_apple'),
            label: context.tr('account_continue_apple'),
            onPressed: busy ? null : () => _signIn(host, AccountProvider.apple),
          ),
          const SizedBox(height: AppSpacing.md),
          SignInButton.google(
            key: const Key('account_google'),
            label: context.tr('account_continue_google'),
            onPressed: busy
                ? null
                : () => _signIn(host, AccountProvider.google),
          ),
          const SizedBox(height: AppSpacing.md),
          EmailSignInButton(
            key: const Key('account_email'),
            label: context.tr('account_continue_email'),
            onPressed: busy ? null : () => _signInWithEmail(host),
          ),
          if (busy) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ],
    );
  }
}

/// Degrade kutuda bulut ve köşesinde eşitleme rozeti.
class _CloudMark extends StatelessWidget {
  const _CloudMark({required this.restore});

  final bool restore;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          Positioned(
            left: 4,
            top: 4,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: AppGradients.mark(context),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.floating(context),
              ),
              child: Icon(
                restore ? Icons.cloud_download_outlined : Icons.cloud_outlined,
                size: 40,
                color: scheme.onPrimary,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: t.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: t.background, width: 2.5),
              ),
              child: Icon(Icons.sync, size: 16, color: scheme.onSecondary),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _PointDivider extends StatelessWidget {
  const _PointDivider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: AppCard.dividerColor(context.tokens));
}

// ─── Giriş yapılmış ───

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.host, required this.restore});

  /// Ekranın bağlamı: bölüm değişse de ağaçta kalıyor.
  final BuildContext host;
  final bool restore;

  Future<void> _toggle(BuildContext context, bool on) async {
    if (on) return _enableSync(context, restore: restore);

    final onay = await _confirm(
      context,
      title: 'account_sync_off_title',
      body: 'account_sync_off_body',
      action: 'account_sync_off_action',
    );
    if (!onay || !context.mounted) return;
    final ok = await context.read<AccountViewModel>().disableSync();
    if (!context.mounted) return;
    ok
        ? AppSnack.success(context, context.tr('account_sync_off_done'))
        : AppSnack.error(context, context.tr('account_sync_off_failed'));
  }

  Future<void> _syncNow(BuildContext context) async {
    final vm = context.read<AccountViewModel>();
    final sonuc = await vm.syncNow();
    if (!context.mounted) return;
    if (restore) return _finishRestore(context, sonuc);
    if (vm.status == SyncStatus.failed) {
      AppSnack.error(context, context.tr('account_sync_failed'));
    }
  }

  Future<void> _signOut(BuildContext context) async {
    final hasPartner = context.read<UserViewModel>().hasPartner;
    final onay = await _confirm(
      context,
      title: 'account_sign_out_title',
      body: 'account_sign_out_body',
      extra: hasPartner ? 'account_sign_out_partner' : null,
      action: 'account_sign_out',
      destructive: false,
    );
    if (!onay || !context.mounted) return;
    await context.read<AccountViewModel>().signOut();
  }

  Future<void> _delete(BuildContext context) async {
    final onay = await _confirm(
      context,
      title: 'account_delete_title',
      body: 'account_delete_body',
      action: 'account_delete',
    );
    if (!onay || !context.mounted) return;
    final vm = context.read<AccountViewModel>();
    // E-posta hesabında kimlik şifreyle doğrulanıyor; Apple ve Google kendi
    // sayfalarını açıyor.
    String? sifre;
    if (vm.account?.provider == AccountProvider.email) {
      sifre = await _askPassword(context);
      if (sifre == null || !context.mounted) return;
    }
    final sonuc = await vm.deleteAccount(password: sifre);
    if (!context.mounted) return;
    switch (sonuc) {
      case AccountDeleteResult.deleted:
        AppSnack.success(context, context.tr('account_delete_done'));
      case AccountDeleteResult.cancelled:
        AppSnack.show(context, context.tr('account_delete_cancelled'));
      case AccountDeleteResult.failed:
        AppSnack.error(context, context.tr('account_delete_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AccountViewModel>();
    final account = vm.account!;
    final t = context.tokens;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: t.textMuted,
      height: 1.4,
    );

    final saglayici = context.tr(switch (account.provider) {
      AccountProvider.apple => 'account_provider_apple',
      AccountProvider.google => 'account_provider_google',
      AccountProvider.email => 'account_provider_email',
    });

    final String durum;
    if (!vm.syncEnabled) {
      durum = context.tr('account_sync_off');
    } else if (vm.status == SyncStatus.syncing) {
      durum = context.tr('account_sync_syncing');
    } else if (vm.status == SyncStatus.failed) {
      durum = context.tr('account_sync_failed');
    } else if (vm.lastSyncAt case final at?) {
      durum = context.tr(
        'account_sync_last',
        params: {'time': context.relativeTime(DateTime.now().difference(at))},
      );
    } else {
      durum = context.tr('account_sync_never');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(context.tr(restore ? 'account_restore_title' : 'account_title')),
        const SizedBox(height: AppSpacing.xl),

        if (vm.stoppedRemotely) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: t.brandTint,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: t.secondary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        context.tr('account_stopped_remotely'),
                        style: muted,
                      ),
                    ),
                  ],
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: vm.acknowledgeStoppedRemotely,
                    child: Text(context.tr('ok')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Kim olarak giriş yapıldı.
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg + 4),
          decoration: AppCard.decoration(t),
          child: Row(
            children: [
              // Sağlayıcının işareti: koyu daire içinde açık simge.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: t.text,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  switch (account.provider) {
                    AccountProvider.apple => Icons.apple,
                    AccountProvider.email => Icons.mail_outline_rounded,
                    AccountProvider.google => Icons.account_circle_outlined,
                  },
                  size: 26,
                  color: t.surface,
                ),
              ),
              const SizedBox(width: AppSpacing.md + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.email ?? account.displayName ?? saglayici,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (account.email != null || account.displayName != null)
                      Text(saglayici, style: muted),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Eşitleme.
        Container(
          decoration: AppCard.decoration(t),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                key: const Key('account_sync_switch'),
                contentPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                secondary: AppIconTile(
                  icon: Icons.cloud_sync_outlined,
                  size: 40,
                  background: t.brandTint,
                ),
                title: Text(
                  context.tr('account_sync_title'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  vm.syncEnabled ? context.tr('account_sync_on') : durum,
                ),
                value: vm.syncEnabled,
                onChanged: vm.busy ? null : (on) => _toggle(host, on),
              ),
              if (vm.syncEnabled) ...[
                Divider(height: 1, color: AppCard.dividerColor(t)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 18, color: t.secondary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(durum, style: muted)),
                      const SizedBox(width: AppSpacing.sm),
                      if (vm.status == SyncStatus.syncing)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        TextButton.icon(
                          key: const Key('account_sync_now'),
                          onPressed: vm.busy ? null : () => _syncNow(host),
                          style: TextButton.styleFrom(
                            backgroundColor: t.brandTint,
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                            ),
                          ),
                          icon: const Icon(Icons.sync, size: 18),
                          label: Text(
                            context.tr(
                              restore
                                  ? 'account_restore_fetch'
                                  : 'account_sync_now',
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              // Uçtan uca şifreli **değil**: kart bunu açıkça söylüyor.
              Container(
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: t.surfaceAlt,
                  borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, size: 18, color: t.textMuted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        context.tr('account_point_encryption'),
                        style: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Rıza verildiyse kapsamı burada da duruyor: neyin, nereye
        // gittiği ve nasıl geri çekileceği onay anında okunup unutulmasın.
        if (vm.syncEnabled) ...[
          const SizedBox(height: AppSpacing.lg),
          const _ConsentScope(),
        ],

        const SizedBox(height: AppSpacing.xxl),

        OutlinedButton.icon(
          key: const Key('account_sign_out'),
          onPressed: vm.busy ? null : () => _signOut(host),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          icon: const Icon(Icons.logout, size: 20),
          label: Text(context.tr('account_sign_out')),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          key: const Key('account_delete'),
          onPressed: vm.busy ? null : () => _delete(host),
          style: TextButton.styleFrom(
            foregroundColor: t.danger,
            minimumSize: const Size.fromHeight(48),
          ),
          icon: const Icon(Icons.delete_forever_outlined, size: 20),
          label: Text(context.tr('account_delete')),
        ),
        if (vm.busy) ...[
          const SizedBox(height: AppSpacing.lg),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

/// Verilen rızanın kapsamı: rıza sayfasındaki üç açıklamanın aynısı ve
/// politikaya bağlantı.
class _ConsentScope extends StatelessWidget {
  const _ConsentScope();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    Widget madde(IconData icon, String key) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconTile(icon: icon, size: 32, background: t.surfaceAlt),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                context.tr(key),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: t.text,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg + 4,
        AppSpacing.lg + 4,
        AppSpacing.lg + 4,
        AppSpacing.sm,
      ),
      decoration: AppCard.decoration(t),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 20, color: t.secondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.tr('sync_consent_title'),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          madde(Icons.inventory_2_outlined, 'sync_consent_what'),
          madde(Icons.public, 'sync_consent_where'),
          madde(Icons.undo, 'sync_consent_withdraw'),
          TextButton(
            onPressed: () => context.pushNamed(RouteNames.privacyPolicy),
            style: TextButton.styleFrom(
              foregroundColor: t.secondary,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 44),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(context.tr('sync_consent_policy'))),
                const Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hesap silmeden önce e-posta hesabının şifresi. Vazgeçilirse `null`.
Future<String?> _askPassword(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _PasswordDialog(),
);

/// Denetleyici kutunun kendi durumunda: kutu kapanırken (animasyon
/// sürerken) hâlâ kullanılıyor, dışarıda atılırsa hata veriyordu.
class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _alan = TextEditingController();

  @override
  void dispose() {
    _alan.dispose();
    super.dispose();
  }

  void _gonder() {
    if (_alan.text.isNotEmpty) Navigator.of(context).pop(_alan.text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('account_delete_password_title')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('account_delete_password_body')),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('account_delete_password'),
          controller: _alan,
          autofocus: true,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _gonder(),
          decoration: InputDecoration(
            labelText: context.tr('email_password_label'),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.tr('cancel')),
      ),
      FilledButton(
        onPressed: _gonder,
        style: AppTheme.dialogAction().copyWith(
          backgroundColor: WidgetStatePropertyAll(context.tokens.danger),
          foregroundColor: WidgetStatePropertyAll(
            Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        child: Text(context.tr('account_delete')),
      ),
    ],
  );
}

/// Onay kutusu. Onaylandıysa `true`.
Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  String? extra,
  bool destructive = true,
}) async {
  final sonuc = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(context.tr(title)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(body)),
          if (extra != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(context.tr(extra)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: destructive
              ? AppTheme.dialogAction().copyWith(
                  backgroundColor: WidgetStatePropertyAll(
                    context.tokens.danger,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : AppTheme.dialogAction(),
          child: Text(context.tr(action)),
        ),
      ],
    ),
  );
  return sonuc ?? false;
}
