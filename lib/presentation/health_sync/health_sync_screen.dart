import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/health_datasource.dart';
import '../../data/repositories/period_repository.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/health_import.dart';
import '../../localization/app_localizations.dart';
import '../calendar/view_models/calendar_view_model.dart';

/// Apple Sağlık / Health Connect eşitlemesi.
///
/// Apple Watch ve diğer uygulamaların verisi HealthKit'e akıyor; buradan
/// içeri almak, kullanıcının aynı bilgiyi iki kez girmesini önlüyor.
class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  final HealthDatasource _health = HealthDatasource();
  final PeriodRepository _repository = const PeriodRepository();

  bool _available = true;
  bool _busy = false;
  String? _result;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final available = await _health.isAvailable();
    if (!mounted) return;
    setState(() => _available = available);
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _result = null;
    });

    final denied = context.tr('health_permission_denied');
    final noneFound = context.tr('health_import_none');
    final calendar = context.read<CalendarViewModel>();

    final granted = await _health.requestPermissions();
    if (!mounted) return;
    if (!granted) {
      setState(() {
        _busy = false;
        _result = denied;
      });
      return;
    }

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
        _result = noneFound;
      });
      return;
    }

    final merged = HealthImport.merge(existing: existing, incoming: incoming);
    await _repository.savePeriodLogs(merged);
    await calendar.refreshData();

    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = context.tr(
        'health_import_done',
        params: {'count': '${fresh.length}'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('health_sync_title'))),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: t.brandTint,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(
              Icons.favorite_outline,
              size: 34,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('health_sync_desc'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: t.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          _Bullet(text: context.tr('health_sync_point_watch')),
          _Bullet(text: context.tr('health_sync_point_merge')),
          _Bullet(text: context.tr('health_sync_point_local')),

          const SizedBox(height: AppSpacing.xxl),

          if (!_available)
            Text(
              context.tr('health_unavailable'),
              style: theme.textTheme.bodyMedium?.copyWith(color: t.textMuted),
            )
          else
            FilledButton.icon(
              onPressed: _busy ? null : _import,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_outlined),
              label: Text(context.tr('health_import_button')),
            ),

          if (_result != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              _result!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;

  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: t.success),
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
