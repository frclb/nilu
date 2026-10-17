import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/design_system/app_palette.dart';

/// İkonun renkleri paletle aynı kalmalı.
///
/// Bir kez kaymıştı: `123301b` ("Tasarım sistemini yeniden kur: sıcak erik
/// paleti") marka rengini #551B26'dan `plum700`'e taşıdı ama ikon betiğine
/// dokunmadı. Uygulama yeni erikte, ana ekrandaki simge eski erikte kaldı ve
/// bunu kimse fark etmedi — çünkü ikon Python'da üretiliyor, palet Dart'ta
/// duruyor ve arada onları bağlayan hiçbir şey yoktu.
///
/// Burası iki bağı birden kuruyor:
///
/// * Betiğin sabitleri paletin sabitleriyle aynı mı,
/// * **üretilmiş PNG** gerçekten o renklerde mi — yani betik güncellenip
///   `python3 tool/generate_icon.py && dart run flutter_launcher_icons`
///   çalıştırılmayı unutmuş mu.
const _script = 'tool/generate_icon.py';
const _master = 'assets/icon/app_icon.png';
const _store =
    'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png';

/// Betikteki `NAME = (0x.., 0x.., 0x..)` üçlüsü.
(int, int, int) _constant(String src, String name) {
  final m = RegExp(
    '$name = '
    r'\((0x[0-9A-Fa-f]{2}), (0x[0-9A-Fa-f]{2}), (0x[0-9A-Fa-f]{2})\)',
  ).firstMatch(src);
  expect(m, isNotNull, reason: '$_script içinde $name bulunamadı.');
  return (
    int.parse(m!.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
  );
}

(int, int, int) _channels(Color c) =>
    ((c.r * 255).round(), (c.g * 255).round(), (c.b * 255).round());

String _hex((int, int, int) c) =>
    '#${c.$1.toRadixString(16).padLeft(2, '0')}'
            '${c.$2.toRadixString(16).padLeft(2, '0')}'
            '${c.$3.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();

Future<_Pixels> _pixels(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return _Pixels(data!.buffer.asUint8List(), image.width);
}

class _Pixels {
  _Pixels(this.bytes, this.width);
  final List<int> bytes;
  final int width;

  (int, int, int) at(int x, int y) {
    final i = (y * width + x) * 4;
    return (bytes[i], bytes[i + 1], bytes[i + 2]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ikon betiğinin renkleri paletle aynı', () {
    final src = File(_script).readAsStringSync();
    // Betik Python, palet Dart: derleyici ikisini bağlamıyor.
    expect(_constant(src, 'BG_TOP'), _channels(AppPalette.plum700));
    expect(_constant(src, 'BG_BOTTOM'), _channels(AppPalette.plum900));
    expect(_constant(src, 'PETAL'), _channels(AppPalette.rose50));
    expect(_constant(src, 'PETAL_SIDE'), _channels(AppPalette.plum300));
  });

  test('üretilmiş ikon betikle aynı renkte', () async {
    final src = File(_script).readAsStringSync();

    for (final path in [_master, _store]) {
      final px = await _pixels(path);
      expect(px.width, 1024, reason: '$path 1024 değil.');

      const regenerate =
          'python3 tool/generate_icon.py && '
          'dart run flutter_launcher_icons';

      // Yaprakların içi düz dolgu: 4x küçültmeden sonra da tam değer.
      expect(
        px.at(512, 560),
        _constant(src, 'PETAL'),
        reason:
            '$path merkez yaprağı ${_hex(px.at(512, 560))} — betik '
            'güncellenmiş ama ikon yeniden üretilmemiş. Çalıştırın: $regenerate',
      );
      expect(
        px.at(380, 600),
        _constant(src, 'PETAL_SIDE'),
        reason: '$path yan yaprağı ${_hex(px.at(380, 600))}. $regenerate',
      );

      // Degradenin uçları: kenarlarda yeniden örnekleme birkaç birim kaydırır.
      void near((int, int, int) got, (int, int, int) want, String where) {
        for (final (a, b) in [
          (got.$1, want.$1),
          (got.$2, want.$2),
          (got.$3, want.$3),
        ]) {
          expect(
            (a - b).abs(),
            lessThanOrEqualTo(3),
            reason:
                '$path $where ${_hex(got)}, beklenen ${_hex(want)}. '
                '$regenerate',
          );
        }
      }

      near(px.at(512, 2), _constant(src, 'BG_TOP'), 'zemin üstü');
      near(px.at(512, 1021), _constant(src, 'BG_BOTTOM'), 'zemin altı');
    }
  });

  test('mağaza ikonunda saydamlık yok', () {
    // App Store 1024'lük ikonu alfa kanalıyla reddediyor. PNG başlığındaki
    // renk tipi: 2 = RGB, 6 = RGBA.
    final colorType = File(_store).readAsBytesSync()[25];
    expect(
      colorType,
      isNot(6),
      reason: 'Mağaza ikonunda alfa kanalı var; yükleme reddedilir.',
    );
  });

  test('tüm iOS boyutları üretilmiş', () {
    final icons = Directory(
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    ).listSync().where((e) => e.path.endsWith('.png'));
    expect(icons, hasLength(21));
  });
}
