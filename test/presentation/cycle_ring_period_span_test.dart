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
void main() {
  final tokens = AppTheme.light(AppFlavor.plum).extension<AppTokens>()!;

  int reglCicekSayisi(CycleInfo info, int bugun) {
    final data = CycleRingData.from(
      info: info,
      currentDay: bugun,
      tokens: tokens,
    );
    final renk = CyclePhase.menstruation.color(tokens);
    return data.colors
        .where(
          (c) =>
              c.toARGB32() == renk.toARGB32() ||
              c.toARGB32() == renk.withAlpha(80).toARGB32(),
        )
        .length;
  }

  test('devam eden regl beklenen süre kadar boyanır', () {
    final info = CycleInfo(
      averageCycleLength: 27,
      averagePeriodLength: 7, // kullanıcının ayarı
      lastPeriodStart: DateTime(2026, 9, 24),
      currentPeriodLength: 4, // bugüne kadar geçen
      currentPeriodEnd: null, // sürüyor
    );

    expect(reglCicekSayisi(info, 4), 7, reason: 'halka dörtte kesiliyor');
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
