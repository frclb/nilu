import 'dart:async';

import 'package:flutter/material.dart';

import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_scrim.dart';
import '../../design_system/app_tokens.dart';
import '../../domain/services/session_plan.dart';
import '../../localization/app_localizations.dart';
import '../../design_system/app_layout.dart';
import '../yoga/widgets/exercise_media.dart';

/// Rehberli seans: adımları sırayla, zamanlayıcıyla gösterir.
///
/// Buradan önce "Başlat" düğmesi yalnızca bir bildirim çubuğu gösteriyordu;
/// hiçbir şey başlamıyordu. Ekranda zaten duran poz adları, açıklamaları ve
/// süreleri gerçek bir akışa dönüştürüldü — yeni bir video ya da varlık
/// gerekmedi.
///
/// Ses, çan ya da nefes ritmi yok: uygulama bunları çalmıyor ve ölçmüyor.
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
        title: Text(
          context.tr(widget.plan.titleKey),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 21,
            color: theme.colorScheme.primary,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(4),
          child: IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            style: IconButton.styleFrom(backgroundColor: t.surfaceAlt),
            icon: Icon(Icons.close, color: theme.colorScheme.primary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      body: AmbientBackground(
        child: AppContentWidth(
          child: SafeArea(
            top: false,
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
                  ),
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
  });

  final SessionPlan plan;
  final int index;
  final Duration elapsed;
  final bool running;
  final String Function(Duration) clock;
  final VoidCallback onToggle;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final step = plan.steps[index];
    final intoStep = elapsed - plan.startOf(index);
    final remaining = step.duration - intoStep;
    final progress = intoStep.inSeconds / step.duration.inSeconds;
    final next = index + 1 < plan.steps.length ? plan.steps[index + 1] : null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            children: [
              Center(
                child: AppTag(
                  label: context.tr(
                    'session_step_of',
                    params: {
                      'n': '${index + 1}',
                      'total': '${plan.steps.length}',
                    },
                  ),
                  dotColor: theme.colorScheme.primary,
                  background: t.brandTint,
                  foreground: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Hareketin sessiz, döngülü mini videosu; üstünde kalan süre
              // ve adımın ilerlemesi. Önce yalnızca bir sayaç halkası vardı:
              // kullanıcı hareketi metinden tahmin ediyordu.
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl - 4),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (step.mediaKey case final key?)
                        ExerciseClip(mediaKey: key, playing: running)
                      else
                        ColoredBox(color: t.surfaceAlt),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [AppScrim.veil(170), AppScrim.veil(0)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 20,
                        child: Text(
                          clock(remaining),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontSize: 44,
                            height: 1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: AppScrim.ink,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 5,
                          color: t.secondary,
                          backgroundColor: AppScrim.frost(50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              AppCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        context.tr(step.nameKey),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          height: 1.2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr(step.descriptionKey),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        height: 1.6,
                        color: t.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (next != null) ...[
                const SizedBox(height: 12),
                // Sıradaki poz: adı ve süresi; dokunulmuyor, yalnızca bilgi.
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      if (next.mediaKey case final key?)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: SizedBox(
                            width: 52,
                            height: 40,
                            child: ExercisePhoto(
                              asset: ExerciseMedia.photo(key),
                            ),
                          ),
                        )
                      else
                        AppIconTile(
                          icon: Icons.skip_next_rounded,
                          size: 40,
                          background: t.surface,
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${context.tr(next.nameKey)} · '
                          '${context.tr('duration_minutes', params: {'n': '${next.duration.inMinutes}'})}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: AppGradientButton(
                  label: context.tr(
                    running ? 'session_pause' : 'session_resume',
                  ),
                  icon: running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  height: 56,
                  radius: AppRadius.pill,
                  onPressed: onToggle,
                ),
              ),
              const SizedBox(width: 12),
              _SkipButton(onPressed: onSkip),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sonraki poza geç: yuvarlak düğme, altında kısa etiket.
class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Material(
      color: t.surfaceAlt,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.fast_forward_rounded, size: 22, color: primary),
                Text(
                  context.tr('session_skip'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: primary,
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

/// Seans bitti.
class _Finished extends StatelessWidget {
  const _Finished({required this.total, required this.clock});

  final Duration total;
  final String Function(Duration) clock;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconTile(
              icon: Icons.check_rounded,
              size: 88,
              circle: true,
              gradient: AppGradients.mark(context),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('session_done_title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontSize: 28,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr(
                'session_done_body',
                params: {'duration': clock(total)},
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.6,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 28),
            AppGradientButton(
              label: context.tr('session_close'),
              expand: false,
              radius: AppRadius.pill,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
