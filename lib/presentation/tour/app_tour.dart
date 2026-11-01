import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../design_system/app_card.dart';
import '../../design_system/app_decor.dart';
import '../../design_system/app_scrim.dart';
import '../../design_system/app_tokens.dart';
import '../../localization/app_localizations.dart';

/// Uygulamaya ilk girişte neyin nerede olduğunu anlatan tur.
///
/// Kurulum bitince ana ekranda bir kez açılıyor: çark, regl düğmesi, kayıt
/// düğmesi ve sekmeler sırayla aydınlatılıp altında kısa bir açıklama
/// beliriyor. Profil'den yeniden izlenebiliyor.
///
/// Hedefler [TourAnchor] ile işaretleniyor. Anahtar (`GlobalKey`) değil:
/// aynı ekran testte ya da geçişte iki kez ağaçta durabiliyor, küresel
/// anahtar o anda çöküyordu. Ekranda olmayan hedefin (ör. geniş ekranda yan
/// menü) adımı atlanıyor.
abstract final class AppTour {
  /// Kurulum bitti, tur bekliyor.
  static const String pendingKey = 'app_tour_pending';

  /// Tur şu an ekranda. Bildirim izni gerekçesi gibi kendiliğinden açılan
  /// pencereler turun bitmesini bekliyor.
  static final ValueNotifier<bool> active = ValueNotifier(false);

  /// Profil'den "yeniden izle": ana ekran dinliyor.
  static final ValueNotifier<int> requests = ValueNotifier(0);

  /// Kurulum bitince çağrılıyor: ana ekran açılınca tur başlıyor.
  static Future<void> requestAfterOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pendingKey, true);
  }

  /// Profil'den: tur ana ekranda yeniden açılıyor.
  static Future<void> replay() async {
    await requestAfterOnboarding();
    requests.value++;
  }

  static Future<bool> _isPending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(pendingKey) ?? false;
  }

  static Future<void> _clearPending() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(pendingKey);
  }

  /// Tur bitene kadar bekler; tur yoksa hemen döner.
  static Future<void> whenIdle() {
    if (!active.value) return Future.value();
    final done = Completer<void>();
    void listener() {
      if (active.value) return;
      active.removeListener(listener);
      done.complete();
    }

    active.addListener(listener);
    return done.future;
  }

  /// Ana ekranın adımları; ekranda olmayan hedefler atlanıyor.
  static const List<TourStep> homeSteps = [
    TourStep('masthead', 'tour_masthead_title', 'tour_masthead_body'),
    TourStep('period', 'tour_period_title', 'tour_period_body'),
    TourStep('log_fab', 'tour_fab_title', 'tour_fab_body'),
    TourStep('nav_1', 'tour_calendar_title', 'tour_calendar_body'),
    TourStep('nav_2', 'tour_insights_title', 'tour_insights_body'),
    TourStep('nav_3', 'tour_library_title', 'tour_library_body'),
    TourStep('nav_4', 'tour_profile_title', 'tour_profile_body'),
  ];

  /// Turu [context]'in navigator katmanının üstünde açar; bitince döner.
  static Future<void> show(BuildContext context, List<TourStep> steps) async {
    final visible = [
      for (final s in steps)
        if (TourAnchor.rectOf(s.anchor) != null) s,
    ];
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (visible.isNotEmpty) await TourAnchor.reveal(visible.first.anchor);
    await _clearPending();
    if (visible.isEmpty || active.value || overlay == null) return;

    final done = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TourOverlay(
        steps: visible,
        onFinish: () {
          entry.remove();
          active.value = false;
          if (!done.isCompleted) done.complete();
        },
      ),
    );
    active.value = true;
    overlay.insert(entry);
    return done.future;
  }
}

/// Turun bir adımı: hangi hedef, hangi başlık ve açıklama.
@immutable
class TourStep {
  const TourStep(this.anchor, this.titleKey, this.bodyKey);

  final String anchor;
  final String titleKey;
  final String bodyKey;
}

