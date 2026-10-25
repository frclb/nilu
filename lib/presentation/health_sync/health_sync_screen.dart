import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/platform/app_platform.dart';
import '../../data/datasources/health_datasource.dart';
import '../../data/repositories/health_write_back.dart';
import '../../data/repositories/period_repository.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/health_import.dart';
import '../../localization/app_localizations.dart';
import '../calendar/view_models/calendar_view_model.dart';
import '../profile/widgets/settings_surface.dart';
import '../../design_system/app_layout.dart';

/// Apple Sağlık / Health Connect eşitlemesi.
///
/// Apple Watch ve diğer uygulamaların verisi HealthKit'e, Android'de saat ve
/// başka uygulamaların verisi Health Connect'e akıyor; buradan içeri almak,
/// kullanıcının aynı bilgiyi iki kez girmesini önlüyor. Akış iki platformda
/// aynı; değişen metinler ve Android'in geçmiş verisi izni.
class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({
    super.key,
    @visibleForTesting this.health,
    @visibleForTesting this.writeBack,
  });

  /// Testte platform kanalı yok; sahte Sağlık kaynağı ve onunla kurulan
  /// yazma servisi buradan veriliyor.
  final HealthDatasource? health;
  final HealthWriteBack? writeBack;

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen>
    with WidgetsBindingObserver {
  late final HealthDatasource _health = widget.health ?? HealthDatasource();
  final PeriodRepository _repository = const PeriodRepository();
  late final HealthWriteBack _writeBack =
      widget.writeBack ?? HealthWriteBack(datasource: _health);

  bool _available = true;

  /// Android: Health Connect yok ya da eski; Play sayfası açılabilir.
  bool _canInstall = false;
  bool _busy = false;
  bool _writeBackOn = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAvailability();
    _writeBack.isEnabled().then((on) {
      if (mounted) setState(() => _writeBackOn = on);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Play'den Health Connect kurulup dönülünce ekran kendini güncellesin.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_available) {
      _checkAvailability();
    }
  }

  /// Metin anahtarı: Android'de Apple Sağlık yerine Health Connect.
  ///
  /// `health_sync_title` → `health_connect_sync_title`: aynı anahtarın
  /// `health_` önekinden (7 harf) sonrası.
  String _k(String key) =>
      AppPlatform.isAndroid ? 'health_connect_${key.substring(7)}' : key;

  /// Sağlık'a yazmayı açar ya da kapatır.
  ///
  /// Açarken yazma izni isteniyor ve geçmiş hemen yazılıyor; izin yoksa ayar
  /// açılmıyor. Kapatınca Sağlık'a daha önce yazılanlar orada kalıyor:
  /// kullanıcının Sağlık'taki verisini sessizce silmek doğru olmaz.
  Future<void> _setWriteBack(bool on) async {
    if (!on) {
      await _writeBack.setEnabled(false);
      if (!mounted) return;
      setState(() {
        _writeBackOn = false;
        _result = context.tr(_k('health_write_off'));
      });
      return;
    }

    setState(() {
      _busy = true;
      _result = null;
    });
    final denied = context.tr(_k('health_permission_denied'));
    final unavailable = context.tr(_k('health_permission_unavailable'));
    final calendar = context.read<CalendarViewModel>();

    final access = await _health.requestPermissions(includeWrite: true);
    if (!mounted) return;
    if (access != HealthAccess.granted) {
      setState(() {
        _busy = false;
        _result = access == HealthAccess.denied ? denied : unavailable;
      });
      return;
    }

    final ok = await _writeBack.syncNow(
      periods: calendar.periodLogs,
      dailyLogs: calendar.dailyLogs,
    );
    if (ok) await _writeBack.setEnabled(true);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _writeBackOn = ok;
      _result = context.tr(
        _k(ok ? 'health_write_done' : 'health_write_failed'),
      );
    });
  }

  Future<void> _checkAvailability() async {
    final available = await _health.isAvailable();
    final canInstall = !available && await _health.canInstall();
    if (!mounted) return;
    setState(() {
      _available = available;
      _canInstall = canInstall;
    });
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _result = null;
    });

    final denied = context.tr(_k('health_permission_denied'));
    final unavailable = context.tr(_k('health_permission_unavailable'));
    final noneFound = context.tr('health_import_none');
    final historyLimited = context.tr('health_connect_history_limited');
    final calendar = context.read<CalendarViewModel>();

    final access = await _health.requestPermissions();
    if (!mounted) return;
    if (access != HealthAccess.granted) {
      setState(() {
        _busy = false;
        // İstem hiç açılamadıysa kullanıcıya "sen reddettin" dememeli:
        // karar onun değildi ve yapabileceği bir şey yok.
        _result = access == HealthAccess.denied ? denied : unavailable;
      });
      return;
    }

    // Android: geçmiş izni yoksa Health Connect yalnızca son 30 günü
    // veriyor. Reddedilirse yine de okunuyor ama kullanıcıya söyleniyor.
    final fullHistory = await _health.requestHistoryAccess();
    if (!mounted) return;

    // Bir yıl geriye bak: daha eskisi tahminleri etkilemiyor ve okuma
    // süresini gereksiz uzatıyor.
    final incoming = await _health.readPeriods(
      since: DateTime.now().subtract(const Duration(days: 365)),
    );
    final existing = await _repository.getPeriodLogs();

    // Çakışanlar kullanıcının kendi kaydı lehine bırakılır; elle
    // işaretlenen bir dönemi dış veriyle ezmek düzeltmesini geri almak olur.
    final fresh = HealthImport.newOnes(existing: existing, incoming: incoming);

    if (!mounted) return;
    if (fresh.isEmpty) {
      setState(() {
        _busy = false;
        _result = fullHistory ? noneFound : '$noneFound $historyLimited';
      });
      return;
    }

    final merged = HealthImport.merge(existing: existing, incoming: incoming);
    await _repository.savePeriodLogs(merged);
    await calendar.refreshData();

    if (!mounted) return;
    final done = context.tr(
      fresh.length == 1 ? 'health_import_done_one' : 'health_import_done',
      params: {'count': '${fresh.length}'},
    );
    setState(() {
      _busy = false;
      _result = fullHistory ? done : '$done $historyLimited';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: SettingsAppBar(title: context.tr(_k('health_sync_title'))),
      body: AmbientBackground(
        child: AppContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              SettingsCard(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: Column(
                  children: [
                    AppIconTile(
                      icon: Icons.favorite_rounded,
                      size: 68,
                      gradient: AppGradients.mark(context),
                      color: theme.colorScheme.onPrimary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      context.tr(_k('health_sync_desc')),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: t.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!_available) ...[
                SettingsNote(
                  text: context.tr(_k('health_unavailable')),
                  icon: Icons.info_outline_rounded,
                ),
                if (_canInstall) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppGradientButton(
                    key: const Key('health_connect_install'),
                    label: context.tr('health_connect_install'),
                    icon: Icons.download_rounded,
                    onPressed: _health.install,
                  ),
                ],
              ] else ...[
                // Yazma anahtarı ekranın üst yarısında: sonuç metni ve
                // izin istemi ona bağlı, aşağıda kaybolmasın.
                SettingsCard(
                  padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
                  child: SwitchListTile(
                    key: const Key('health_write_back'),
                    contentPadding: EdgeInsets.zero,
                    isThreeLine: true,
                    secondary: AppIconTile(
                      icon: Icons.event_available_outlined,
                      circle: true,
                      color: t.secondary,
                      background: t.secondaryTint,
                    ),
                    title: Text(
                      context.tr(_k('health_write_title')),
                      style: SettingsText.title(context),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        context.tr(_k('health_write_body')),
                        style: SettingsText.subtitle(context),
                      ),
                    ),
                    value: _writeBackOn,
                    onChanged: _busy ? null : _setWriteBack,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: t.brandTint,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppGradientButton(
                        label: context.tr(_k('health_import_button')),
                        icon: Icons.download_rounded,
                        busy: _busy,
                        onPressed: _busy ? null : _import,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _Bullet(
                        text: context.tr('health_sync_point_merge'),
                        icon: Icons.info_outline_rounded,
                        iconColor: t.secondary,
                      ),
                    ],
                  ),
                ),
              ],

              if (_result != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _result!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.text,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              SettingsCard(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  children: [
                    _Bullet(text: context.tr(_k('health_sync_point_watch'))),
                    _Bullet(text: context.tr('health_sync_point_local')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? iconColor;

  const _Bullet({
    required this.text,
    this.icon = Icons.verified_user_outlined,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor ?? t.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
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
