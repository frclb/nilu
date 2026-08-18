import 'package:flutter/material.dart';
import '../../domain/services/app_lock_service.dart';
import '../../localization/app_localizations.dart';

/// Uygulama kilidini uygulayan kapı.
///
/// Kilit açık olduğunda içeriği **çizmeden** örter: doğrulama beklenirken
/// ekran görüntüsü alıcıda ya da uygulama değiştiricide sağlık verisi
/// görünmesin.
///
/// Yeniden doğrulama arka plandan dönüşte istenir; ama her dönüşte değil.
/// QR taramak için kameraya geçmek, bir bildirime bakmak ya da fotoğraf
/// seçmek de uygulamayı arka plana alıyor — her seferinde kilit ekranı
/// çıksaydı özellik kullanılamaz olurdu (bkz. [AppLockService.graceperiod]).
class AppLockGate extends StatefulWidget {
  final Widget child;
  final AppLockService service;

  AppLockGate({super.key, required this.child, AppLockService? service})
    : service = service ?? AppLockService();

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  /// Kilit durumu bilinene kadar içerik örtülü kalır. Varsayılan `true`:
  /// bilinmeyen durumda açık bırakmak, kilidin hiç olmaması demekti.
  bool _locked = true;
  bool _authenticating = false;
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluateOnStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _evaluateOnStart() async {
    final enabled = await widget.service.isEnabled();
    if (!mounted) return;

    if (!enabled) {
      setState(() => _locked = false);
      return;
    }
    await _unlock();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundedAt = DateTime.now();
      case AppLifecycleState.resumed:
        _evaluateOnResume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _evaluateOnResume() async {
    if (_locked || _authenticating) return;

    final since = _backgroundedAt;
    if (since == null) return;
    if (DateTime.now().difference(since) < AppLockService.graceperiod) return;

    final enabled = await widget.service.isEnabled();
    if (!mounted || !enabled) return;

    setState(() => _locked = true);
    await _unlock();
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);

    final ok = await widget.service.authenticate(
      reason: mounted
          ? context.tr('lock_reason')
          : 'Unlock to view your health data',
    );

    if (!mounted) return;
    setState(() {
      _authenticating = false;
      if (ok) {
        _locked = false;
        _backgroundedAt = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          // Örtü içeriği tamamen kapatır; şeffaflık yok.
          Positioned.fill(
            child: _LockScreen(busy: _authenticating, onUnlock: _unlock),
          ),
      ],
    );
  }
}

class _LockScreen extends StatelessWidget {
  final bool busy;
  final VoidCallback onUnlock;

  const _LockScreen({required this.busy, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  context.tr('lock_title'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('lock_subtitle'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: busy ? null : onUnlock,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open),
                    label: Text(context.tr('lock_unlock')),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
