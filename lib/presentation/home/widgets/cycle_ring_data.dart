import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../design_system/app_tokens.dart';
import '../../../design_system/phase_colors.dart';
import '../../../domain/models/cycle_info.dart';

/// Halkanın çizilmesi için gereken her şey, tek bir değer olarak.
///
/// Renkler burada hesaplanıyor — boyayıcının içinde değil. İki sebebi var:
/// boyayıcı bir kapanış aldığında `shouldRepaint` onu karşılaştıramıyor, ve
/// iki durum arasında geçiş canlandırmak için "önceki" ile "sonraki"nin
/// karşılaştırılabilir birer değer olması gerekiyor.
@immutable
class CycleRingData {
  /// Gün başına renk; sırayla 1. günden son güne. Geçmiş günlerin solukluğu
  /// da bu renklere işlenmiş durumda, böylece geçiş sırasında ayrıca
  /// hesaplanması gerekmiyor.
  final List<Color> colors;

  /// Bugünün dizideki sırası (0 tabanlı). Halka dışındaysa `null`.
  final int? todayIndex;

  /// Döngünün beklenen uzunluğu. Halka bundan uzun olabilir: regl gecikince
  /// döngü tahmin edilen günü aşıyor.
  final int expected;

  const CycleRingData({
    required this.colors,
    required this.todayIndex,
    required this.expected,
  });

  int get length => colors.length;

  /// Verilen döngü bilgisinden halka verisi üretir.
  factory CycleRingData.from({
    required CycleInfo info,
    required int currentDay,
    required AppTokens tokens,
  }) {
    final expected = info.averageCycleLength;

    // Regl gecikirse döngü beklenen uzunluğu aşıyor. Halka yalnızca beklenen
    // uzunlukta olsaydı bugüne denk gelen çiçek olmaz, işaret kaybolur ve
    // bütün günler "geçmiş" sayılıp çelenk tamamen solardı.
    final length = currentDay > expected ? currentDay : expected;

    return CycleRingData(
      colors: [
        for (var day = 1; day <= length; day++)
          _colorFor(day, expected, currentDay, info, tokens),
      ],
      todayIndex: currentDay >= 1 && currentDay <= length
          ? currentDay - 1
          : null,
      expected: expected,
    );
  }

  static Color _colorFor(
    int day,
    int expected,
    int currentDay,
    CycleInfo info,
    AppTokens tokens,
  ) {
    // Beklenen uzunluğun ötesi nötr: gecikme çelengin kendisinden okunuyor.
    final base = day > expected
        ? tokens.textFaint
        : info.getPhaseForDay(day).color(tokens);

    // Geçmiş günler soluk: bakış bugüne ve önündeki yola gitsin.
    return day < currentDay ? base.withAlpha(80) : base;
  }

  /// Beklenen uzunluğa kırpılmış hâli.
  ///
  /// Uygulama, döngü çoktan uzamışken açıldığında geçişin nereden başlayacağı
  /// buradan geliyor: önce tahmin edilen çelenk, sonra bugüne kadar uzayan
  /// hâli.
  CycleRingData clampedToExpected() {
    if (length <= expected) return this;
    return CycleRingData(
      colors: colors.take(expected).toList(),
      todayIndex: null,
      expected: expected,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CycleRingData &&
      other.todayIndex == todayIndex &&
      other.expected == expected &&
      listEquals(other.colors, colors);

  @override
  int get hashCode => Object.hash(todayIndex, expected, Object.hashAll(colors));
}
