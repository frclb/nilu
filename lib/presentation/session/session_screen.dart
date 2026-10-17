import 'dart:async';

import 'package:flutter/material.dart';

import '../../design_system/app_tokens.dart';
import '../../domain/services/session_plan.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';

/// Rehberli seans: adımları sırayla, zamanlayıcıyla gösterir.
///
/// Buradan önce "Başlat" düğmesi yalnızca bir bildirim çubuğu gösteriyordu;
/// hiçbir şey başlamıyordu. Ekranda zaten duran poz adları, açıklamaları ve
/// süreleri gerçek bir akışa dönüştürüldü — yeni bir video ya da varlık
/// gerekmedi.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key, required this.plan});

  final SessionPlan plan;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
        if (widget.plan.stepIndexAt(_elapsed) == null) {
          _timer?.cancel();
          _running = false;
        }
      });
    });
  }

  void _toggle() {
    setState(() => _running = !_running);
    if (_running) {
      _start();
    } else {
      _timer?.cancel();
    }
  }

  /// Bir sonraki adıma atlar.
  ///
  /// Kullanıcı bir pozu erken bitirebilmeli; aksi hâlde ekranın karşısında
  /// sayacın dolmasını beklemek zorunda kalıyor.
  void _skip() {
    final index = widget.plan.stepIndexAt(_elapsed);
    if (index == null) return;
    setState(() {
      _elapsed = widget.plan.startOf(index) + widget.plan.steps[index].duration;
      if (widget.plan.stepIndexAt(_elapsed) == null) {
        _timer?.cancel();
        _running = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _clock(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final index = widget.plan.stepIndexAt(_elapsed);
    final done = index == null;

    return Scaffold(
      backgroundColor: t.background,
      appBar: AppBar(
        backgroundColor: t.background,
        elevation: 0,
        title: Text(context.tr(widget.plan.titleKey)),
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: AppContentWidth(
        child: SafeArea(
          child: done
              ? _Finished(total: widget.plan.total, clock: _clock)
              : _Active(
                  plan: widget.plan,
                  index: index,
                  elapsed: _elapsed,
                  running: _running,
                  clock: _clock,
                  onToggle: _toggle,
                  onSkip: _skip,
                  theme: theme,
                ),
        ),
      ),
    );
  }
}

class _Active extends StatelessWidget {
  const _Active({
    required this.plan,
    required this.index,
    required this.elapsed,
    required this.running,
    required this.clock,
    required this.onToggle,
    required this.onSkip,
    required this.theme,
  });

  final SessionPlan plan;
  final int index;
  final Duration elapsed;
  final bool running;
  final String Function(Duration) clock;
  final VoidCallback onToggle;
  final VoidCallback onSkip;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final step = plan.steps[index];
    final intoStep = elapsed - plan.startOf(index);
    final remaining = step.duration - intoStep;
    final progress = intoStep.inSeconds / step.duration.inSeconds;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Text(
            context.tr(
              'session_step_of',
              params: {'n': '${index + 1}', 'total': '${plan.steps.length}'},
            ),
            style: theme.textTheme.labelLarge?.copyWith(
              letterSpacing: 1,
              color: t.textMuted,
            ),
          ),
          const SizedBox(height: 24),

          // Kalan süre halkası.
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 10,
                    strokeCap: StrokeCap.round,
                    backgroundColor: t.brandTint,
                    valueColor: AlwaysStoppedAnimation(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  clock(remaining),
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text(
            context.tr(step.nameKey),
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                context.tr(step.descriptionKey),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ),
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSkip,
                  icon: const Icon(Icons.skip_next),
                  label: Text(context.tr('session_skip')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: t.border),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onToggle,
                  icon: Icon(running ? Icons.pause : Icons.play_arrow),
                  label: Text(
                    context.tr(running ? 'session_pause' : 'session_resume'),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({required this.total, required this.clock});

  final Duration total;
  final String Function(Duration) clock;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('session_done_title'),
              style: theme.textTheme.displayLarge?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'session_done_body',
                params: {'duration': clock(total)},
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 15,
                height: 1.6,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 52)),
              child: Text(context.tr('session_close')),
            ),
          ],
        ),
      ),
    );
  }
}
