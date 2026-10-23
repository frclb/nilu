import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../design_system/app_tokens.dart';
import '../../../localization/app_localizations.dart';
import 'cycle_ring_data.dart';

/// Döngüyü boncuk dizisi olarak çizer ve düzen değiştiğinde yeniler.
///
/// Her gün bir boncuk; geçmiş günler dolu ama soluk, bugün hâleli ve büyük,
/// önümüzdeki (tahmin edilen) günler içi açık halka. Renkler veriden
/// geliyor (bkz. [CycleRingData]): regl gül, foliküler adaçayı, yumurtlama
/// menekşe, luteal kehribar — takvimdekiyle aynı anlam.
///
/// Döngü tahmin edildiği kadar sürmeyebilir: erken biterse boncuk sayısı
/// azalır, gecikirse artar. Yeni düzene sıçrayarak geçmek diziyi bozuk
/// gösteriyordu.
///
/// Yenileme iki evre: eski dizi sırayla sönüyor, sonra yenisi 1. günden
/// itibaren sırayla yanıyor. Canlandırma yalnızca bu alanı kapsıyor —
/// kartın geri kalanı ve ekranın diğer bölümleri sabit.
class CycleRing extends StatefulWidget {
  const CycleRing({
    super.key,
    required this.data,
    required this.center,
    this.caption,
    this.markerIndex,
    this.size = 232,
  });

  final CycleRingData data;

  /// Halkanın ortasında duran içerik.
  ///
  /// Başlık ve halka önce ayrı bloklardı; ikisi ayrı ayrı dikkat çekiyor ve
  /// aradaki boşluk kartı seyrek gösteriyordu.
  final Widget center;

  /// Merkezin altındaki küçük satır (bkz. [RingCaption]).
  ///
  /// Gebelik panosu aynı diziyi 40 haftayla kullanıyor; orada "40 günlük
  /// döngü" yazması yanlış olurdu, o yüzden her pano kendi satırını veriyor.
  final Widget? caption;

  /// Ayrıca işaretlenen boncuk (0 tabanlı) — döngüde tahmini yumurtlama
  /// günü. Bugünün vurgusu her zaman önce gelir.
  final int? markerIndex;

  /// Halkanın kenar uzunluğu.
  final double size;

  @override
  State<CycleRing> createState() => _CycleRingState();
}

