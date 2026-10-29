import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../design_system/app_tokens.dart';
import '../../design_system/launch_mark.dart';

/// Soğuk açılışta sistemin açılış ekranını uygulamaya bağlayan perde.
///
/// iOS'un açılış ekranında ortada çıplak, erik renkli bir lotus var
/// (`tool/generate_launch_image.py`). Flutter'ın ilk karesi ise dairenin
/// içinde beyaz lotus, altında "Nilu" ve bir çark gösteriyordu: işaret bir
/// karede şekil, renk ve yer değiştirip zıplıyordu.
///
/// Perdenin ilk karesi açılış ekranıyla **birebir aynı**, geçiş görünmüyor.
/// Sonra lotusun arkasından daire büyüyor, lotus küçülüp beyazlaşarak içine
/// oturuyor, işaret yukarı kayıyor ve "Nilu" beliriyor. Uygulama hazırsa
/// perde hafifçe büyüyerek soluyor; altında yönlendirilmiş ekran zaten
/// çizilmiş bekliyor. Zamanlama tasarım prototipiyle aynı.
///
/// Hazır değilse son karede bekleniyor ve bir süre sonra çark çıkıyor —
/// splash'in eskiden yaptığı iş. Hazırken dokunmak animasyonu kısaltıyor.
/// "Hareketi azalt" açıksa hareket yok: açılış karesi yalnızca soluyor.
///
/// Uygulamanın kökünde, yönlendirilen her şeyin üstünde duruyor ve ömrü
/// boyunca bir kez oynuyor: arka plandan dönüşte tekrar çıkmıyor.
class LaunchIntro extends StatefulWidget {
  const LaunchIntro({
    super.key,
    required this.ready,
    required this.isReady,
    required this.child,
  });

  /// Hazır olma durumu değişince haber veren kaynak (`UserViewModel`).
  final Listenable ready;

  /// Uygulama perdeyi kaldırmaya hazır mı: yerel durum okundu mu.
  final ValueGetter<bool> isReady;

  final Widget child;

  /// İşaretin yükseldiği mesafe; altında "Nilu"ya yer açılıyor.
  static const double rise = 30;

  /// Giriş animasyonu; bittiğinde son kare bekliyor.
  static const Duration duration = Duration(milliseconds: 1250);

  /// Perdenin kalkışı.
  static const Duration exitDuration = Duration(milliseconds: 350);

  /// Hazır olunmadan bekleniyorsa çarkın belirmesine kadar geçen süre.
  static const Duration spinnerDelay = Duration(milliseconds: 1500);

  @override
  State<LaunchIntro> createState() => _LaunchIntroState();
}

