import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_tokens.dart';

/// Ana ekran widget'ı (Swift) uygulamanın renklerini kullanıyor mu?
///
/// Widget ayrı bir süreç ve renkleri `CycleWidget.swift` içinde sabit
/// yazılı. Ekim 2026 tasarım yenilemesinde palet değişti ama widget eski
/// tonlarda kaldı — hiçbir test ikisini bağlamıyordu. Bu test bağlıyor:
/// her renk anahtarının açık ve koyu değeri uygulamanın rol rengiyle aynı.
void main() {
  final swift = File('ios/CycleWidget/CycleWidget.swift').readAsStringSync();

  /// `case "key": return rgb(dark ? 0xDARK : 0xLIGHT)` satırlarını okur.
  (int, int) hexes(String key) {
    final m = RegExp(
      '"$key"[^\\n]*\\n?\\s*return rgb\\(dark \\? 0x([0-9A-Fa-f]{6}) : '
      '0x([0-9A-Fa-f]{6})\\)',
    ).firstMatch(swift);
    expect(m, isNotNull, reason: '$key Swift\'te bulunamadı');
    return (
      int.parse(m!.group(1)!, radix: 16),
      int.parse(m.group(2)!, radix: 16),
    );
  }

  int rgb(Color c) => c.toARGB32() & 0xFFFFFF;

  final light = AppTokens.light;
  final dark = AppTokens.dark;
  final cases = <String, (Color, Color)>{
    'menstruation': (light.flow, dark.flow),
    'follicular': (light.phaseFollicular, dark.phaseFollicular),
    'ovulation': (light.ovulation, dark.ovulation),
    'luteal': (light.phaseLuteal, dark.phaseLuteal),
    'suppressed': (light.phaseSuppressed, dark.phaseSuppressed),
    'postpartum': (light.accent, dark.accent),
  };

  for (final c in cases.entries) {
    test('${c.key} paletle aynı', () {
      final (d, l) = hexes(c.key);
      expect(l, rgb(c.value.$1), reason: '${c.key} açık tema');
      expect(d, rgb(c.value.$2), reason: '${c.key} koyu tema');
    });
  }

  test('varsayılan renk marka rengi', () {
    final m = RegExp(
      r'default:\s*return rgb\(dark \? 0x([0-9A-Fa-f]{6}) : 0x([0-9A-Fa-f]{6})\)',
    ).firstMatch(swift)!;
    expect(int.parse(m.group(2)!, radix: 16), rgb(AppFlavor.plum.brand));
    expect(int.parse(m.group(1)!, radix: 16), rgb(AppFlavor.plum.brandDark));
  });
}
