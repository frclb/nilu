import 'package:flutter/material.dart';
import '../../core/app_info.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/brand_lotus.dart';
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

  /// Şimdiki zaman. Tolerans süresi zamana bağlı olduğu için testte
  /// ileri sarılabilmesi gerekiyor; gerçek saatle 30 saniyelik senaryo
  /// widget testinde hiç oluşmaz ve test boşuna geçer.
  final DateTime Function() clock;

  AppLockGate({
    super.key,
    required this.child,
    AppLockService? service,
    DateTime Function()? clock,
  }) : service = service ?? AppLockService(),
       clock = clock ?? DateTime.now;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  /// Kilit durumu bilinene kadar içerik örtülü kalır. Varsayılan `true`:
  /// bilinmeyen durumda açık bırakmak, kilidin hiç olmaması demekti.
  bool _locked = true;

  /// Ayar okunana kadar null. Örtü var ama kilit ekranı **yok**: kilidi hiç
  /// açmamış kullanıcıya her açılışta "Uygulama kilitli" yazısı yanıp
  /// sönüyordu.
  bool? _lockEnabled;

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

    setState(() => _lockEnabled = enabled);

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
        // Sistem kimlik doğrulama istemi de uygulamayı örtüyor. Bunu arka
        // plana çıkma saymak iki yerde ikinci bir istem doğuruyordu:
        // kapının kendi isteminde ve gizlilik ekranındaki anahtarda.
        if (widget.service.isSystemPromptActive) break;
        _backgroundedAt = widget.clock();
      case AppLifecycleState.resumed:
        _evaluateOnResume();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _evaluateOnResume() async {
    final since = _backgroundedAt;

    // Damga her dönüşte tüketilir. Bırakılsaydı: tolerans içinde dönülen
    // eski bir damga yerinde kalır, kullanıcı bir süre uygulamayı kullanır
    // ve ardından yalnızca kısa bir `inactive`'den döndüğünde (Denetim
    // Merkezi, paylaşım sayfası, izin kutusu) eski damgayla karşılaştırılıp
    // kilit tetiklenirdi.
    _backgroundedAt = null;

    if (_locked || _authenticating) return;
    if (since == null) return;
    if (widget.clock().difference(since) < AppLockService.graceperiod) return;

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
            child: _lockEnabled == null
                ? const _Curtain()
                : _LockScreen(busy: _authenticating, onUnlock: _unlock),
          ),
      ],
    );
  }
}

/// Ayar okunurken içeriği örten düz zemin.
///
/// Kilit ekranı değil: kilidi kapalı olan kullanıcı hiçbir zaman "Uygulama
/// kilitli" yazısını görmemeli.
class _Curtain extends StatelessWidget {
  const _Curtain();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: const SizedBox.expand(),
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
    final t = context.tokens;

    return Material(
      color: t.background,
      child: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            // Kaydırılabilir ama sığdığında ortada: büyük yazıda ve kısa
            // ekranda düğme ekran dışına itilmesin.
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 24),
                        const _LockMedallion(),
                        const SizedBox(height: 28),
                        Text(
                          context.tr('lock_title'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 32,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.tr('lock_subtitle'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 15,
                            height: 1.5,
                            color: t.textMuted,
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Gerçekte olan: kayıtlar cihazda şifreli. Tasarımdaki
                        // "uçtan uca şifreli" alınmadı — bulut kopyası değil.
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: t.surfaceAlt,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: t.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  context.tr('onboarding_success_privacy'),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: t.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 36),
                        AppGradientButton(
                          label: context.tr('lock_unlock'),
                          icon: Icons.lock_open_rounded,
                          onPressed: busy ? null : onUnlock,
                          busy: busy,
                          radius: AppRadius.pill,
                        ),
                        const SizedBox(height: 28),
                        // Sessiz marka imzası.
                        ExcludeSemantics(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 18,
                                child: BrandLotus(color: t.secondary),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppInfo.displayName,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: t.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lotus ve kilit rozeti: halenin içinde degrade çerçeveli beyaz daire.
class _LockMedallion extends StatelessWidget {
  const _LockMedallion();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hale
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.secondary.withAlpha(22),
            ),
          ),
          // Degrade çerçeve
          Container(
            width: 104,
            height: 104,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.mark(context),
              boxShadow: AppShadows.floating(context),
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: t.surface,
              ),
              padding: const EdgeInsets.all(26),
              child: BrandLotus(color: scheme.primary, sideColor: t.secondary),
            ),
          ),
          // Kilit rozeti
          Positioned(
            right: 26,
            bottom: 26,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
                border: Border.all(color: t.surface, width: 2.5),
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 16,
                color: scheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
