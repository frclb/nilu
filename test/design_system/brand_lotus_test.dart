import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/design_system/brand_lotus.dart';

/// Dart'taki lotus, Python'daki lotusla aynı çiçek mi?
///
/// Şekil `tool/lotus.py` içinde tanımlı; ikon ve açılış ekranı oradan
/// üretiliyor. [BrandLotus] aynı eğrilerin Dart karşılığı — yani geometri
/// iki dilde iki kez yazılı. Derleyici bu ikisini bağlamıyor: biri
/// değiştirilip diğeri unutulursa uygulama içindeki çiçek ile ana ekrandaki
/// simge sessizce ayrışır.
///
/// Bu test ikisini **piksel piksel** karşılaştırıyor: Dart çizimi, üretilmiş
/// açılış görselinin şeklini tutturmalı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const reference =
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png';

  testWidgets('yalnızca genişlik verildiğinde de çiziliyor', (tester) async {
    // `CustomPaint`'in doğal boyutu yok. Çiçek yalnızca genişliği sınırlı bir
    // yere konduğunda sıfır yükseklikte çizilip görünmez oluyordu — onboarding
    // başarı ekranında dairenin içi bomboş kaldı ve hiçbir hata çıkmadı.
    final key = GlobalKey();
    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: const SizedBox(
            width: 200,
            // Yükseklik bilerek verilmiyor: kritik durum bu.
            child: BrandLotus(color: Color(0xFF000000)),
          ),
        ),
      ),
    );
    await tester.pump();

    late int painted;
    late Size size;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      size = boundary.size;
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      painted = 0;
      for (var i = 3; i < bytes.length; i += 4) {
        if (bytes[i] > 40) painted++;
      }
    });

    expect(
      size.height,
      greaterThan(0),
      reason: 'Çiçek yüksekliksiz kaldı: kutusuna sığmıyor.',
    );
    expect(
      painted,
      greaterThan(1000),
      reason: 'Çiçek hiç çizilmedi ($painted piksel).',
    );
  });

  testWidgets('Dart çizimi üretilmiş görselle örtüşüyor', (tester) async {
    final key = GlobalKey();

    // Referans görselin alfa maskesi.
    late List<int> want;
    late int width;
    late int height;
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(
        File(reference).readAsBytesSync(),
      );
      final image = (await codec.getNextFrame()).image;
      width = image.width;
      height = image.height;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      want = [for (var i = 3; i < bytes.length; i += 4) bytes[i]];
    });

    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: width.toDouble(),
            height: height.toDouble(),
            // Referans tek renk + yan yapraklarda %75 saydamlık ile üretiliyor.
            child: const BrandLotus(color: Color(0xFF000000)),
          ),
        ),
      ),
    );
    await tester.pump();

    late List<int> got;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = data!.buffer.asUint8List();
      got = [for (var i = 3; i < bytes.length; i += 4) bytes[i]];
    });

    expect(got, hasLength(want.length), reason: 'ölçüler tutmuyor');

    // Kesişim / birleşim: şekil aynı yerde mi?
    var intersection = 0;
    var union = 0;
    var diff = 0;
    for (var i = 0; i < want.length; i++) {
      final a = want[i] > 40;
      final b = got[i] > 40;
      if (a && b) intersection++;
      if (a || b) union++;
      diff += (want[i] - got[i]).abs();
    }
    final iou = intersection / union;
    final meanDiff = diff / want.length;

    expect(
      iou,
      greaterThan(0.97),
      reason:
          'Şekiller örtüşmüyor (IoU ${iou.toStringAsFixed(3)}): '
          'tool/lotus.py ile brand_lotus.dart ayrışmış. Birini '
          'değiştirdiyseniz diğerini de güncelleyin.',
    );

    // Yan yaprakların saydamlığı da tutmalı; yalnızca siluet değil.
    expect(
      meanDiff,
      lessThan(12),
      reason:
          'Yaprak tonları ayrışmış (ortalama alfa farkı '
          '${meanDiff.toStringAsFixed(1)}).',
    );
  });
}
