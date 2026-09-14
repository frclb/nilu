import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/design_system/app_contrast.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/design_system/app_tokens.dart';

/// WCAG göreli parlaklık — bağımsız hesap.
///
/// `Color.computeLuminance` kullanılmıyor: [AppContrast.on] da onu
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

Color _over(Color fg, int alpha, Color bg) {
  final t = alpha / 255.0;
  int mix(double f, double b) => (t * f + (1 - t) * b).round();
  return Color.fromARGB(
    255,
    mix(fg.r * 255, bg.r * 255),
    mix(fg.g * 255, bg.g * 255),
    mix(fg.b * 255, bg.b * 255),
  );
}

/// Kontrast, uygulamanın **gerçekten kurduğu** tema üzerinden ölçülüyor.
///
/// Önce değerler tek tek elle okunuyordu: `AppSnack.background(...)`,
/// `AppTokens.light`… Tema kurulamıyordu çünkü yazı tipleri çalışma anında
/// indiriliyordu ve test ortamında ağ yok. Yazı tipleri pakete gömülünce bu
/// engel kalktı.
///
/// Fark önemli: eskisi tasarım sabitlerinin birbirine göre doğru olduğunu
/// gösteriyordu, bu ise **ekrana giden** değerlerin doğru olduğunu. Aradaki
/// boşlukta tema kurucusunun sabitleri kullanmayı bırakması gibi bir
/// değişiklik fark edilmeden geçebilirdi.
///
/// Dört premium çeşidin hepsi taranıyor; marka rengi çeşide göre değişiyor
/// ve yalnızca varsayılanı ölçmek diğer üçünü kör noktada bırakırdı.
void main() {
  const textMinimum = 4.5;

  for (final flavor in AppFlavor.values) {
    for (final entry in {
      'açık': Brightness.light,
      'koyu': Brightness.dark,
    }.entries) {
      final label = '${flavor.name} · ${entry.key}';
      ThemeData build() => entry.value == Brightness.light
          ? AppTheme.light(flavor)
          : AppTheme.dark(flavor);

      group(label, () {
        test('bildirim metni okunur', () {
          final snack = build().snackBarTheme;
          expect(
            _contrast(snack.backgroundColor!, snack.contentTextStyle!.color!),
            greaterThanOrEqualTo(textMinimum),
            reason: '$label: gövde metni zeminden ayrışmıyor',
          );
        });

        test('geri alma bağlantısı okunur ve gövdeden ayrışır', () {
          final snack = build().snackBarTheme;
          expect(
            _contrast(snack.backgroundColor!, snack.actionTextColor!),
            greaterThanOrEqualTo(textMinimum),
            reason: '$label: geri alma zeminden ayrışmıyor',
          );
          expect(
            snack.actionTextColor,
            isNot(snack.contentTextStyle!.color),
            reason: '$label: geri alma gövde metniyle aynı renk',
          );
        });

        test('hata bildirimi okunur', () {
          // Regresyon: ön plan `estimateBrightnessForColor` ile seçiliyordu.
          // O metot WCAG eşiğine göre değil "hangisi hoş durur"a göre karar
          // veriyor; koyu temada kontrast 3.1'e düşmüştü.
          final t = build().extension<AppTokens>()!;
          expect(
            _contrast(t.danger, AppContrast.on(t.danger)),
            greaterThanOrEqualTo(textMinimum),
            reason: '$label: hata metni uyarı zemininde okunmuyor',
          );
        });

        test('dolu düğmenin yazısı okunur', () {
          // Uygulamadaki bütün dolu düğmeler bu çifti kullanıyor. Sabit
          // renkler token'lara taşınırken çok sayıda `Colors.white`
          // `onPrimary`ye çevrildi ama premium çeşitlerde hiç ölçülmemişti.
          final scheme = build().colorScheme;
          expect(
            _contrast(scheme.primary, scheme.onPrimary),
            greaterThanOrEqualTo(textMinimum),
            reason: '$label: düğme yazısı marka renginde okunmuyor',
          );
        });

        test('tahmin bandı zeminden seçiliyor', () {
          // Eşik tema başına ayrı: beyaz zeminde pembe hem parlaklıkta hem
          // renkte ayrışıyor ve 1.20'de rahat görünüyor; koyu zeminde ikisi
          // de sıkıştığı için aynı sayı görünmezliğe denk geliyor. Bunlar
          // birer **taban** — mevcut değerin altına düşmeyi engelliyor,
          // WCAG'ın 3:1'ini karşıladıkları iddiası değil.
          final t = build().extension<AppTokens>()!;
          final isLight = entry.value == Brightness.light;
          final alpha = isLight ? 90 : 100;
          final floor = isLight ? 1.40 : 1.45;
          expect(
            _contrast(_over(t.flowSoft, alpha, t.surface), t.surface),
            greaterThanOrEqualTo(floor),
            reason: '$label: tahmin bandı zeminden ayrışmıyor',
          );
        });

        test('tül token\'ları zemine yakın; işaret olarak kullanılamaz', () {
          final t = build().extension<AppTokens>()!;
          for (final tint in {
            'flowTint': t.flowTint,
            'ovulationTint': t.ovulationTint,
            'accentTint': t.accentTint,
          }.entries) {
            expect(
              _contrast(tint.value, t.surface),
              lessThan(2.0),
              reason:
                  '$label · ${tint.key} zeminden ayrışıyorsa artık tül '
                  'değildir; işaret token\'ı olarak yeniden düşünülmeli',
            );
          }
        });
      });
    }
  }

  test('doğurganlık işareti koyu temada görünür', () {
    // Açık temada `fertile` ile `flowTint` aynı tonu paylaşıyor; ayrım
    // değerde değil rolde. Koyu temada ayrışıyorlar ve kaybolan da buydu:
    // tül 1.25:1'e düşerken işaretin görünmesi gerekiyor.
    final t = AppTheme.dark(AppFlavor.plum).extension<AppTokens>()!;
    expect(
      _contrast(t.fertile, t.surface),
      greaterThan(3.0),
      reason: 'koyu temada doğurganlık noktası zeminden ayrışmıyor',
    );
    expect(t.fertile, isNot(t.flowTint));
  });
}
