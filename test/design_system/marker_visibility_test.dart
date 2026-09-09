import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/design_system/app_tokens.dart';

double _luminance(Color c) {
  double channel(double v) {
    final s = v / 255.0;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4) as double;
  }

  return 0.2126 * channel(c.r * 255) +
      0.7152 * channel(c.g * 255) +
      0.0722 * channel(c.b * 255);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Tül token'ları (`*Tint`) hücrenin **altına** serilen zeminler; işaret
/// olarak kullanılamazlar.
///
/// Takvim açıklamasındaki doğurganlık noktası bir göç sırasında `flowTint`e
/// bağlanmıştı. Koyu temada o ton zeminle 1.25:1 kalıyor — nokta kayboluyor,
/// üstelik açıklama ile takvimin boyadığı renk de ayrışıyor.
void main() {
  test('tül token'
      "'"
      'ları zemine yakın; işaret olarak kullanılamaz', () {
    for (final entry in {
      'açık': AppTokens.light,
      'koyu': AppTokens.dark,
    }.entries) {
      final t = entry.value;
      for (final tint in {
        'flowTint': t.flowTint,
        'ovulationTint': t.ovulationTint,
        'accentTint': t.accentTint,
      }.entries) {
        expect(
          _contrast(tint.value, t.surface),
          lessThan(2.0),
          reason:
              '${entry.key} · ${tint.key} zeminden ayrışıyorsa artık tül '
              'değildir; işaret token'
              "'"
              'u olarak yeniden düşünülmeli',
        );
      }
    }
  });

  test('takvim açıklaması işaret için tül kullanmıyor', () {
    final source = File(
      'lib/presentation/calendar/widgets/calendar_grid.dart',
    ).readAsStringSync();

    final calls = RegExp(
      r'_buildLegendItem\(([^;]*?)\),\s*\n',
      multiLine: true,
    ).allMatches(source).map((m) => m.group(1)!).toList();

    expect(calls, isNotEmpty, reason: 'açıklama çağrıları bulunamadı');
    for (final call in calls) {
      expect(
        call.contains('Tint'),
        isFalse,
        reason: 'açıklama noktası zemin tülü kullanıyor: ${call.trim()}',
      );
    }
  });

  test('doğurganlık işareti koyu temada görünür', () {
    // Açık temada `fertile` ile `flowTint` aynı tonu paylaşıyor; ayrım
    // değerde değil rolde. Koyu temada ise ayrışıyorlar ve kaybolan da
    // buydu: tül 1.25:1'e düşerken işaretin görünmesi gerekiyor.
    expect(
      _contrast(AppTokens.dark.fertile, AppTokens.dark.surface),
      greaterThan(3.0),
      reason: 'koyu temada doğurganlık noktası zeminden ayrışmıyor',
    );
    expect(AppTokens.dark.fertile, isNot(AppTokens.dark.flowTint));
  });
}