class _LaunchIntroState extends State<LaunchIntro>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: LaunchIntro.duration,
  );
  // Kalkış ve bekleme "Hareketi azalt"ta da gerçek süresinde: denetleyici
  // varsayılan olarak o ayarda süreyi yirmide bire indiriyor, perde bir
  // karede yok olup çark hemen çıkıyordu. Solma hareket sayılmıyor.
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: LaunchIntro.exitDuration,
    animationBehavior: AnimationBehavior.preserve,
  );

  /// Hazır olunmadan geçen bekleme; çarkın görünürlüğünü sürüyor. Zamanlayıcı
  /// yerine denetleyici: testte bekleyen `Timer` bırakmıyor.
  late final AnimationController _wait = AnimationController(
    vsync: this,
    duration: LaunchIntro.spinnerDelay * 1.4,
    animationBehavior: AnimationBehavior.preserve,
  );

  bool _started = false;
  bool _reduced = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    widget.ready.addListener(_maybeLeave);
    _intro.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      _maybeLeave();
      if (!_leaving) _wait.forward();
    });
    _exit.addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _done = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      // Hareket yok: açılış karesi hazır olunca yalnızca soluyor.
      _wait.forward();
      _maybeLeave();
    } else {
      _intro.forward();
    }
  }

  @override
  void didUpdateWidget(LaunchIntro old) {
    super.didUpdateWidget(old);
    if (old.ready != widget.ready) {
      old.ready.removeListener(_maybeLeave);
      widget.ready.addListener(_maybeLeave);
    }
  }

  @override
  void dispose() {
    widget.ready.removeListener(_maybeLeave);
    _intro.dispose();
    _exit.dispose();
    _wait.dispose();
    super.dispose();
  }

  bool get _leaving => _exit.isAnimating || _exit.isCompleted;

  void _maybeLeave() {
    if (_done || _leaving || !widget.isReady()) return;
    if (!_reduced && !_intro.isCompleted) return;
    _wait.stop();
    _exit.forward();
  }

  /// Hazırken dokunmak beklemeyi kısaltıyor: işaret son karesine atlıyor ve
  /// perde kalkıyor.
  void _skip() {
    if (_done || _leaving || !widget.isReady()) return;
    if (_reduced) {
      _maybeLeave();
      return;
    }
    // `forward` son değerden devam ediyor; tamamlanınca `_maybeLeave`.
    _intro.animateTo(1, duration: const Duration(milliseconds: 150));
  }

  @override
  Widget build(BuildContext context) {
    // Yapı sabit kalıyor: perde kalkınca yalnızca ikinci çocuk düşüyor, alttaki
    // uygulamanın durumu korunuyor.
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_done)
          GestureDetector(
            key: const Key('launch_intro'),
            behavior: HitTestBehavior.opaque,
            onTap: _skip,
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: Listenable.merge([_intro, _exit, _wait]),
                builder: (context, _) => _Curtain(
                  intro: _intro.value,
                  exit: _exit.value,
                  wait: _wait.value,
                  reduced: _reduced,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Perdenin bir karesi; değerler denetleyicilerden.
class _Curtain extends StatelessWidget {
  const _Curtain({
    required this.intro,
    required this.exit,
    required this.wait,
    required this.reduced,
  });

  final double intro;
  final double exit;
  final double wait;
  final bool reduced;

  // Prototipteki eğriler (CSS `cubic-bezier`).
  static const _settle = Cubic(0.22, 1, 0.36, 1);
  static const _pop = Cubic(0.34, 1.32, 0.64, 1);
  static const _glide = Cubic(0.65, 0, 0.35, 1);

  /// [intro] içinde [startMs]–[endMs] aralığının eğriden geçmiş ilerlemesi.
  double _phase(int startMs, int endMs, Curve curve) {
    final total = LaunchIntro.duration.inMilliseconds;
    return Interval(
      startMs / total,
      endMs / total,
      curve: curve,
    ).transform(intro);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;

    // 150–750 ms: daire büyüyor, lotus küçülüp beyazlaşarak içine oturuyor.
    final grow = _phase(150, 750, _pop);
    final settle = _phase(150, 750, _settle);
    // 500–950 ms: işaret yükseliyor. 650–1050 ms: "Nilu" beliriyor.
    final rise = -LaunchIntro.rise * _phase(500, 950, _glide);
    final word = _phase(650, 1050, _settle);
    // Kalkış: perde soluyor ve hafifçe büyüyor. İşaret zeminden önce
    // kayboluyor: alttaki karşılama ekranının kendi büyük lotusu var ve
    // ikisi aynı anda yarı saydam görünüyordu.
    final out = Curves.easeIn.transform(exit);
    final markOut = Curves.easeOut.transform(
      const Interval(0, 0.5).transform(exit),
    );
    final spinner = const Interval(0.7, 1).transform(wait);

    const box = LaunchMark.launchWidth;
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 1 - out,
          child: ColoredBox(color: t.background),
        ),
        Opacity(
          opacity: 1 - markOut,
          child: Transform.scale(
            scale: reduced ? 1 : 1 + 0.08 * out,
            child: Center(
              child: Transform.translate(
                offset: Offset(0, rise),
                child: SizedBox.square(
                  dimension: box,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      LaunchMark(circle: grow, settle: settle),
                      // Kutunun ortası ekranın ortası; yazı dairenin altında.
                      Positioned(
                        top: box / 2 + LaunchMark.markSize / 2 + 20,
                        left: -box,
                        right: -box,
                        child: Column(
                          children: [
                            Opacity(
                              opacity: word,
                              child: Transform.translate(
                                offset: Offset(0, 12 * (1 - word)),
                                child: Text(
                                  AppInfo.displayName,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontSize: 34,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: -0.5,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Yalnızca beklenirken ağaçta: çark kendi kendine
                            // dönüyor, görünmezken de kare istemesin.
                            SizedBox.square(
                              dimension: 18,
                              child: spinner > 0
                                  ? Opacity(
                                      opacity: spinner,
                                      child: CircularProgressIndicator(
                                        key: const Key('launch_intro_spinner'),
                                        strokeWidth: 2,
                                        color: t.secondary,
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
