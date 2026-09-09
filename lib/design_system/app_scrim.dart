import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Fotoğraf, video ve kamera görüntüsü üzerindeki katman renkleri.
///
/// Bunlar **bilerek** temayla değişmiyor: altlarındaki görüntü temayı takip
/// etmiyor. Bir yemek fotoğrafının üstündeki başlık koyu temada da açık
/// kalmalı, çünkü fotoğraf her iki temada da aynı fotoğraf.
///
/// Ekranlarda ham `Colors.white` / `Colors.black` yazmak yerine buradan
/// okunuyor; böylece "bu renk neden sabit?" sorusunun cevabı kodun içinde
/// duruyor ve sabit renk denetimi ekranları taramaya devam edebiliyor.
class AppScrim {
  const AppScrim._();

  /// Görüntü üzerindeki metin ve ikon.
  static const Color ink = Colors.white;

  /// Görüntü üzerindeki ikincil metin.
  static const Color inkMuted = Color(0xB3FFFFFF);

  /// Görüntüyü karartan katman. [alpha] 0-255.
  static Color veil(int alpha) => Color.fromARGB(alpha, 0, 0, 0);

  /// Görüntü üzerinde duran açık renkli denetim yüzeyi. [alpha] 0-255.
  static Color frost(int alpha) => Color.fromARGB(alpha, 255, 255, 255);

  /// Yükselti gölgesi. Gölge her temada siyahtır; değişen yalnızca opaklık.
  static List<BoxShadow> lift({
    double blurRadius = 10,
    Offset offset = const Offset(0, 4),
    int alpha = 26,
  }) => [BoxShadow(color: veil(alpha), blurRadius: blurRadius, offset: offset)];

  /// Kamera görüntüsünün ardındaki zemin.
  static const Color cameraBackground = AppPalette.ink900;
}
