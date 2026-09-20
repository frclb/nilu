import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_palette.dart';
import 'package:period_tracker/design_system/app_tokens.dart';

/// Açılış ekranı uygulamanın ilk karesine benzemeli.
///
/// Flutter'ın şablonu iki yer tutucu bırakmıştı: görsel 1x1 saydam bir
/// PNG'ydi (Xcode her derlemede "default placeholder icon" diye uyarıyordu)
/// ve zemin storyboard'a **sabit beyaz** yazılmıştı. Karanlık modda uygulama
/// önce beyaz patlayıp sonra koyuya geçiyordu.
///
/// Zemin iki yerde yazılı olduğu için — Dart paleti ve iOS varlık kataloğu —
/// biri değişip diğeri unutulabilir; derleme bunu fark etmez, kullanıcı ilk
/// açılışta yanıp sönen bir renk olarak görür. Burası ikisini karşılaştırıyor.
const _imageset = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';
const _colorset = 'ios/Runner/Assets.xcassets/LaunchBackground.colorset';
const _storyboard = 'ios/Runner/Base.lproj/LaunchScreen.storyboard';
const _generator = 'tool/generate_launch_image.py';

/// Varlık kataloğunun yazdığı biçim: `{"red": "0xFB", …}`.
Map<String, String> _asComponents(Color c) => {
      'red': _byte(c.r),
      'green': _byte(c.g),
      'blue': _byte(c.b),
    };

String _byte(double channel) =>
    '0x${(channel * 255).round().toRadixString(16).toUpperCase().padLeft(2, '0')}';

/// Katalogtaki renk girdisini okur. [dark] koyu görünüm varyantını seçer.
Map<String, String> _catalogColor({required bool dark}) {
  final json = jsonDecode(File('$_colorset/Contents.json').readAsStringSync())
      as Map<String, dynamic>;
  final entry = (json['colors'] as List).cast<Map<String, dynamic>>().firstWhere(
        (e) => (e['appearances'] != null) == dark,
      );
  final parts = (entry['color'] as Map)['components'] as Map<String, dynamic>;
  return {
    for (final k in ['red', 'green', 'blue']) k: parts[k] as String,
  };
}

/// PNG başlığındaki IHDR alanından ölçüyü okur — kod çözmeye gerek yok.
(int, int) _pngSize(String path) {
  final b = File(path).readAsBytesSync();
  int be32(int o) => (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
  return (be32(16), be32(20));
}

void main() {
  test('açılış zemini uygulamanın zeminiyle aynı', () {
    expect(
      _catalogColor(dark: false),
      _asComponents(AppTokens.light.background),
      reason: 'Açık temada açılış ekranı ilk kareden farklı renkte açılıyor. '
          '$_colorset güncellenmemiş — `python3 $_generator` çalıştırın.',
    );
    expect(
      _catalogColor(dark: true),
      _asComponents(AppTokens.dark.background),
      reason: 'Koyu temada açılış ekranı ilk kareden farklı renkte açılıyor.',
    );
  });

  test('zemin tema çeşidinden bağımsız, sabit açılış rengi meşru', () {
    // Açılış ekranı statik: kullanıcının hangi çeşidi seçtiğini bilemez.
    // Bu ancak zemin tüm çeşitlerde aynıysa doğru olur.
    for (final flavor in AppFlavor.values) {
      expect(AppTokens.of(flavor, Brightness.light).background,
          AppTokens.light.background,
          reason: '${flavor.name} açık temada zemini değiştiriyor: statik '
              'açılış ekranı bu çeşitte yanlış renkte kalır.');
      expect(AppTokens.of(flavor, Brightness.dark).background,
          AppTokens.dark.background,
          reason: '${flavor.name} koyu temada zemini değiştiriyor.');
    }
  });

  test('üretici betiğin renkleri paletle aynı', () {
    final src = File(_generator).readAsStringSync();

    Map<String, String> constant(String name) {
      final m = RegExp('$name = ' r'\((0x[0-9A-Fa-f]{2}), (0x[0-9A-Fa-f]{2}), (0x[0-9A-Fa-f]{2})\)')
          .firstMatch(src);
      expect(m, isNotNull, reason: '$_generator içinde $name bulunamadı.');
      // Yalnızca basamaklar büyütülüyor; `0x` öneki katalogdaki gibi kalmalı.
      String norm(String v) => '0x${v.substring(2).toUpperCase()}';
      return {
        'red': norm(m!.group(1)!),
        'green': norm(m.group(2)!),
        'blue': norm(m.group(3)!),
      };
    }

    // Betik Python, palet Dart: derleyici ikisini bağlamıyor, test bağlıyor.
    expect(constant('SAND_50'), _asComponents(AppPalette.sand50));
    expect(constant('NIGHT_900'), _asComponents(AppPalette.night900));
    expect(constant('PLUM_700'), _asComponents(AppPalette.plum700));
    expect(constant('PLUM_300'), _asComponents(AppPalette.plum300));
  });

  test('açılış görseli yer tutucu değil', () {
    final json = jsonDecode(File('$_imageset/Contents.json').readAsStringSync())
        as Map<String, dynamic>;
    final images = (json['images'] as List).cast<Map<String, dynamic>>();

    // Her ölçek, her görünüm için gerçek bir dosya: 1x/2x/3x × açık/koyu.
    expect(images, hasLength(6));

    for (final image in images) {
      final name = image['filename'] as String;
      final scale = int.parse((image['scale'] as String).replaceAll('x', ''));
      final file = '$_imageset/$name';
      expect(File(file).existsSync(), isTrue, reason: '$name eksik.');

      final (width, height) = _pngSize(file);
      expect(width, greaterThan(1),
          reason: '$name hâlâ 1x1 yer tutucu: açılış ekranı boş görünür.');
      expect(height, greaterThan(1), reason: '$name hâlâ 1x1 yer tutucu.');
      // Storyboard görseli doğal boyutunda ortalıyor; ölçekler tutmazsa
      // işaret cihazdan cihaza büyüyüp küçülür.
      expect(width, 120 * scale,
          reason: '$name ${scale}x için yanlış ölçekte.');
    }

    final dark = images.where((i) => i['appearances'] != null);
    expect(dark, hasLength(3),
        reason: 'Koyu görünüm varyantı eksik: koyu temada erik lotus '
            'gece zemininde kaybolur.');
  });

  test('storyboard zemini sabit yazmıyor', () {
    final src = File(_storyboard).readAsStringSync();

    expect(
      RegExp(r'key="backgroundColor"[^/>]*\bred=').hasMatch(src),
      isFalse,
      reason: 'Zemin storyboard\'a sabit yazılmış: koyu temayı takip etmez.',
    );
    expect(src, contains('key="backgroundColor" name="LaunchBackground"'));

    // Interface Builder'ın önizlemesi de yalan söylememeli.
    final preview = RegExp(
      r'<namedColor name="LaunchBackground">\s*<color red="([\d.]+)" green="([\d.]+)" blue="([\d.]+)"',
    ).firstMatch(src);
    expect(preview, isNotNull, reason: 'namedColor tanımı eksik.');
    final light = AppTokens.light.background;
    for (final (i, channel) in [light.r, light.g, light.b].indexed) {
      expect(double.parse(preview!.group(i + 1)!), closeTo(channel, 0.001),
          reason: 'Storyboard önizlemesi katalogtaki renkten farklı.');
    }
  });
}
