import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/design_system/app_tokens.dart';
import 'package:period_tracker/presentation/calendar/widgets/calendar_grid.dart';

/// Tahmin bandı artık **opak** çiziliyor.
///
/// Eskiden `flowSoft.withAlpha(90)` idi. Yarı saydam iki kap yan yana
/// geldiğinde kenarların her biri sınır pikselini yarım kaplıyor ve aradan
/// zemin sızıyordu; bindirerek kapatmak da mümkün değildi, çünkü üst üste
/// gelen iki tül açık çizginin yerine koyu bir çizgi koyar.
///
/// Çözüm tülü zemine **önceden karıştırmak**. Buradaki testler o değişimin
/// asıl riskini tutuyor: görünüm değişmemeli. Dikişin kendisi ölçüldüğünde
/// parlaklıkta yalnızca ~2 birim fark ediyordu, yani piksel testiyle
/// güvenilir biçimde ayırt edilemeyecek kadar sönük — asıl tehlike çizgi
/// değil, karışımın yanlış zemine yapılıp bandın renginin kayması.
void main() {
  for (final entry in {
    'açık': AppTokens.light,
    'koyu': AppTokens.dark,
  }.entries) {
    final t = entry.value;
    final isDark = entry.key == 'koyu';

    group('${entry.key} tema', () {
      test('bant ve dikiş opak — bindirme ancak böyle güvenli', () {
        // Saydam kalırsa bindirme koyu bir çizgi bırakır; bağlayıcı da
        // bu yüzden yalnızca opak dikişte bindiriyor.
        expect(predictedBandColor(t, isDark).a, 1.0);
        expect(predictedSeamColor(t, isDark).a, 1.0);
      });

      test('görünüm değişmedi: hâlâ aynı incelikte bir tül', () {
        // Opak renk, eski saydam bandın zemin üstündeki karşılığıyla
        // birebir aynı olmalı. Üstündeki gün dairesi de tül ve kompozit
        // birleşmeli olduğu için ekranda hiçbir piksel değişmiyor.
        expect(
          predictedBandColor(t, isDark),
          Color.alphaBlend(t.flowSoft.withAlpha(isDark ? 100 : 90), t.surface),
        );
      });

      test('dikiş bandın incelmiş hâli, başka bir renk değil', () {
        // Dikiş zemine doğru çekiliyor ama bandın rengiyle zemin arasında
        // kalmalı: dışına çıkarsa iki gün arasında yabancı bir ton belirir.
        double lum(Color c) => 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;

        final band = lum(predictedBandColor(t, isDark));
        final seam = lum(predictedSeamColor(t, isDark));
        final surface = lum(t.surface);

        expect(
          (seam - band).abs(),
          greaterThan(0.005),
          reason: 'Dikiş banttan hiç ayrışmıyor: geçiş yok.',
        );
        // Zemine doğru, ama yolun çok azını gidiyor: "hafif" olan bu.
        expect(
          (seam - band) / (surface - band),
          inInclusiveRange(0.05, 0.25),
          reason: 'Dikiş ya görünmüyor ya bandı ikiye bölüyor.',
        );
      });
    });
  }
}