class _CycleRingState extends State<CycleRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Sönecek olan düzen.
  late CycleRingData _from;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1700),
      vsync: this,
    );

    // Uygulama açıldığında döngü çoktan uzamışsa dizi yenileniyor: önce
    // tahmin edilen düzen sönüyor, sonra bugüne kadar uzayan düzen yanıyor.
    // Kullanıcı "regl hâlâ sürüyor" bilgisini bir sıçrama olarak değil,
    // dizinin yeniden kurulması olarak görüyor.
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
    // kalmış bir dizinin üzerine ikinci bir sıra başlatmak, henüz yanmamış
    // boncukları sönüyor gösteriyordu.
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
    final size = widget.size;

    // Merkezdeki içerik boncukların iç çemberine sığmalı. Büyük yazıda
    // taşmak yerine bütün blok orantılı küçülüyor.
    final innerWidth = size * 0.72;
    final innerHeight = size * 0.62;

    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => CustomPaint(
            size: Size.square(size),
            painter: _BeadRingPainter(
              from: _from,
              to: widget.data,
              progress: _controller.value,
              marker: widget.markerIndex,
              track: t.border,
              surface: t.surface,
              glow: [t.flowTint, t.accentTint, t.ovulationTint],
            ),
            child: child,
          ),
          child: Center(
            child: SizedBox(
              width: innerWidth,
              height: innerHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: innerWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget.center,
                      if (widget.caption != null) ...[
                        const SizedBox(height: 8),
                        widget.caption!,
                      ],
                    ],
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

/// Halkanın merkezindeki küçük alt satır.
///
/// Döngü panosunda süre bir hap içinde ("● 28 günlük döngü"); gebelik ve
/// lohusalıkta düz, soluk bir satır.
class RingCaption extends StatelessWidget {
  const RingCaption(this.text, {super.key}) : pill = false;

  /// Noktalı hap görünümü.
  const RingCaption.pill(this.text, {super.key}) : pill = true;

  final String text;
  final bool pill;

  /// "N günlük döngü" tek satırda.
  ///
  /// Sözlükteki metin halkanın eski, dar merkezine göre iki satıra
  /// bölünmüştü ("28 günlük\ndöngü"). Hap tek satır; tireyle bölünmüş
  /// birleşik sözcük ("28-Tage-\nZyklus") birleşik kalıyor.
  static String cycleLength(BuildContext context, int days) => context
      .tr('home_ring_cycle_length', params: {'n': '$days'})
      .replaceAll('-\n', '-')
      .replaceAll('\n', ' ');

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      fontSize: 11.5,
      height: 1.3,
      fontWeight: FontWeight.w500,
      color: t.textMuted,
    );

    if (!pill) {
      return Text(text, textAlign: TextAlign.center, style: style);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: t.surfaceAlt.withAlpha(200),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: t.border.withAlpha(130)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: t.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeadRingPainter extends CustomPainter {
  _BeadRingPainter({
    required this.from,
    required this.to,
    required this.progress,
    required this.marker,
    required this.track,
    required this.surface,
    required this.glow,
  });

  final CycleRingData from;
  final CycleRingData to;
  final double progress;

  /// Ayrıca işaretlenen boncuk (bkz. [CycleRing.markerIndex]).
  final int? marker;

  /// Dizi boşken yörüngenin rengi.
  final Color track;

  /// Kartın yüzeyi: içi açık boncukların zemini ve bugünün göbeği.
  final Color surface;

  /// Merkezin arkasındaki yumuşak ışımanın üç tonu.
  final List<Color> glow;

  // Zaman çizelgesi. Aradeğerleme yerine sön-yan ayrımı tercih edildi:
  // döngü uzunluğu değiştiğinde boncuklar yer değiştirirken hangisinin
  // hangisi olduğu okunmuyordu. Sönüp yeniden yanmak değişimi açıkça
  // anlatıyor.
  //
  //   0.00 - 0.46   sönme   (1. günden sona doğru)
  //   0.46 - 0.54   dizi boş
  //   0.54 - 1.00   yanma   (1. günden sona doğru)
  static const double _outStagger = 0.30;
  static const double _outSpan = 0.16;
  static const double _inStart = 0.54;
  static const double _inStagger = 0.34;
  static const double _inSpan = 0.12;

  /// Sıradaki boncuğun gecikmesi. Tek boncuklu halkada bölme yapılmıyor.
  double _offset(int index, int count, double stagger) =>
      count <= 1 ? 0 : (index / (count - 1)) * stagger;

  /// Eski dizideki bir boncuğun ölçeği: 1'den 0'a.
  double _outScale(int index, int count) {
    final begin = _offset(index, count, _outStagger);
    final local = ((progress - begin) / _outSpan).clamp(0.0, 1.0);
    return 1 - Curves.easeInCubic.transform(local);
  }

  /// Yeni dizideki bir boncuğun ölçeği: 0'dan 1'e.
  double _inScale(int index, int count) {
    final begin = _inStart + _offset(index, count, _inStagger);
    final local = ((progress - begin) / _inSpan).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(local);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Bugünün hâlesi kenara taşmasın.
    final radius = math.min(size.width, size.height) / 2 - 15;

    _paintGlow(canvas, center, radius);
    _paintTrack(canvas, center, radius);

    // Sönen eski dizi.
    _paintBeads(
      canvas,
      center: center,
      radius: radius,
      data: from,
      scaleOf: (i) => _outScale(i, from.length),
    );

    // Yanan yeni dizi.
    _paintBeads(
      canvas,
      center: center,
      radius: radius,
      data: to,
      scaleOf: (i) => _inScale(i, to.length),
    );
  }

  /// Merkezin arkasındaki ışıma: gül → kehribar → menekşe, yumuşak kenarlı.
  void _paintGlow(Canvas canvas, Offset center, double radius) {
    final r = radius - 14;
    if (r <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: r);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glow[0].withAlpha(150),
            glow[1].withAlpha(110),
            glow[2].withAlpha(150),
          ],
        ).createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  /// Boncukların dizildiği kesik çizgili yörünge. Her parça altındaki günün
  /// renginde, çok soluk; dizi boşken alanın ne olduğunu gösteren tek şey.
  void _paintTrack(Canvas canvas, Offset center, double radius) {
    const dash = 3.0;
    const gap = 3.5;
    final circumference = 2 * math.pi * radius;
    final count = (circumference / (dash + gap)).floor();
    if (count <= 0) return;
    final step = 2 * math.pi / count;
    final sweep = step * dash / (dash + gap);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final n = to.length;

    for (var k = 0; k < count; k++) {
      final start = -math.pi / 2 + k * step;
      if (n > 0) {
        final i = ((k + 0.5) / count * n).floor().clamp(0, n - 1);
        paint.color = to.colors[i].withValues(alpha: 0.3);
      } else {
        paint.color = track;
      }
      canvas.drawArc(rect, start, sweep, false, paint);
    }
  }

  void _paintBeads(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required CycleRingData data,
    required double Function(int) scaleOf,
  }) {
    final n = data.length;
    if (n <= 0) return;

    // Boncuk boyu dilime göre: uzun döngüde (ya da 40 haftada) komşular
    // birbirine değmesin.
    final slot = 2 * math.pi * radius / n;
    final bead = math.min(4.4, slot * 0.3);
    final today = data.todayIndex;

    for (var i = 0; i < n; i++) {
      final scale = scaleOf(i);
      if (scale <= 0.01) continue;

      // Saat 12'den başla; boncuk dilimin ortasında dursun.
      final angle = -math.pi / 2 + (i + 0.5) * (2 * math.pi / n);
      final at = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final color = data.colors[i];

      if (i == today) {
        _paintToday(canvas, at, bead * scale, color);
        continue;
      }

      if (i == marker) {
        _paintMarker(canvas, at, bead * scale, color);
        continue;
      }

      if (today == null || i > today) {
        // Henüz yaşanmadı: içi açık halka. Tahmin edilen regl günleri
        // veride zaten bir ton açık (`flowSoft`).
        canvas.drawCircle(
          at,
          bead * scale,
          Paint()..color = Color.alphaBlend(color.withAlpha(40), surface),
        );
        canvas.drawCircle(
          at,
          math.max(bead * scale - 0.75, 0),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5 * scale,
        );
      } else {
        // Geçmiş: dolu; solukluk veride (bkz. `CycleRingData`).
        canvas.drawCircle(at, bead * scale, Paint()..color = color);
      }
    }
  }

  /// Bugün: yumuşak hâle, saydam halka, dolu boncuk, beyaz göbek.
  void _paintToday(Canvas canvas, Offset at, double bead, Color color) {
    canvas.drawCircle(
      at,
      bead * 3.2,
      Paint()
        ..color = color.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(at, bead * 2.15, Paint()..color = color.withAlpha(90));
    canvas.drawCircle(at, bead * 1.42, Paint()..color = color);
    canvas.drawCircle(at, bead * 0.55, Paint()..color = surface);
  }

  /// İşaretli gün: dışta ince halka, içte küçük dolu boncuk.
  void _paintMarker(Canvas canvas, Offset at, double bead, Color color) {
    canvas.drawCircle(
      at,
      bead * 1.3,
      Paint()..color = Color.alphaBlend(color.withAlpha(70), surface),
    );
    canvas.drawCircle(
      at,
      bead * 1.3,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(at, bead * 0.65, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BeadRingPainter old) =>
      old.progress != progress ||
      old.from != from ||
      old.to != to ||
      old.marker != marker ||
      old.track != track ||
      old.surface != surface ||
      old.glow[0] != glow[0] ||
      old.glow[1] != glow[1] ||
      old.glow[2] != glow[2];
}
