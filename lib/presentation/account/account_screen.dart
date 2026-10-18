import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/route_names.dart';
import '../../data/datasources/remote/account_auth.dart';
import '../../design_system/app_card.dart';
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
import 'sync_consent_sheet.dart';

/// Hesap ve bulut yedeği.
///
/// Hesap isteğe bağlı: uygulamanın her özelliği girişsiz çalışıyor. Giriş
/// yalnızca kayıtları buluta koyup başka bir cihazda geri almak için ve
/// giriş tek başına hiçbir sağlık verisi göndermiyor — eşitleme ayrı bir
/// açık rızayla açılıyor (bkz. [showSyncConsentSheet]).
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(restore ? 'account_restore_title' : 'account_title'),
        ),
      ),
      body: AppContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            // Akışlar bu ekranın bağlamıyla yürüyor, bölümünkiyle değil:
            // giriş ya da çıkış bölümü değiştirince eski bölüm ağaçtan
            // kalkıyor ve kendi bağlamıyla süren akış (rıza, geri yükleme,
            // "hesabın silindi" bildirimi) yarıda kalıyordu.
            if (vm.isSignedIn)
              _SignedIn(host: context, restore: restore)
            else
              _SignedOut(host: context, restore: restore),
          ],
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
    AppSnack.show(context, context.tr('account_sync_failed'));
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
    AppSnack.show(context, failed);
    return;
  }
  if (await vm.hasLocalData()) {
    await user.resetPartnerState();
    await user.markOnboardingComplete();
    if (!context.mounted) return;
    AppSnack.show(context, done);
    router.goNamed(RouteNames.home);
  } else {
    if (!context.mounted) return;
    AppSnack.show(context, empty);
    router.pushReplacementNamed(RouteNames.onboardingGoal);
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
    final hadPartner = context.read<UserViewModel>().hasPartner;
    final sonuc = await vm.signIn(provider);
    if (!context.mounted) return;

    switch (sonuc.status) {
      case SignInStatus.signedIn:
        if (sonuc.switchedIdentity && hadPartner) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              content: Text(context.tr('account_switched_partner')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.tr('ok')),
                ),
              ],
            ),
          );
          if (!context.mounted) return;
        }
        if (!restore) return;
        // Geri yüklemede bir sonraki adım zaten belli: rıza ve indirme.
        if (vm.syncEnabled) {
          final s = await vm.syncNow();
          if (context.mounted) await _finishRestore(context, s);
        } else {
          await _enableSync(context, restore: true);
        }
      case SignInStatus.cancelled:
        break;
      case SignInStatus.failed:
        AppSnack.show(context, context.tr('account_sign_in_failed'));
      case SignInStatus.unavailable:
        AppSnack.show(context, context.tr('account_unavailable'));
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
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: t.brandTint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              Icons.cloud_outlined,
              size: 34,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr(restore ? 'account_restore_intro' : 'account_intro'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: t.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _Point(
          icon: Icons.verified_user_outlined,
          textKey: 'account_point_consent',
        ),
        const _Point(
          icon: Icons.delete_outline,
          textKey: 'account_point_delete',
        ),
        const _Point(
          icon: Icons.lock_outline,
          textKey: 'account_point_encryption',
        ),
        const SizedBox(height: AppSpacing.xl),
        if (!vm.isAvailable)
          Text(
            context.tr('account_unavailable'),
            style: theme.textTheme.bodyMedium?.copyWith(color: t.textMuted),
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
          if (busy) ...[
            const SizedBox(height: AppSpacing.lg),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ],
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
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              context.tr(textKey),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: t.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
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
    AppSnack.show(
      context,
      context.tr(ok ? 'account_sync_off_done' : 'account_sync_off_failed'),
    );
  }

  Future<void> _syncNow(BuildContext context) async {
    final vm = context.read<AccountViewModel>();
    final sonuc = await vm.syncNow();
    if (!context.mounted) return;
    if (restore) return _finishRestore(context, sonuc);
    if (vm.status == SyncStatus.failed) {
      AppSnack.show(context, context.tr('account_sync_failed'));
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
    final sonuc = await context.read<AccountViewModel>().deleteAccount();
    if (!context.mounted) return;
    AppSnack.show(
      context,
      context.tr(switch (sonuc) {
        AccountDeleteResult.deleted => 'account_delete_done',
        AccountDeleteResult.cancelled => 'account_delete_cancelled',
        AccountDeleteResult.failed => 'account_delete_failed',
      }),
    );
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
                Text(context.tr('account_stopped_remotely'), style: muted),
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
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppCard.decoration(t),
          child: Row(
            children: [
              Icon(
                account.provider == AccountProvider.apple
                    ? Icons.apple
                    : Icons.account_circle_outlined,
                size: 28,
                color: t.text,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.email ?? account.displayName ?? saglayici,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
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
        const SizedBox(height: AppSpacing.xl),

        // Eşitleme.
        Container(
          decoration: AppCard.decoration(t),
          child: Column(
            children: [
              SwitchListTile(
                key: const Key('account_sync_switch'),
                title: Text(context.tr('account_sync_title')),
                subtitle: Text(
                  vm.syncEnabled ? context.tr('account_sync_on') : durum,
                ),
                value: vm.syncEnabled,
                onChanged: vm.busy ? null : (on) => _toggle(host, on),
              ),
              if (vm.syncEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  title: Text(durum, style: muted),
                  trailing: vm.status == SyncStatus.syncing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          key: const Key('account_sync_now'),
                          onPressed: vm.busy ? null : () => _syncNow(host),
                          child: Text(
                            context.tr(
                              restore
                                  ? 'account_restore_fetch'
                                  : 'account_sync_now',
                            ),
                          ),
                        ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text(context.tr('account_point_encryption'), style: muted),
        ),
        const SizedBox(height: AppSpacing.xxl),

        OutlinedButton(
          key: const Key('account_sign_out'),
          onPressed: vm.busy ? null : () => _signOut(host),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(context.tr('account_sign_out')),
        ),
        const SizedBox(height: AppSpacing.md),
        TextButton(
          key: const Key('account_delete'),
          onPressed: vm.busy ? null : () => _delete(host),
          style: TextButton.styleFrom(
            foregroundColor: t.danger,
            minimumSize: const Size(0, 48),
          ),
          child: Text(context.tr('account_delete')),
        ),
        if (vm.busy) ...[
          const SizedBox(height: AppSpacing.lg),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
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
