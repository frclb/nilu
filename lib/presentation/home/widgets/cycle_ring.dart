import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import 'cycle_ring_data.dart';

/// Döngüyü papatya çelengi olarak çizer ve düzen değiştiğinde yeniler.
///
/// Döngü tahmin edildiği kadar sürmeyebilir: erken biterse çiçek sayısı azalır,
/// gecikirse artar. Yeni düzene sıçrayarak geçmek çelengi bozuk gösteriyordu.
///
/// Yenileme iki evre: eski çelenk sırayla kapanıyor, sonra yenisi 1. günden
/// itibaren sırayla açılıyor. Canlandırma yalnızca bu alanı kapsıyor —
/// kartın geri kalanı ve ekranın diğer bölümleri sabit.
class CycleRing extends StatefulWidget {
  const CycleRing({
    super.key,
    required this.data,
    required this.center,
    this.caption,
  });

  final CycleRingData data;

  /// Halkanın ortasında duran içerik.
  ///
  /// Başlık ve halka önce ayrı bloklardı; ikisi ayrı ayrı dikkat çekiyor ve
  /// aradaki boşluk kartı seyrek gösteriyordu.
  final Widget center;

  /// Merkezin altındaki küçük satır. Verilmezse "N günlük döngü".
  ///
  /// Gebelik panosu aynı çelengi 40 haftayla kullanıyor; orada "40 günlük
  /// döngü" yazması yanlış olurdu.
  final String? caption;

  @override
  State<CycleRing> createState() => _CycleRingState();
}

class _CycleRingState extends State<CycleRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Kapanacak olan düzen.
  late CycleRingData _from;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1700),
      vsync: this,
    );

    // Uygulama açıldığında döngü çoktan uzamışsa çelenk yenileniyor: önce
    // tahmin edilen düzen kapanıyor, sonra bugüne kadar uzayan düzen açılıyor.
    // Kullanıcı "regl hâlâ sürüyor" bilgisini bir sıçrama olarak değil,
    // çelengin yeniden kurulması olarak görüyor.
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

    // Önceki yenileme sürüyorsa onu bitmiş sayıp yeniden başlıyoruz. Yarım
    // kalmış bir çelengin üzerine ikinci bir sıra başlatmak, henüz açılmamış
    // çiçekleri kapanıyor gösteriyordu.
    _from = old.data;
    _controller.forward(from: 0);
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
          builder: (context, child) => CustomPaint(
            size: const Size.square(232),
            painter: _WreathPainter(
              from: _from,
              to: widget.data,
              progress: _controller.value,
              track: t.border,
              core: t.surface,
            ),
            child: child,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.center,
                  const SizedBox(height: 6),
                  Text(
                    widget.caption ??
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

  // Zaman çizelgesi. Aradeğerleme yerine kapan-aç ayrımı tercih edildi:
  // döngü uzunluğu değiştiğinde çiçekler yer değiştirirken hangisinin hangisi
  // olduğu okunmuyordu. Kapanıp yeniden açılmak değişimi açıkça anlatıyor.
  //
  //   0.00 - 0.46   kapanma  (1. günden sona doğru)
  //   0.46 - 0.54   çelenk boş
  //   0.54 - 1.00   açılma   (1. günden sona doğru)
  static const double _outStagger = 0.30;
  static const double _outSpan = 0.16;
  static const double _inStart = 0.54;
  static const double _inStagger = 0.34;
  static const double _inSpan = 0.12;

  /// Sıradaki çiçeğin gecikmesi. Tek çiçekli halkada bölme yapılmıyor.
  double _offset(int index, int count, double stagger) =>
      count <= 1 ? 0 : (index / (count - 1)) * stagger;

  /// Eski çelenkteki bir çiçeğin ölçeği: 1'den 0'a.
  double _outScale(int index, int count) {
    final begin = _offset(index, count, _outStagger);
    final local = ((progress - begin) / _outSpan).clamp(0.0, 1.0);
    return 1 - Curves.easeInCubic.transform(local);
  }

  /// Yeni çelenkteki bir çiçeğin ölçeği: 0'dan 1'e.
  double _inScale(int index, int count) {
    final begin = _inStart + _offset(index, count, _inStagger);
    final local = ((progress - begin) / _inSpan).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(local);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 18;

    // Çiçeklerin dizildiği ince iz. Çelenk boşken alanın ne olduğunu gösteren
    // tek şey bu, o yüzden her zaman çiziliyor.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Kapanan eski çelenk.
    _paintWreath(
      canvas,
      center: center,
      radius: radius,
      data: from,
      scaleOf: (i) => _outScale(i, from.length),
      spinOf: (i) => (1 - _outScale(i, from.length)) * 0.5,
    );

    // Açılan yeni çelenk.
    _paintWreath(
      canvas,
      center: center,
      radius: radius,
      data: to,
      scaleOf: (i) => _inScale(i, to.length),
      // Açılırken yerine dönüyor: çiçek "açılıyor" gibi okunuyor.
      spinOf: (i) => (1 - _inScale(i, to.length)) * -0.6,
    );
  }

  void _paintWreath(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required CycleRingData data,
    required double Function(int) scaleOf,
    required double Function(int) spinOf,
  }) {
    if (data.length <= 0) return;

    // Taban boyut, bugünün büyütülmüş çiçeğine yer kalacak şekilde
    // hesaplanıyor. İki komşu merkez arası `slot` kadar; bugünün yarıçapı ile
    // komşusunun yarıçapının toplamı bunun altında kalmalı:
    //
    //   base/2 * todayScale + base/2 <= slot * clearance
    const todayScale = 1.28;
    const clearance = 0.94;
    final slot = 2 * math.pi * radius / data.length;
    final base = math.min(slot * 2 * clearance / (todayScale + 1), 20.0);

    for (var i = 0; i < data.length; i++) {
      final scale = scaleOf(i);
      if (scale <= 0.01) continue;

      final isToday = i == data.todayIndex;

      // Saat 12'den başla; çiçek dilimin ortasında dursun.
      final angle = -math.pi / 2 + (i + 0.5) * (2 * math.pi / data.length);

      // Bugünün çiçeği bir tık dışarıda: açısal aralık sabit olduğundan dışa
      // çıkmak komşularla arayı açıyor ve çelengin üzerinde kabarmış gibi
      // görünüyor.
      final r = isToday ? radius + base * 0.22 : radius;
      final at = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );

      final color = data.colors[i];

      if (isToday) {
        // Yumuşak bir hâle: bugünü büyütmeye fazla yüklenmeden ayırıyor.
        // Çiçekle birlikte büyüyüp küçülüyor.
        canvas.drawCircle(
          at,
          base * 0.95 * scale,
          Paint()..color = color.withAlpha((38 * scale).round()),
        );
      }

      _drawDaisy(
        canvas,
        at: at,
        size: base * (isToday ? todayScale : 1) * scale,
        petal: color,
        core: core,
        petals: 8,
        spin: spinOf(i),
      );
    }
  }

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
    required double spin,
  }) {
    final paint = Paint()
      ..color = petal
      ..isAntiAlias = true;
    final petalLength = size * 0.52;
    final petalWidth = size * 0.30;

    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(spin);
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
