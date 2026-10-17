import 'package:flutter/material.dart';

import '../../../design_system/app_tokens.dart';
import '../../../design_system/brand_lotus.dart';

/// Karşılama sayfalarının çizimleri.
///
/// Eskiden dört sayfanın da kahraman alanı aynıydı: üstteki rozetin ikonu
/// büyütülüp soluklaştırılmış hâli, altında değişmeyen bir damla + çiçek +
/// güneş + ay dizisi. Yani çizim ne sayfayı anlatıyordu ne de bir şey
/// gösteriyordu — rozetin tekrarıydı.
///
/// Artık her sayfa uygulamanın **kendi ekranından** bir kesit gösteriyor:
/// takvimdeki regl bandı, kayıt ekranının çipleri, partner bağlantısı.
/// Kullanıcı daha uygulamaya girmeden ne göreceğini biliyor.
enum OnboardingIllustration {
  /// Markanın lotusu — ikon ve açılış ekranıyla aynı eğriler.
  brand,

  /// Takvimdeki regl bandı.
  calendar,

  /// Kayıt ekranının belirti çipleri.
  log,

  /// Partner bağlantısı.
  partner;

  Widget build(BuildContext context) => switch (this) {
    OnboardingIllustration.brand => const _Brand(),
    OnboardingIllustration.calendar => const _Calendar(),
    OnboardingIllustration.log => const _Log(),
    OnboardingIllustration.partner => const _Partner(),
  };
}

/// Çizimlerin ortak doğal boyutu. Kahraman alanı `FittedBox` ile
/// ölçeklendiği için buradaki ölçüler oran belirliyor, mutlak boyut değil.
const Size _canvas = Size(220, 170);

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: _canvas,
    child: Center(
      child: SizedBox(
        width: 150,
        height: 115,
        child: BrandLotus(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}

/// Takvim: bir ay ızgarası ve içinden geçen regl bandı.
class _Calendar extends StatelessWidget {
  const _Calendar();

  static const _columns = 7;
  static const _rows = 4;

  /// Bandın hangi satırda, hangi günler arasında olduğu.
  static const _bandRow = 1;
  static const _bandStart = 2;
  static const _bandEnd = 5;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox.fromSize(
      size: _canvas,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var row = 0; row < _rows; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var col = 0; col < _columns; col++)
                    _cell(t, primary, row, col),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(AppTokens t, Color primary, int row, int col) {
    final inBand = row == _bandRow && col >= _bandStart && col <= _bandEnd;
    // Bandın uçları yuvarlak, ortası düz: takvimdeki bandın aynısı.
    final first = col == _bandStart;
    final last = col == _bandEnd;

    return Container(
      width: 22,
      height: 16,
      decoration: BoxDecoration(
        color: inBand ? t.flow : null,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(inBand && first ? 8 : 0),
          right: Radius.circular(inBand && last ? 8 : 0),
        ),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: inBand ? t.surface : primary.withValues(alpha: 0.22),
          ),
        ),
      ),
    );
  }
}

/// Kayıt: belirti çipleri, biri seçili.
class _Log extends StatelessWidget {
  const _Log();

  /// `(genişlik, seçili mi)` — gerçek ekrandaki gibi farklı uzunlukta
  /// etiketler ve aralarında seçilmiş olanlar.
  static const _rows = <List<(double, bool)>>[
    [(64, true), (44, false), (52, false)],
    [(48, false), (70, true), (38, false)],
    [(56, false), (40, false), (62, false)],
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox.fromSize(
      size: _canvas,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final row in _rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final (width, selected) in row)
                    Container(
                      width: width,
                      height: 26,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? primary
                            : primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                        border: selected
                            ? null
                            : Border.all(
                                color: primary.withValues(alpha: 0.20),
                              ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          // Seçili çipin altındaki onay: kayıt tamamlandı.
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, color: t.flow),
            child: Icon(Icons.check, size: 20, color: t.surface),
          ),
        ],
      ),
    );
  }
}

/// Partner: iki halka, aralarında bağ.
class _Partner extends StatelessWidget {
  const _Partner();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox.fromSize(
      size: _canvas,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ring(primary, filled: true, child: BrandLotus(color: t.surface)),
            // Bağ: iki halkanın arasını dolduran çizgi.
            Container(
              width: 34,
              height: 4,
              color: primary.withValues(alpha: 0.35),
            ),
            _ring(
              primary,
              filled: false,
              child: Icon(
                Icons.favorite,
                size: 34,
                color: primary.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(Color primary, {required bool filled, required Widget child}) =>
      Container(
        width: 76,
        height: 76,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? primary : primary.withValues(alpha: 0.08),
          border: filled
              ? null
              : Border.all(color: primary.withValues(alpha: 0.35), width: 2),
        ),
        child: child,
      );
}
