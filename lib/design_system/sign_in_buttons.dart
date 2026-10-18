import 'dart:math' as math;

import 'package:flutter/material.dart';

/// "Apple ile devam et" ve "Google ile devam et" düğmeleri.
///
/// Renkler **bilerek sabit**: ikisi de başka şirketlerin markası ve
/// görünüşleri kurala bağlı. Apple'ın İnsan Arayüzü Yönergeleri açık zeminde
/// siyah, koyu zeminde beyaz düğme istiyor; Google'ın marka kuralları beyaz
/// (koyu temada koyu gri) düğme ve dört renkli "G" istiyor. Uygulamanın
/// teması bunları boyarsa App Store incelemesi ve Google'ın kuralları
/// sorun çıkarıyor — bu yüzden token'lardan değil buradan geliyorlar.
///
/// Apple düğmesi her zaman önce ve en az Google düğmesi kadar belirgin
/// (App Store Yönergeleri 4.8).
class SignInButton extends StatelessWidget {
  const SignInButton.apple({
    super.key,
    required this.label,
    required this.onPressed,
  }) : _apple = true;

  const SignInButton.google({
    super.key,
    required this.label,
    required this.onPressed,
  }) : _apple = false;

  final String label;
  final VoidCallback? onPressed;
  final bool _apple;

  static const Color _black = Color(0xFF000000);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _googleDark = Color(0xFF131314);
  static const Color _googleBorderLight = Color(0xFF747775);
  static const Color _googleBorderDark = Color(0xFF8E918F);
  static const Color _googleTextLight = Color(0xFF1F1F1F);
  static const Color _googleTextDark = Color(0xFFE3E3E3);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    final Color zemin;
    final Color yazi;
    final Color? kenar;
    if (_apple) {
      zemin = dark ? _white : _black;
      yazi = dark ? _black : _white;
      kenar = null;
    } else {
      zemin = dark ? _googleDark : _white;
      yazi = dark ? _googleTextDark : _googleTextLight;
      kenar = dark ? _googleBorderDark : _googleBorderLight;
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: zemin,
          foregroundColor: yazi,
          disabledBackgroundColor: zemin.withValues(alpha: 0.5),
          disabledForegroundColor: yazi.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: kenar == null ? BorderSide.none : BorderSide(color: kenar),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_apple)
              Icon(Icons.apple, size: 22, color: yazi)
            else
              const SizedBox.square(
                dimension: 18,
                child: CustomPaint(painter: _GoogleMark()),
              ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: yazi,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Google'ın dört renkli "G" işareti.
///
/// Görsel dosya yerine çiziliyor: uygulama uzak görsel yüklemiyor ve tek bir
/// işaret için SVG paketi eklemeye değmez.
class _GoogleMark extends CustomPainter {
  const _GoogleMark();

  static const Color _blue = Color(0xFF4285F4);
  static const Color _green = Color(0xFF34A853);
  static const Color _yellow = Color(0xFFFBBC05);
  static const Color _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final kalinlik = s * 0.2;
    final merkez = Offset(size.width / 2, size.height / 2);
    final r = s / 2 - kalinlik / 2;
    final kutu = Rect.fromCircle(center: merkez, radius: r);
    double der(double d) => d * math.pi / 180;

    Paint boya(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = kalinlik;

    // Açılar saat yönünde, 0° saat üçte.
    canvas.drawArc(kutu, der(-150), der(110), false, boya(_red));
    canvas.drawArc(kutu, der(150), der(60), false, boya(_yellow));
    canvas.drawArc(kutu, der(40), der(110), false, boya(_green));
    canvas.drawArc(kutu, der(0), der(40), false, boya(_blue));
    canvas.drawRect(
      Rect.fromLTRB(
        merkez.dx,
        merkez.dy - kalinlik / 2,
        merkez.dx + r + kalinlik / 2,
        merkez.dy + kalinlik / 2,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
