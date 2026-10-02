import 'package:flutter/material.dart';

import '../../design_system/app_tokens.dart';
import '../../domain/models/pregnancy.dart';
import '../home/widgets/cycle_ring_data.dart';

/// Gebelik panosundaki çelengin verisi: her çiçek bir hafta.
///
/// Yeni bir çizim yazmak yerine döngü çelengi (`CycleRing`) kullanılıyor:
/// marka dili korunuyor ve canlandırma, solukluk, "bugün" vurgusu gibi
/// zaten test edilmiş davranışlar bedavaya geliyor.
class PregnancyRing {
  const PregnancyRing._();

  static const int weeks = 40;

  /// Trimester renkleri. Kan (`flow`) ve uyarı tonlarından bilerek
  /// kaçınılıyor: gebelik ekranında kırmızıya kayan bir çiçek kanama ya da
  /// tehlike çağrıştırırdı.
  static List<Color> trimesterColors(AppTokens t) => [
    t.accent,
    t.phaseFollicular,
    t.ovulation,
  ];

  static CycleRingData data(
    Pregnancy pregnancy, {
    required DateTime today,
    required AppTokens tokens,
  }) {
    final ga = pregnancy.gestationOn(today);
    // Tamamlanan hafta sayısı = içinde bulunulan haftanın sırası (0 tabanlı).
    final suanki = ga?.weeks;
    final uzunluk = suanki != null && suanki >= weeks ? suanki + 1 : weeks;
    final renkler = trimesterColors(tokens);

    Color renk(int i) {
      // 40. haftadan sonrası nötr: gecikme çelengin kendisinden okunuyor
      // (döngü çelengindeki gecikmiş regl gibi).
      final temel = i >= weeks
          ? tokens.textFaint
          : renkler[i < 14
                ? 0
                : i < 28
                ? 1
                : 2];
      return suanki != null && i < suanki ? temel.withAlpha(80) : temel;
    }

    return CycleRingData(
      colors: [for (var i = 0; i < uzunluk; i++) renk(i)],
      todayIndex: suanki,
      expected: weeks,
    );
  }
}
