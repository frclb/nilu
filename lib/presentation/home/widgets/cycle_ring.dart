import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../design_system/app_tokens.dart';
import '../../../design_system/phase_colors.dart';
import '../../../domain/models/cycle_info.dart';
import '../../../localization/app_localizations.dart';

/// Döngüyü halka olarak çizer: her gün bir yay parçası.
///
/// Halkanın içinde gün sayısı **yok**. Bu kategorideki uygulamalarda merkezdeki
/// sayı tek başına duruyor ve okumak için onun bir döngü günü olduğunu bilmek
/// gerekiyor. Burada cevabı üstteki cümle veriyor; halka yalnızca döngünün
/// şeklini gösteriyor — evrelerin nerede başlayıp bittiğini ve bugünün o yay
/// üzerindeki yerini.
class CycleRing extends StatelessWidget {
  const CycleRing({
    super.key,
    required this.info,
    required this.currentDay,
    required this.center,
  });

  final CycleInfo info;
  final int currentDay;

  /// Halkanın ortasında duran içerik.
  ///
  /// Başlık ve halka önce ayrı bloklardı; ikisi ayrı ayrı dikkat çekiyor ve
  /// aradaki boşluk kartı seyrek gösteriyordu. Tek bir odak nesnesi olarak
  /// daha derli toplu duruyor.
  final Widget center;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final theme = Theme.of(context);
    final expected = info.averageCycleLength;

    // Regl gecikirse döngü tahmin edilen uzunluğu aşıyor. Halka yalnızca
    // beklenen uzunlukta çizilseydi bugüne denk gelen parça olmaz, işaret
    // kaybolur ve bütün günler "geçmiş" sayılıp halka tamamen solardı.
    // Halka bugüne kadar uzuyor; beklenenin ötesindeki günler nötr renkte,
    // böylece gecikme halkanın kendisinden okunuyor.
    final length = math.max(expected, currentDay);

    // Renkler boyayıcıya girmeden hesaplanıyor: bir kapanış geçirilseydi
    // `shouldRepaint` onu karşılaştıramaz ve evre renkleri değişip gün sayısı
    // aynı kaldığında halka yeniden çizilmezdi.
    final colors = [
      for (var day = 1; day <= length; day++)
        if (day > expected) t.textFaint else info.getPhaseForDay(day).color(t),
    ];

    final phaseColor = info.currentPhase.color(t);

    return Center(
      child: SizedBox(
        width: 232,
        height: 232,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Evre renginde çok hafif bir hâle: halka düz zeminde yüzer gibi
            // duruyordu, bu onu yere oturtuyor.
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [phaseColor.withAlpha(20), phaseColor.withAlpha(0)],
                ),
              ),
            ),
            CustomPaint(
              size: const Size.square(232),
              painter: _RingPainter(
                colors: colors,
                currentDay: currentDay,
                track: t.border,
                core: t.surface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  center,
                  const SizedBox(height: 6),
                  Text(
                    context.tr(
                      'home_ring_cycle_length',
                      params: {'n': '$expected'},
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
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.colors,
    required this.currentDay,
    required this.track,
    required this.core,
  });

  final List<Color> colors;
  final int currentDay;

  /// Parçaların altındaki ince iz: halka soluk günlerde de tam bir daire
  /// olarak okunsun.
  final Color track;

  /// Papatyaların göbek rengi — kartın yüzeyiyle aynı.
  final Color core;

  int get length => colors.length;

  @override
  void paint(Canvas canvas, Size size) {
    if (length <= 0) return;

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

    final sweep = 2 * math.pi / length;

    // Her gün bir papatya. Boyut, iki komşu çiçek değmeyecek şekilde
    // yaydan türetiliyor: döngü uzadıkça çiçekler küçülüyor.
    final slot = 2 * math.pi * radius / length;

    // Taban boyut, bugünün büyütülmüş çiçeğine yer kalacak şekilde
    // hesaplanıyor. İki komşu merkez arası `slot` kadar; bugünün yarıçapı ile
    // komşusunun yarıçapının toplamı bunun altında kalmalı.
    //
    //   base/2 * todayScale + base/2 <= slot * clearance
    //
    // Önceden taban `slot * 0.92` ve büyütme 1.45'ti; toplam yarıçap slot'u
    // aşıyor ve bugünün çiçeği iki komşusuna değiyordu.
    const todayScale = 1.28;
    const clearance = 0.94;
    final petalSize = math.min(slot * 2 * clearance / (todayScale + 1), 20.0);

    for (var day = 1; day <= length; day++) {
      final isToday = day == currentDay;
      final isPast = day < currentDay;
      final color = colors[day - 1];

      // Saat 12'den başla.
      final angle = -math.pi / 2 + (day - 1) * sweep + sweep / 2;

      // Bugünün çiçeği bir tık dışarıda duruyor. Açısal aralık sabit
      // olduğundan dışa çıkmak komşularla arayı açıyor; ayrıca çelengin
      // üzerinde hafifçe kabarmış gibi görünüyor.
      final r = isToday ? radius + petalSize * 0.22 : radius;
      final at = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );

      if (isToday) {
        // Yumuşak bir hâle: bugünü büyütmeye fazla yüklenmeden ayırıyor.
        canvas.drawCircle(
          at,
          petalSize * 0.95,
          Paint()..color = color.withAlpha(38),
        );
      }

      _drawDaisy(
        canvas,
        at: at,
        size: isToday ? petalSize * todayScale : petalSize,
        // Geçmiş günler soluk: bakış bugüne ve önündeki yola gitsin.
        petal: isPast ? color.withAlpha(80) : color,
        // Papatyanın göbeği kartın yüzey rengi. Sarı bir göbek palete yeni
        // bir renk sokardı; boşluk bırakmak çiçeği yine papatya gibi okutuyor.
        core: isPast ? core.withAlpha(150) : core,
        // Bugünün çiçeği hem büyük hem tam açık; ayrıca dışına işaret
        // koymaya gerek kalmıyor.
        petals: 8,
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
  bool shouldRepaint(_RingPainter old) =>
      old.currentDay != currentDay ||
      old.track != track ||
      old.core != core ||
      !listEquals(old.colors, colors);
}
