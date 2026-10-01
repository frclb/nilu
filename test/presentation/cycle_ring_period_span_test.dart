import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/design_system/app_tokens.dart';
import 'package:period_tracker/design_system/phase_colors.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_ring_data.dart';

/// Çelenkteki regl çiçeklerinin kaç gün kapladığı.
///
/// Halka bir tahmin görseli: yumurtlamayı ve luteal fazı ileriye doğru
/// boyuyor. Devam eden reglin kalan günlerini boyamayıp diğer her şeyi
/// boyamak, aynı veriden iki farklı cevap vermek demekti — kullanıcı yedi
/// gün seçtiğinde takvim yedi gün gösterirken halka dördüncü çiçekte
/// kesiliyordu.
///
/// Regl çiçekleri artık **iki tonda**: yaşanmış günler dolu (`flow`), süren
/// reglin henüz gelmemiş günleri yumuşak (`flowSoft`) — takvimdeki
/// kayıt/tahmin ayrımının karşılığı. Buradaki sayım toplam **kapsamı**
/// ölçüyor, yani iki tonu birlikte; ayrım ayrıca sınanıyor
/// (bkz. `ring_predicted_color_test`).
void main() {
  final tokens = AppTheme.light(AppFlavor.plum).extension<AppTokens>()!;

  /// Verilen tondaki (ve onun soluk hâlindeki) çiçek sayısı.
  int tonSayisi(CycleInfo info, int bugun, Color ton) {
    final data = CycleRingData.from(
      info: info,
      currentDay: bugun,
      tokens: tokens,
    );
    return data.colors
        .where(
          (c) =>
              c.toARGB32() == ton.toARGB32() ||
              c.toARGB32() == ton.withAlpha(80).toARGB32(),
        )
        .length;
  }

  /// Toplam regl kapsamı: yaşanmış + tahmin edilen.
  int reglCicekSayisi(CycleInfo info, int bugun) =>
      tonSayisi(info, bugun, CyclePhase.menstruation.color(tokens)) +
      tonSayisi(info, bugun, tokens.flowSoft);

  test('devam eden regl beklenen süre kadar boyanır', () {
    final info = CycleInfo(
      averageCycleLength: 27,
      averagePeriodLength: 7, // kullanıcının ayarı
      lastPeriodStart: DateTime(2026, 9, 24),
      currentPeriodLength: 4, // bugüne kadar geçen
      currentPeriodEnd: null, // sürüyor
    );

    expect(reglCicekSayisi(info, 4), 7, reason: 'halka dörtte kesiliyor');

    // Kapsam yedi gün ama dördü yaşanmış, üçü tahmin. Yalnızca toplamı
    // sınamak, her günü dolu renge boyayan bir sürümü de geçirirdi.
    expect(
      tonSayisi(info, 4, CyclePhase.menstruation.color(tokens)),
      4,
      reason: 'yaşanmış gün sayısı kadar dolu çiçek olmalı',
    );
    expect(
      tonSayisi(info, 4, tokens.flowSoft),
      3,
      reason: 'kalan üç gün henüz yaşanmadı — takvim de onları tül çiziyor',
    );
  });

  test('regl uzarsa çiçekler de uzar', () {
    // Kullanıcı yedinci günden sonra da işaretlemeye devam etti.
    final info = CycleInfo(
      averageCycleLength: 27,
      averagePeriodLength: 7,
      lastPeriodStart: DateTime(2026, 9, 24),
      currentPeriodLength: 9,
      currentPeriodEnd: null,
    );

    expect(reglCicekSayisi(info, 9), 9);
  });

  test('dönem kapandıysa kayıt kesindir', () {
    // "Reglim bitti"ye üçüncü gün basıldı; yedi çiçek göstermek yanlış olur.
    final info = CycleInfo(
      averageCycleLength: 27,
      averagePeriodLength: 7,
      lastPeriodStart: DateTime(2026, 9, 24),
      currentPeriodLength: 3,
      currentPeriodEnd: DateTime(2026, 9, 26),
    );

    expect(reglCicekSayisi(info, 4), 3);
  });

  test('kayıt yoksa ortalamaya düşülür', () {
    final info = CycleInfo(
      averageCycleLength: 27,
      averagePeriodLength: 5,
      lastPeriodStart: DateTime(2026, 9, 24),
    );

    expect(reglCicekSayisi(info, 4), 5);
  });
}
