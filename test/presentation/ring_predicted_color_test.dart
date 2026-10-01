import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_theme.dart';
import 'package:period_tracker/design_system/app_tokens.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';
import 'package:period_tracker/presentation/home/widgets/cycle_ring_data.dart';

/// Çelenk, tahmin ayrımını gerçekten **boyuyor** mu?
///
/// `ring_predicted_period_test` kuralın kendisini sınıyor
/// (`isPredictedPeriodRingDay`). Kuralı sınamak onun uygulandığını
/// sınamak değil: bu oturumda iki test tam bu yüzden boşa geçmişti —
/// model doğru cevabı veriyordu ama ekran onu kullanmıyordu.
void main() {
  final bugun = DateTime(2026, 9, 27);

  late AppTokens tokens;

  setUpAll(() {
    tokens = AppTheme.light(AppFlavor.plum).extension<AppTokens>()!;
  });

  CycleRingData halka({
    required int kayitli,
    int planlanan = 7,
    bool bitti = false,
  }) {
    final start = DateTime(2026, 9, 27 - (kayitli - 1));
    final info = PredictionService().getCycleInfo(
      [PeriodLog(id: 'p', startDate: start, endDate: bitti ? bugun : null)],
      userCycleLength: 28,
      userPeriodLength: planlanan,
      today: bugun,
    );
    return CycleRingData.from(
      info: info,
      currentDay: info.cycleDayOn(bugun) ?? 0,
      tokens: tokens,
    );
  }

  test('yaşanmış ve tahmin edilen regl günleri farklı renkte', () {
    final data = halka(kayitli: 3, planlanan: 7);

    // Bugün (3. gün) yaşanmış: dolu regl rengi.
    expect(
      data.colors[2],
      tokens.flow,
      reason: 'Kayıtlı gün takvimdekiyle aynı dolu renk olmalı',
    );

    // 4–7. günler henüz yaşanmadı.
    for (var gun = 4; gun <= 7; gun++) {
      expect(
        data.colors[gun - 1],
        tokens.flowSoft,
        reason:
            '$gun. gün henüz yaşanmadı; takvim onu tül ile çiziyor. Çelenk '
            'dolu renk kullanırsa kullanıcı planladığı günleri olmuş sanır.',
      );
    }

    expect(
      data.colors[2],
      isNot(data.colors[3]),
      reason: 'Yaşanmış ile tahmin aynı renkse ayrım kullanıcıya ulaşmaz',
    );
  });

  test('regl bitirilince tahmin rengi kalmıyor', () {
    final data = halka(kayitli: 3, planlanan: 7, bitti: true);

    for (final renk in data.colors) {
      expect(
        renk,
        isNot(tokens.flowSoft),
        reason:
            'Dönem kapandı; tahmin edilen gün kalmadığı için yumuşak ton da '
            'kalmamalı',
      );
    }
  });

  test('planlanandan uzun süren reglde tahmin rengi yok', () {
    final data = halka(kayitli: 9, planlanan: 7);
    for (final renk in data.colors) {
      expect(renk, isNot(tokens.flowSoft));
    }
  });

  test('geçmiş tahmin günü hem soluk hem yumuşak olmuyor', () {
    // Tahmin günleri tanımı gereği bugünden sonra; geçmiş solukluğu
    // (alpha 80) ile üst üste binmemeli.
    final data = halka(kayitli: 1, planlanan: 7);
    for (var gun = 2; gun <= 7; gun++) {
      expect(
        data.colors[gun - 1],
        tokens.flowSoft,
        reason: '$gun. gün: tam tonlu yumuşak renk beklenir, soluklaştırılmış '
            'hâli değil',
      );
    }
  });

  test('üç ton iki temada da birbirinden ayrı', () {
    // Çelenkte bir regl çiçeği üç durumdan birinde: yaşanmış-bugün,
    // tahmin, yaşanmış-geçmiş. İkisi birbirine yaklaşırsa ayrım
    // kullanıcıya ulaşmaz — ölçüldüğünde (açık tema) sırasıyla
    // #b24a66, #d07e93, #e7c6cf; koyu temada #d07e93, #b24a66, #563744.
    //
    // `flowSoft` iki temada da zemine doğru çekiliyor, yani sıralama
    // korunuyor: bugün en belirgin, tahmin bir adım geride, geçmiş en silik.
    for (final koyu in [false, true]) {
      final tema = koyu
          ? AppTheme.dark(AppFlavor.plum)
          : AppTheme.light(AppFlavor.plum);
      final t = tema.extension<AppTokens>()!;

      final yasanmis = t.flow;
      final tahmin = t.flowSoft;
      final gecmis = Color.alphaBlend(t.flow.withAlpha(80), t.surface);

      final ad = koyu ? 'koyu' : 'açık';
      expect(
        tahmin.toARGB32(),
        isNot(yasanmis.toARGB32()),
        reason: '$ad tema: tahmin ile yaşanmış aynı renk',
      );
      expect(
        tahmin.toARGB32(),
        isNot(gecmis.toARGB32()),
        reason: '$ad tema: tahmin ile geçmiş gün aynı renk',
      );
      expect(
        yasanmis.toARGB32(),
        isNot(gecmis.toARGB32()),
        reason: '$ad tema: bugün ile geçmiş gün aynı renk',
      );
    }
  });
}
