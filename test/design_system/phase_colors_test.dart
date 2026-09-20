import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/design_system/app_flavor.dart';
import 'package:period_tracker/design_system/app_tokens.dart';
import 'package:period_tracker/design_system/phase_colors.dart';
import 'package:period_tracker/domain/models/cycle_info.dart';

/// Faz renklerinin anlamı.
///
/// Hormonal doğum kontrolünde çarkın 27 çiçeğinin 21'i `textMuted`'a, yani
/// koyu griye dönüyordu. Davranış doğruydu — yumurtlama baskılandığı için
/// uygulama faz uydurmuyor — ama sunum "veri yok / bozuk" diyordu:
/// kullanıcı bunu "renkler kaybolmuş" diye okuyor.
///
/// Üç ayrı anlam, üç ayrı renk olmalı:
///
///   * faz renkleri — evre gerçekten biliniyor
///   * `suppressed` — durum biliniyor ama evrelere ayrılmıyor
///   * `unknown` — hesaplayacak veri yok
void main() {
  for (final flavor in AppFlavor.values) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      group('${flavor.name} · ${brightness.name}', () {
        final t = AppTokens.of(flavor, brightness);

        test('baskılanmış evre gri değil', () {
          // Gri "veri yok" demek. Burada durum biliniyor.
          expect(CyclePhase.suppressed.color(t), isNot(t.textMuted));
          expect(CyclePhase.suppressed.color(t), isNot(t.textFaint));
        });

        test('baskılanmış evre "veri yok"tan ayrı', () {
          expect(
            CyclePhase.suppressed.color(t),
            isNot(CyclePhase.unknown.color(t)),
            reason: 'iki farklı durum tek renkle anlatılıyor',
          );
        });

        test('baskılanmış evre bir faz rengi taklit etmiyor', () {
          // En ağırı bu: baskılanmış bir günü foliküler ya da yumurtlama
          // rengiyle boyamak, olmayan bir evreyi varmış gibi göstermek
          // olurdu.
          for (final phase in [
            CyclePhase.menstruation,
            CyclePhase.follicular,
            CyclePhase.ovulation,
            CyclePhase.luteal,
          ]) {
            expect(
              CyclePhase.suppressed.color(t),
              isNot(phase.color(t)),
              reason: '${phase.name} rengiyle aynı',
            );
          }
        });

        test('gerçek fazlar birbirinden ayrı', () {
          final colors = [
            CyclePhase.menstruation,
            CyclePhase.follicular,
            CyclePhase.ovulation,
            CyclePhase.luteal,
          ].map((p) => p.color(t)).toList();

          expect(colors.toSet(), hasLength(colors.length));
        });

        test('baskılanmışken doğurganlık göstergesi nötr', () {
          // Doğurganlık hesaplanmıyor; göstergeyi renklendirmek olmayan
          // bir tahmini varmış gibi gösterirdi.
          expect(CyclePhase.suppressed.fertilityColor(t), t.textFaint);
        });
      });
    }
  }
}
