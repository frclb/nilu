import 'package:flutter/widgets.dart';

/// Genişliğe göre düzen sınıfı.
///
/// Uygulama telefon genişliği varsayarak yazılmıştı: tek sütun, kenardan
/// kenara. iPad'de bu sütun 1024 pt'ye kadar geriliyor, kart içindeki iki
/// kelimelik etiketin sağında 800 pt boşluk kalıyordu.
///
/// Cihaz adına göre değil **gelen genişliğe** göre karar veriyoruz; iPadOS 26
/// pencereleri serbestçe boyutlandırıyor ve katlanabilir telefon açılıp
/// kapandığında genişlik çalışma anında değişiyor. "iPad mi?" sorusunun
/// doğru cevabı yok, "şu an kaç pt?" sorusunun var.
enum LayoutClass {
  /// Tek sütun, kenardan kenara. Bütün iPhone'lar; katlanabilir kapalıyken.
  compact,

  /// Tek sütun ama ortalanmış. iPad portre, katlanabilir açıkken, Split View.
  medium,

  /// Yan menü sığacak kadar geniş. iPad yatay, 13" portre.
  expanded,
}

/// Düzen eşikleri ve ölçüleri.
abstract final class AppLayout {
  /// Bu genişliğin altı telefon kabul edilir.
  ///
  /// Ölçüler (pt, portre): iPhone 16e 375, iPhone 17 393, 17 Pro Max 440,
  /// iPhone Duo kapalı 466. En geniş telefon 466; eşik 600 hepsini rahatça
  /// içeri alıyor ve en dar tablete (iPad mini 744) değmiyor.
  static const double compactMax = 600;

  /// Bu genişlikten sonra yan gezinme menüsü açılır.
  ///
  /// iPad Duo açık 626 ve iPad mini 744 bunun altında: oralarda alt menü
  /// kalıyor, çünkü yan menü + 600 pt içerik ikisine de sığmıyor.
  static const double expandedMin = 900;

  /// Tek sütun içeriğin büyüyebileceği azami genişlik.
  ///
  /// [compactMax] ile aynı bilinçli olarak: 600 pt'lik bir ekranda içerik tam
  /// genişlikte, 601 pt'de hâlâ 600 pt. Eşikte sıçrama olmuyor.
  static const double contentMaxWidth = 600;

  /// Yan gezinme menüsünün genişliği.
  static const double railWidth = 88;

  static LayoutClass classOf(double width) {
    if (width < compactMax) return LayoutClass.compact;
    if (width < expandedMin) return LayoutClass.medium;
    return LayoutClass.expanded;
  }

  /// [width] kadar yerde [maxWidth] genişliğinde içeriği ortalayan boşluk.
  ///
  /// Sliver'lar için: `Center` + `ConstrainedBox` sliver protokolünde
  /// çalışmıyor, `SliverPadding` çalışıyor.
  static EdgeInsets centeringInsets(
    double width, {
    double maxWidth = contentMaxWidth,
  }) {
    final slack = width - maxWidth;
    if (slack <= 0) return EdgeInsets.zero;
    return EdgeInsets.symmetric(horizontal: slack / 2);
  }
}

extension LayoutContext on BuildContext {
  /// Pencerenin düzen sınıfı.
  ///
  /// Gezinme kabuğu gibi **ekran düzeyi** kararlar için. Bir gövdenin kendi
  /// içindeki karar için [AppContentWidth] kullanın: yan menü açıkken gövde
  /// pencereden dar kalıyor ve pencere genişliği yanıltıyor.
  LayoutClass get layoutClass =>
      AppLayout.classOf(MediaQuery.sizeOf(this).width);

  bool get isCompactLayout => layoutClass == LayoutClass.compact;
}

/// İçeriği okunur genişlikte tutup ortalar.
///
/// Dar ekranda hiçbir şey yapmaz — telefon görünümü birebir korunur.
///
/// `Center` ya da `Align` ile değil **`Padding`** ile daraltıyor. İkisi de
/// dikey kısıtı gevşetiyor: gövdesi `Stack` olan bir ekran o zaman ekranı
/// doldurmayı bırakıp içeriğine göre büzülüyor, `Expanded` "unbounded height"
/// hatası veriyor. `Padding` gelen kısıtın sıkılığını koruyup yalnızca
/// genişliğini kırpıyor.
class AppContentWidth extends StatelessWidget {
  const AppContentWidth({
    super.key,
    required this.child,
    this.maxWidth = AppLayout.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) return child;
        return Padding(
          padding: AppLayout.centeringInsets(
            constraints.maxWidth,
            maxWidth: maxWidth,
          ),
          child: child,
        );
      },
    );
  }
}

/// [AppContentWidth]'in sliver karşılığı.
///
/// Gelen çapraz eksen genişliğini ölçüp [SliverPadding]'e çevirir; kaydırma
/// çubuğu kenarda kalır, içerik ortada.
class SliverContentWidth extends StatelessWidget {
  const SliverContentWidth({
    super.key,
    required this.sliver,
    this.maxWidth = AppLayout.contentMaxWidth,
  });

  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) => SliverPadding(
        padding: AppLayout.centeringInsets(
          constraints.crossAxisExtent,
          maxWidth: maxWidth,
        ),
        sliver: sliver,
      ),
    );
  }
}
