import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Bir zemin üzerinde okunabilir mürekkep rengi.
class AppContrast {
  const AppContrast._();

  /// İki renk arasındaki WCAG kontrast oranı.
  static double ratio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// [background] üzerinde okunan metin/ikon rengi.
  ///
  /// Flutter'ın `estimateBrightnessForColor` metodu "hangisi hoş durur"a göre
  /// karar veriyor, WCAG eşiğine göre değil: koyu temanın uyarı rengini koyu
  /// sayıp açık metin seçiyor ve kontrast 3.1'e düşüyordu. Burada iki aday
  /// ölçülüp kazanan seçiliyor.
  ///
  /// Sabit bir `Colors.white` yerine bunu kullanmak gerekiyor çünkü aynı rol
  /// rengi iki temada farklı parlaklıkta: akış rengi açık temada koyu pembe,
  /// koyu temada açık pembe. Beyaz metin ikisinde birden okunmuyor.
  static Color on(Color background) =>
      ratio(background, AppPalette.sand50) >=
          ratio(background, AppPalette.ink900)
      ? AppPalette.sand50
      : AppPalette.ink900;
}
