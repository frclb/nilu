import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Markanın lotusu — uygulama ikonu ve açılış ekranıyla **aynı eğriler**.
///
/// Şekil `tool/lotus.py` içinde tanımlı ve oradan ikon (`generate_icon.py`)
/// ile açılış ekranı işareti (`generate_launch_image.py`) üretiliyor. Bu
/// dosya aynı geometrinin Dart karşılığı: uygulamanın içinde de aynı çiçek
/// çizilebilsin diye.
///
/// Onboarding daha önce `Icons.spa` kullanıyordu — Material'in üç yapraklı
/// genel ikonu. Kullanıcı ana ekranda beş yapraklı bir simge görüp uygulamayı
/// açtığında başka bir çiçek karşılıyordu.
///
/// İki dilde iki kopya olduğu için `test/design_system/brand_lotus_test.dart`
/// bu çizimi üretilmiş açılış görseliyle piksel piksel karşılaştırıyor.
class BrandLotus extends StatelessWidget {
  const BrandLotus({
    super.key,
    required this.color,
    this.sideColor,
    this.sideOpacity = 0.75,
  });

  /// Orta yaprağın rengi.
  final Color color;

  /// Yan yaprakların rengi. Verilmezse [color]'ın [sideOpacity] kadarı.
  final Color? sideColor;

  /// Yan yaprakların saydamlığı — üst üste binen yapraklara derinlik veriyor.
  final double sideOpacity;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _LotusPainter(
      color: color,
      sideColor: sideColor ?? color.withValues(alpha: sideOpacity),
    ),
  );
}

/// Yaprağın kontrol noktaları (matematik koordinatları: taban orijinde,
/// uç yukarıda). Hem çizilen yol hem sınır hesabı buradan türüyor ki ikisi
/// ayrışmasın.
({Offset r1, Offset r2, Offset apex, Offset l1, Offset l2}) _petalControls(
  double width,
  double height,
) => (
  r1: Offset(width, height * 0.18),
  r2: Offset(width * 0.72, height * 0.72),
  apex: Offset(0, height),
  l1: Offset(-width * 0.72, height * 0.72),
  l2: Offset(-width, height * 0.18),
);

/// Yaprağı tabanından döndürüp ekran koordinatlarına çevirir.
///
/// Matematikte y yukarı, ekranda aşağı; dönüş taban etrafında.
Offset _place(Offset p, double cos, double sin) =>
    Offset(p.dx * cos - p.dy * sin, -(p.dx * sin + p.dy * cos));

Path _petalPath(double width, double height, double angleDeg) {
  final a = angleDeg * math.pi / 180;
  final cos = math.cos(a);
  final sin = math.sin(a);
  final c = _petalControls(width, height);
  Offset t(Offset p) => _place(p, cos, sin);

  final base = t(Offset.zero);
  final apex = t(c.apex);
  return Path()
    ..moveTo(base.dx, base.dy)
    ..cubicTo(t(c.r1).dx, t(c.r1).dy, t(c.r2).dx, t(c.r2).dy, apex.dx, apex.dy)
    ..cubicTo(t(c.l1).dx, t(c.l1).dy, t(c.l2).dx, t(c.l2).dy, base.dx, base.dy)
    ..close();
}

/// Yaprağın **gerçek** sınırlarını örnekleyerek bulur.
///
/// `Path.getBounds()` eğrinin değil kontrol noktalarının sınırını veriyor;
/// kontrol noktaları eğrinin dışına taştığı için çizim gereğinden küçük
/// ölçekleniyordu (ölçüldü: 360x274 kutuda 328x250'de kalıyordu). Python
/// tarafı da eğriyi noktalara bölüp sınırı öyle buluyor.
Rect _petalBounds(double width, double height, double angleDeg) {
  final a = angleDeg * math.pi / 180;
  final cos = math.cos(a);
  final sin = math.sin(a);
  final c = _petalControls(width, height);

  double minX = 0, maxX = 0, minY = 0, maxY = 0;
  void add(Offset p) {
    final q = _place(p, cos, sin);
    minX = math.min(minX, q.dx);
    maxX = math.max(maxX, q.dx);
    minY = math.min(minY, q.dy);
    maxY = math.max(maxY, q.dy);
  }

  const steps = 120;
  for (final curve in [
    (Offset.zero, c.r1, c.r2, c.apex),
    (c.apex, c.l1, c.l2, Offset.zero),
  ]) {
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final u = 1 - t;
      add(
        curve.$1 * (u * u * u) +
            curve.$2 * (3 * u * u * t) +
            curve.$3 * (3 * u * t * t) +
            curve.$4 * (t * t * t),
      );
    }
  }
  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

/// Lotusun yaprakları: `(yan yapraklar, orta yaprak)`.
///
/// Ölçüler `tool/lotus.py` ile aynı oranlarda; birim tuval 1x1 kabul edilip
/// çizim sonradan kutuya sığdırılıyor.
const _h = 0.34;
const _w = 0.105;
const _layout = <(double, double)>[
  (-58, 0.80),
  (58, 0.80),
  (-30, 0.90),
  (30, 0.90),
];

(List<Path>, Path) _lotusPaths() => (
  [
    for (final (angle, scale) in _layout)
      _petalPath(_w * scale, _h * scale, angle),
  ],
  _petalPath(_w, _h, 0),
);

/// Bütün çiçeğin gerçek sınırları.
Rect _lotusBounds() {
  var r = _petalBounds(_w, _h, 0);
  for (final (angle, scale) in _layout) {
    r = r.expandToInclude(_petalBounds(_w * scale, _h * scale, angle));
  }
  return r;
}

class _LotusPainter extends CustomPainter {
  _LotusPainter({required this.color, required this.sideColor});

  final Color color;
  final Color sideColor;

  @override
  void paint(Canvas canvas, Size size) {
    final (side, middle) = _lotusPaths();

    final bounds = _lotusBounds();
    if (bounds.isEmpty) return;

    final scale = math.min(size.width / bounds.width, size.height / bounds.height);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(-bounds.center.dx, -bounds.center.dy);

    // Yan yapraklar **tek bir yol** olarak birleştirilip bir kez boyanıyor.
    // Dördü ayrı ayrı çizilirse saydam yapraklar kesiştikleri yerde üst üste
    // binip koyulaşıyor; Python tarafı maskeye düz yazdığı için orada böyle
    // bir koyulaşma yok ve iki çizim ayrışıyordu (ölçüldü: örtüşme 0.74'e
    // düşüyor).
    var merged = side.first;
    for (final p in side.skip(1)) {
      merged = Path.combine(PathOperation.union, merged, p);
    }
    canvas.drawPath(merged, Paint()..color = sideColor..isAntiAlias = true);
    canvas.drawPath(middle, Paint()..color = color..isAntiAlias = true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LotusPainter old) =>
      old.color != color || old.sideColor != sideColor;
}
