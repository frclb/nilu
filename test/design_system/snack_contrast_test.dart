import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/design_system/app_snack.dart';
import 'package:period_tracker/design_system/app_tokens.dart';

/// WCAG göreli parlaklık — bağımsız hesap.
///
/// `Color.computeLuminance` kullanılmıyor: [AppSnack.readableOn] de onu
/// kullanıyor, aynı hesabı iki yerde kullanmak testi kör ederdi.
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

/// Bildirimler uygulamanın tek geri bildirim kanalı; içindeki metin de geri
/// alma bağlantısı da her iki temada okunmalı.
void main() {
  const minimum = 4.5;

  for (final entry in {
    'açık': Brightness.light,
    'koyu': Brightness.dark,
  }.entries) {
    final label = entry.key;
    final brightness = entry.value;
    final background = AppSnack.background(brightness);
    final tokens = brightness == Brightness.light
        ? AppTokens.light
        : AppTokens.dark;

    test('$label temada bildirim metni okunur', () {
      expect(
        _contrast(background, AppSnack.foreground),
        greaterThanOrEqualTo(minimum),
        reason: '$label: gövde metni zeminden ayrışmıyor',
      );
    });

    test('$label temada geri alma bağlantısı okunur ve ayrışır', () {
      expect(
        _contrast(background, AppSnack.actionForeground),
        greaterThanOrEqualTo(minimum),
        reason: '$label: geri alma zeminden ayrışmıyor',
      );
      expect(
        AppSnack.actionForeground,
        isNot(AppSnack.foreground),
        reason: '$label: geri alma gövde metniyle aynı renk',
      );
    });

    test('$label temada hata bildirimi okunur', () {
      // Regresyon: ön plan `estimateBrightnessForColor` ile seçiliyordu. O
      // metot WCAG eşiğine göre değil "hangisi hoş durur"a göre karar
      // veriyor; koyu temada kontrast 3.1'e düşmüştü.
      expect(
        _contrast(tokens.danger, AppSnack.readableOn(tokens.danger)),
        greaterThanOrEqualTo(minimum),
        reason: '$label: hata metni uyarı zemininde okunmuyor',
      );
    });
  }
}