/// Turun aydınlatabileceği bir öğe.
///
/// Son kurulan aynı adlı çapa geçerli; kaldırılınca kaydı siliniyor.
class TourAnchor extends StatefulWidget {
  const TourAnchor({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  static final Map<String, _TourAnchorState> _anchors = {};

  /// Hedef bir kaydırma görünümündeyse onu görünür yere getirir.
  ///
  /// Ana ekran aşağı kaydırılmışken tur başlayınca çark ekranın dışında
  /// kalıyor, aydınlatılan alan boşluğa düşüyordu.
  static Future<void> reveal(String id) async {
    final state = _anchors[id];
    if (state == null || !state.mounted) return;
    if (Scrollable.maybeOf(state.context) == null) return;
    await Scrollable.ensureVisible(
      state.context,
      alignment: 0.08,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Hedefin ekrandaki dikdörtgeni; ekranda değilse null.
  static Rect? rectOf(String id) {
    final state = _anchors[id];
    if (state == null || !state.mounted) return null;
    final box = state.context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.isEmpty) return null;
    return rect;
  }

  @override
  State<TourAnchor> createState() => _TourAnchorState();
}

class _TourAnchorState extends State<TourAnchor> {
  @override
  void initState() {
    super.initState();
    TourAnchor._anchors[widget.id] = this;
  }

  @override
  void didUpdateWidget(TourAnchor old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      if (identical(TourAnchor._anchors[old.id], this)) {
        TourAnchor._anchors.remove(old.id);
      }
      TourAnchor._anchors[widget.id] = this;
    }
  }

  @override
  void dispose() {
    if (identical(TourAnchor._anchors[widget.id], this)) {
      TourAnchor._anchors.remove(widget.id);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Ana ekranda bekleyen turu açar.
///
/// Kurulum bittikten sonra (ya da Profil'den istenince) bir kez. Ekranın
/// üstünde başka bir şey varken (bildirim izni gerekçesi, alt sayfa)
/// başlamıyor; o kapanınca deniyor.
class HomeTourLauncher extends StatefulWidget {
  const HomeTourLauncher({super.key, required this.child});

  final Widget child;

  @override
  State<HomeTourLauncher> createState() => _HomeTourLauncherState();
}

class _HomeTourLauncherState extends State<HomeTourLauncher> {
  Timer? _timer;
  int _tries = 0;

  @override
  void initState() {
    super.initState();
    AppTour.requests.addListener(_schedule);
    _schedule();
  }

  @override
  void dispose() {
    AppTour.requests.removeListener(_schedule);
    _timer?.cancel();
    super.dispose();
  }

  void _schedule() {
    _tries = 0;
    _timer?.cancel();
    // Açılış perdesi ve sayfa geçişi bitsin, veriler gelsin.
    _timer = Timer(const Duration(milliseconds: 1400), _tryStart);
  }

  Future<void> _tryStart() async {
    if (!mounted || AppTour.active.value) return;
    if (!await AppTour._isPending() || !mounted) return;
    // Üstte başka bir şey var mı: hem bu sekmenin gezgininde hem kökte.
    // Bildirim izni gerekçesi kök gezginde açılıyor; ana ekranın kendi
    // rotası o sırada da "en üstte" sayılıyordu ve tur pencerenin üstüne
    // açılıyordu.
    final route = ModalRoute.of(context);
    final root = Navigator.maybeOf(context, rootNavigator: true);
    // Başka sekmedeyken de bekliyor: gizli sekme yine yerleşiyor ve hedefin
    // dikdörtgeni gerçek görünüyordu; tur takvimin üstünde çarkı anlatırdı.
    // go_router gizli sekmelerde zamanlayıcıları kapatıyor (`TickerMode`).
    final covered =
        (route != null && !route.isCurrent) ||
        (root?.canPop() ?? false) ||
        !TickerMode.of(context);
    if (covered || TourAnchor.rectOf('masthead') == null) {
      // Üstte bir pencere var ya da ekran henüz çizilmedi: biraz sonra.
      if (++_tries < 30) {
        _timer = Timer(const Duration(seconds: 1), _tryStart);
      }
      return;
    }
    await AppTour.show(context, AppTour.homeSteps);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Turun katmanı: hedefin çevresi açık, gerisi kararmış; altında ya da
/// üstünde açıklama kartı.
class _TourOverlay extends StatefulWidget {
  const _TourOverlay({required this.steps, required this.onFinish});

  final List<TourStep> steps;
  final VoidCallback onFinish;

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  int _index = 0;

  Future<void> _next() async {
    if (_index + 1 >= widget.steps.length) {
      widget.onFinish();
      return;
    }
    setState(() => _index++);
    // Hedef kaydırılınca yeri değişiyor: kaydırma bitince yeniden ölç.
    await TourAnchor.reveal(widget.steps[_index].anchor);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final media = MediaQuery.of(context);
    final target = (TourAnchor.rectOf(step.anchor) ?? Rect.zero).inflate(8);
    final reduce = media.disableAnimations;
    final duration = reduce ? Duration.zero : const Duration(milliseconds: 320);

    // Ekran okuyucu tur sürerken yalnızca kartı okusun; karartılmış
    // zemindeki öğelere gitmesin.
    return BlockSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // Kararan zemin dokunuşları yutuyor: tur sürerken altta bir şeye
            // yanlışlıkla basılmasın.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {},
                child: TweenAnimationBuilder<Rect?>(
                  tween: RectTween(end: target),
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  builder: (context, rect, _) => CustomPaint(
                    painter: _SpotlightPainter(
                      hole: rect ?? target,
                      veil: AppScrim.veil(185),
                      ring: context.tokens.secondary,
                    ),
                  ),
                ),
              ),
            ),
            // Kartın yeri kendi boyuna göre: hedefin altı, sığmazsa üstü,
            // ikisi de dar gelirse (çark ekranın çoğunu kaplıyor) ekranın
            // altı. Tahmini bir boyla yerleştirmek kartı ekranın dışına
            // düşürüyordu.
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: _CardLayout(target: target, padding: media.padding),
                child: AnimatedSwitcher(
                  duration: duration,
                  child: _TourCard(
                    key: ValueKey(_index),
                    step: step,
                    index: _index,
                    total: widget.steps.length,
                    onNext: _next,
                    onSkip: widget.onFinish,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Açıklama kartını hedefe göre yerleştirir.
class _CardLayout extends SingleChildLayoutDelegate {
  const _CardLayout({required this.target, required this.padding});

  final Rect target;
  final EdgeInsets padding;

  static const double _margin = 16;
  static const double _gap = 14;
  static const double _maxWidth = 420;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = (constraints.maxWidth - _margin * 2).clamp(0.0, _maxWidth);
    return BoxConstraints(
      maxWidth: width,
      maxHeight: constraints.maxHeight - padding.vertical - _margin * 2,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (size.width - childSize.width) / 2;
    final below = target.bottom + _gap;
    if (below + childSize.height <= size.height - padding.bottom - _margin) {
      return Offset(x, below);
    }
    final above = target.top - _gap - childSize.height;
    if (above >= padding.top + _margin) return Offset(x, above);
    return Offset(x, size.height - padding.bottom - _margin - childSize.height);
  }

  @override
  bool shouldRelayout(_CardLayout old) =>
      old.target != target || old.padding != padding;
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    super.key,
    required this.step,
    required this.index,
    required this.total,
    required this.onNext,
    required this.onSkip,
  });

  final TourStep step;
  final int index;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final last = index + 1 == total;

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        key: const Key('app_tour_card'),
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
        decoration: AppCard.decoration(
          t,
        ).copyWith(boxShadow: AppShadows.floating(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                'tour_step_of',
                params: {'n': '${index + 1}', 'total': '$total'},
              ),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: t.secondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(step.titleKey),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 21,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(step.bodyKey),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14.5,
                height: 1.45,
                color: t.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (!last)
                  TextButton(
                    key: const Key('app_tour_skip'),
                    onPressed: onSkip,
                    style: TextButton.styleFrom(foregroundColor: t.textMuted),
                    child: Text(context.tr('tour_skip')),
                  ),
                const Spacer(),
                // Adım noktaları.
                ExcludeSemantics(
                  child: Row(
                    children: [
                      for (var i = 0; i < total; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: i == index ? 14 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == index ? t.secondary : t.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  key: const Key('app_tour_next'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(88, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onPressed: onNext,
                  child: Text(context.tr(last ? 'tour_done' : 'tour_next')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Zemini karartıp hedefin çevresini yuvarlak köşeli bir pencereyle açar.
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.hole,
    required this.veil,
    required this.ring,
  });

  final Rect hole;
  final Color veil;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(hole, const Radius.circular(22));
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(r);
    canvas.drawPath(path, Paint()..color = veil);
    canvas.drawRRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.veil != veil || old.ring != ring;
}
