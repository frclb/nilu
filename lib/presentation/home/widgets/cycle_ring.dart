import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import 'cycle_ring_data.dart';

/// Döngüyü papatya çelengi olarak çizer ve düzen değiştiğinde canlandırır.
///
/// Döngü tahmin edildiği kadar sürmeyebilir: erken biterse çiçek sayısı azalır,
/// gecikirse artar. Yeni düzene sıçrayarak geçmek çelengi bozuk gösteriyordu;
/// çiçekler artık yeni yerlerine dönerek gidiyor, fazlalar açılıyor, eksikler
/// soluyor.
///
/// Canlandırma yalnızca bu alanı kapsıyor — ekranın geri kalanı sabit kalıyor.
class CycleRing extends StatefulWidget {
  const CycleRing({super.key, required this.data, required this.center});

  final CycleRingData data;

  /// Halkanın ortasında duran içerik.
  ///
  /// Başlık ve halka önce ayrı bloklardı; ikisi ayrı ayrı dikkat çekiyor ve
  /// aradaki boşluk kartı seyrek gösteriyordu.
  final Widget center;

  @override
  State<CycleRing> createState() => _CycleRingState();
}

class _CycleRingState extends State<CycleRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Geçişin başladığı düzen.
  late CycleRingData _from;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 950),
      vsync: this,
    );

    // Uygulama açıldığında döngü çoktan uzamışsa, geçiş tahmin edilen
    // çelenkten başlayıp bugüne kadar uzuyor. Kullanıcı "regl hâlâ sürüyor"
    // bilgisini bir sıçrama olarak değil, çelengin büyümesi olarak görüyor.
    final target = widget.data;
    final start = target.clampedToExpected();
    if (start != target) {
      _from = start;
      _controller.forward(from: 0);
    } else {
      _from = target;
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(CycleRing old) {
    super.didUpdateWidget(old);
    if (old.data == widget.data) return;

    // Geçiş ortasında yeni bir değişiklik gelirse, o anki ara durumdan devam
    // etmek gerekiyor; yoksa çiçekler geri sıçrayıp yeniden yola çıkıyor.
    _from = _lerpData(_from, old.data, _controller.value);
    _controller.forward(from: 0);
  }

  /// İki düzen arasındaki ara durumu üretir.
  CycleRingData _lerpData(CycleRingData a, CycleRingData b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    final count = math.max(a.length, b.length);
    return CycleRingData(
      colors: [
        for (var i = 0; i < count; i++)
          Color.lerp(
                i < a.length ? a.colors[i] : b.colors[i],
                i < b.length ? b.colors[i] : a.colors[i],
                t,
              ) ??
              b.colors[math.min(i, b.length - 1)],
      ],
      todayIndex: t < 0.5 ? a.todayIndex : b.todayIndex,
      expected: b.expected,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);

    return Center(
      child: SizedBox(
        width: 232,
        height: 232,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: const Size.square(232),
              painter: _WreathPainter(
                from: _from,
                to: widget.data,
                progress: _controller.value,
                track: t.border,
                core: t.surface,
              ),
              child: child,
            );
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.center,
                  const SizedBox(height: 6),
                  Text(
                    context.tr(
                      'home_ring_cycle_length',
                      params: {'n': '${widget.data.expected}'},
                    ),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 11,
                      height: 1.35,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WreathPainter extends CustomPainter {
  _WreathPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.track,
    required this.core,
  });

  final CycleRingData from;
  final CycleRingData to;
  final double progress;

  /// Çiçeklerin dizildiği ince iz.
  final Color track;

  /// Papatyaların göbek rengi — kartın yüzeyiyle aynı.
  final Color core;

  /// Bir çiçeğin kendi ilerlemesi.
  ///
  /// Hepsi aynı anda hareket ederse çelenk tek parça gibi dönüyor. Bugünden
  /// uzaklaştıkça küçük bir gecikme ekleniyor: değişim bugünden başlayıp
  /// halka boyunca dalga hâlinde yayılıyor.
  double _localProgress(int index, int count) {
    final anchor = to.todayIndex ?? from.todayIndex ?? 0;
    var distance = (index - anchor).abs();
    if (count > 0) {
      distance = math.min(distance, count - distance);
    }
    final delay = count <= 1 ? 0.0 : (distance / count) * 0.55;
    final span = 1 - delay;
    if (span <= 0) return 1;
    final local = ((progress - delay) / span).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(local);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final count = math.max(from.length, to.length);
    if (count <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 18;

    // Çiçeklerin dizildiği ince iz.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Taban boyut, bugünün büyütülmüş çiçeğine yer kalacak şekilde
    // hesaplanıyor. İki komşu merkez arası `slot` kadar; bugünün yarıçapı ile
    // komşusunun yarıçapının toplamı bunun altında kalmalı:
    //
    //   base/2 * todayScale + base/2 <= slot * clearance
    const todayScale = 1.28;
    const clearance = 0.94;

    double sizeFor(int length) {
      if (length <= 0) return 0;
      final slot = 2 * math.pi * radius / length;
      return math.min(slot * 2 * clearance / (todayScale + 1), 20.0);
    }

    final sizeFrom = sizeFor(from.length);
    final sizeTo = sizeFor(to.length);

    for (var i = 0; i < count; i++) {
      final local = _localProgress(i, count);

      final inFrom = i < from.length;
      final inTo = i < to.length;

      // Saat 12'den başla; çiçek dilimin ortasında dursun.
      double angleFor(int length) =>
          -math.pi / 2 + (i + 0.5) * (2 * math.pi / length);

      final angle = _lerp(
        inFrom ? angleFor(from.length) : angleFor(to.length),
        inTo ? angleFor(to.length) : angleFor(from.length),
        local,
      );

      // Düzene yeni katılan çiçek açılıyor, çıkan soluyor.
      final presence = _lerp(inFrom ? 1 : 0, inTo ? 1 : 0, local);
      if (presence <= 0.01) continue;

      final base = _lerp(sizeFrom, sizeTo, local) * presence;
      final isToday = i == (local < 0.5 ? from.todayIndex : to.todayIndex);

      // Bugünün çiçeği bir tık dışarıda: açısal aralık sabit olduğundan dışa
      // çıkmak komşularla arayı açıyor ve çelengin üzerinde kabarmış gibi
      // görünüyor.
      final r = isToday ? radius + base * 0.22 : radius;
      final at = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );

      final color = Color.lerp(
        inFrom ? from.colors[i] : to.colors[i],
        inTo ? to.colors[i] : from.colors[i],
        local,
      )!;

      if (isToday) {
        // Yumuşak bir hâle: bugünü büyütmeye fazla yüklenmeden ayırıyor.
        canvas.drawCircle(
          at,
          base * 0.95,
          Paint()..color = color.withAlpha(38),
        );
      }

      _drawDaisy(
        canvas,
        at: at,
        size: isToday ? base * todayScale : base,
        petal: color,
        core: core,
        petals: 8,
      );
    }
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  /// Tek bir papatya çizer.
  ///
  /// Taç yaprakları merkez çevresinde döndürülmüş elipsler. Yaprak sayısı
  /// tekil çiçeği tanınır kılacak kadar çok, küçük boyutta lekeye dönüşmeyecek
  /// kadar az.
  void _drawDaisy(
    Canvas canvas, {
    required Offset at,
    required double size,
    required Color petal,
    required Color core,
    required int petals,
  }) {
    final paint = Paint()
      ..color = petal
      ..isAntiAlias = true;
    final petalLength = size * 0.52;
    final petalWidth = size * 0.30;

    canvas.save();
    canvas.translate(at.dx, at.dy);
    for (var i = 0; i < petals; i++) {
      canvas.save();
      canvas.rotate(2 * math.pi * i / petals);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -petalLength * 0.52),
          width: petalWidth,
          height: petalLength,
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(Offset.zero, size * 0.17, Paint()..color = core);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WreathPainter old) =>
      old.progress != progress ||
      old.from != from ||
      old.to != to ||
      old.track != track ||
      old.core != core;
}
