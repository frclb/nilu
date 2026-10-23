import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_tokens.dart';
import '../localization/app_localizations.dart';

/// İçerik görselleri için uygulama içinde çizilen illüstrasyon.
///
/// Bütün içerik görselleri Google'ın `lh3.googleusercontent.com/aida-public/...`
/// adreslerinden geliyordu. Bunlar tasarım aracının ürettiği geçici bağlantılar:
/// kalıcı olacaklarına dair bir söz yok ve biri çoktan HTTP 400 dönmeye
/// başlamıştı (kütüphanedeki öne çıkan makale). Mağazaya çıkmış bir uygulamanın
/// görselleri, üçüncü taraf bir adres sustuğu gün topluca kaybolamaz.
///
/// Bu yüzden görseller ağdan değil, burada çiziliyor:
/// - Çevrimdışı çalışır; sağlık uygulamasının geri kalanı da çalışıyor.
/// - Süresi dolmaz, 404 vermez, yükleme beklemez.
/// - Uygulama boyutuna tek bayt eklemez, her yoğunlukta net görünür.
/// - Açık/koyu temaya uyar.
///
/// Gerçek fotoğraf tedarik edildiğinde [ContentIllustration] çağrıları
/// `Image.asset` ile değiştirilebilir; çağrı yerleri tek tip olduğu için
/// değişiklik lokaldir.
class ContentIllustration extends StatelessWidget {
  /// Görselin deseni bu metinden türetilir. Aynı içerik her açılışta aynı
  /// görünsün diye rastgelelik yok: tohum, içeriğin kimliği.
  final String seed;

  /// İçeriği anlatan simge (yemek, yoga, egzersiz, makale kategorisi…).
  final IconData icon;

  const ContentIllustration({
    super.key,
    required this.seed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _paletteFor(seed, isDark: isDark);

    return CustomPaint(
      painter: _IllustrationPainter(palette: palette, seed: seed),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.38,
          child: FittedBox(child: Icon(icon, color: palette.glyph, size: 96)),
        ),
      ),
    );
  }

  /// Tohumdan sabit bir renk çifti seçer.
  static _Palette _paletteFor(String seed, {required bool isDark}) {
    final options = isDark ? _darkPalettes : _lightPalettes;
    return options[seed.hashCode.abs() % options.length];
  }

  static const List<_Palette> _lightPalettes = [
    _Palette(Color(0xFFF9E7EB), Color(0xFFE9C4CD), Color(0x66551B26)),
    _Palette(Color(0xFFFCECEE), Color(0xFFEFC9CF), Color(0x668A2C3C)),
    _Palette(Color(0xFFF2E9F7), Color(0xFFDCC9EA), Color(0x666B21A8)),
    _Palette(Color(0xFFE8F5F2), Color(0xFFC5E5DD), Color(0x660D9488)),
    _Palette(Color(0xFFFDF0E4), Color(0xFFF3D6B8), Color(0x669A3412)),
  ];

  static const List<_Palette> _darkPalettes = [
    _Palette(Color(0xFF2A1F20), Color(0xFF3E2A2F), Color(0x99E9C4CD)),
    _Palette(Color(0xFF2B181D), Color(0xFF43242C), Color(0x99EFC9CF)),
    _Palette(Color(0xFF241C2E), Color(0xFF362A45), Color(0x99DCC9EA)),
    _Palette(Color(0xFF16262A), Color(0xFF21393D), Color(0x99C5E5DD)),
    _Palette(Color(0xFF2C2118), Color(0xFF443224), Color(0x99F3D6B8)),
  ];
}

class _Palette {
  final Color from;
  final Color to;
  final Color glyph;

  const _Palette(this.from, this.to, this.glyph);
}

/// Arka planı ve üstündeki yumuşak lekeleri çizer.
class _IllustrationPainter extends CustomPainter {
  final _Palette palette;
  final String seed;

  const _IllustrationPainter({required this.palette, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.from, palette.to],
        ).createShader(rect),
    );

    // Lekelerin yeri tohuma bağlı: aynı içerik hep aynı görünür ama farklı
    // içerikler birbirinin kopyası olmaz.
    final random = math.Random(seed.hashCode);
    final blob = Paint()..color = palette.to.withAlpha(90);
    final shortest = size.shortestSide;

    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.1 + random.nextDouble() * 0.8),
          size.height * (0.1 + random.nextDouble() * 0.8),
        ),
        shortest * (0.18 + random.nextDouble() * 0.22),
        blob,
      );
    }
  }

  @override
  bool shouldRepaint(_IllustrationPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.palette.from != palette.from;
}

/// Ağdan gelen bir görseli güvenle gösterir.
///
/// Uzak adres öldüğünde ya da cihaz çevrimdışıyken [fallback] çizilir; bir
/// önceki kodda bazı çağrılarda `errorBuilder` hiç yoktu, o ekranlarda
/// kullanıcı gri bir boşluk ya da hata kutusu görüyordu.
class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final Widget fallback;
  final BoxFit fit;

  const SafeNetworkImage({
    super.key,
    required this.url,
    required this.fallback,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final source = url;
    if (source == null || source.isEmpty) return fallback;

    return Image.network(
      source,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => fallback,
      // Yüklenirken de boşluk değil illüstrasyon durur; görsel gelince
      // yerini alır, düzen zıplamaz.
      frameBuilder: (_, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return fallback;
      },
    );
  }
}

/// Profil görseli olmayan kullanıcı için baş harf rozeti.
///
/// Avatar da uzak bir adresten geliyordu — üstelik herkes için **aynı**
/// fotoğraf. Kullanıcının kendi adının baş harfi hem doğru hem çevrimdışı.
class InitialAvatar extends StatelessWidget {
  final String? name;
  final double size;

  const InitialAvatar({super.key, required this.name, this.size = 48});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.tokens;
    final isDark = theme.brightness == Brightness.dark;
    final initial = _initialOf(context, name);

    // İnce degrade halka (gül → marka tülü → kehribar), içinde baş harf.
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [t.secondaryTint, t.brandTint, t.accentTint],
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? t.surfaceAlt : t.surface,
        ),
        child: initial == null
            ? Icon(
                Icons.person_outline,
                size: size * 0.5,
                color: theme.colorScheme.primary,
              )
            : Text(
                initial,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: size * 0.42,
                  height: 1,
                  color: theme.colorScheme.primary,
                ),
              ),
      ),
    );
  }

  /// "irem" → "İ": baş harf de dile göre büyütülüyor.
  static String? _initialOf(BuildContext context, String? name) {
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return context.upper(trimmed.characters.first);
  }
}
