import 'package:flutter/material.dart';

import 'app_decor.dart';
import 'app_palette.dart';
import 'brand_lotus.dart';

/// Açılış ekranındaki çıplak lotustan [AppLogoMark]'a geçen işaret.
///
/// iOS'un açılış ekranı (`tool/generate_launch_image.py`) ortada erik renkli
/// bir lotus gösteriyor; uygulamanın işareti ise dairenin içinde beyaz lotus.
/// Bu widget ikisinin arasındaki her kareyi çiziyor: [settle] 0'da açılış
/// ekranının işaretiyle aynı, 1'de [AppLogoMark] ile aynı.
///
/// Açılış ekranının renkleri burada çünkü tema rolü değiller: statik görsel
/// kullanıcının tema çeşidini bilemez, her zaman bu tonlarda.
class LaunchMark extends StatelessWidget {
  const LaunchMark({super.key, required this.circle, required this.settle});

  /// Açılış ekranındaki işaretin genişliği (pt). Storyboard görseli doğal
  /// boyutunda ortalıyor; generator'daki `WIDTH_PT` ile aynı olmalı
  /// (`launch_intro_test.dart` karşılaştırıyor).
  static const double launchWidth = 120;

  /// Dairenin çapı: splash'teki `AppLogoMark(size: 88)` ile aynı.
  static const double markSize = 88;

  /// Açılış ekranındaki işaretin rengi; generator'ın `PLUM_700` ve
  /// `ROSE_200` sabitleri.
  static Color launchColor(Brightness brightness) =>
      brightness == Brightness.dark ? AppPalette.rose200 : AppPalette.plum700;

  /// Dairenin ölçeği; eğri hafifçe taşabiliyor.
  final double circle;

  /// Lotusun daireye oturması: 0 açılış ekranı, 1 [AppLogoMark].
  final double settle;

  @override
  Widget build(BuildContext context) {
    final from = launchColor(Theme.of(context).brightness);
    // `AppLogoMark` lotusu dairenin %60'ına sığdırıyor.
    const end = markSize * 0.6 / launchWidth;
    return SizedBox.square(
      dimension: launchWidth,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            key: const Key('launch_mark_circle'),
            scale: circle,
            child: Container(
              width: markSize,
              height: markSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.mark(context),
                boxShadow: AppShadows.soft(context),
              ),
            ),
          ),
          Transform.scale(
            key: const Key('launch_mark_lotus'),
            scale: 1 - (1 - end) * settle,
            child: SizedBox(
              width: launchWidth,
              child: BrandLotus(
                color: Color.lerp(from, Colors.white, settle)!,
                sideOpacity: 0.75 + 0.05 * settle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
