import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_tokens.dart';

/// Uygulamanın tek bildirim (snackbar) dili.
///
/// Aynı iş — bir günü regl olarak işaretlemek — üç ekranda üç farklı
/// bildirimle sonuçlanıyordu: biri temanın rengini eziyor, biri duruma göre
/// gri/pembe/kırmızı zemin veriyor, biri hiç bildirim göstermiyordu. Aynı
/// eylemin ekrana göre farklı görünmesi uygulamayı dağınık gösteriyor.
///
/// Geri alınabilir eylemler de buradan geçiyor: geri alma kalıcı bir düğme
/// değil, eylemin hemen ardından gelen geçici bir teklif. Ekranda sürekli
/// duran bir "Geri al", geri alınacak bir şey olmadığında da orada kalıyordu.
class AppSnack {
  const AppSnack._();

  /// Bildirim zemini. Tema bunu kullanıyor; karar tek yerde dursun diye
  /// tema kurucusunun içinde değil burada.
  static Color background(Brightness brightness) =>
      brightness == Brightness.light ? AppPalette.ink900 : AppPalette.night700;

  /// Gövde metni rengi.
  static const Color foreground = AppPalette.sand50;

  /// Geri alma bağlantısının rengi.
  ///
  /// Flutter'ın varsayılanı `inversePrimary`; koyu bildirim zemininde gövde
  /// metninden ayırt edilemiyordu.
  static const Color actionForeground = AppPalette.plum300;

  /// Geri alma teklifinin ekranda kalma süresi.
  ///
  /// Varsayılan dört saniye, yanlış dokunuşu fark edip geri almak için kısa.
  static const Duration undoDuration = Duration(seconds: 6);

  /// Nötr bildirim. [onUndo] verilirse geri alma teklif edilir.
  static void show(
    BuildContext context,
    String message, {
    String? undoLabel,
    VoidCallback? onUndo,
  }) {
    final offersUndo = onUndo != null && undoLabel != null;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: offersUndo ? undoDuration : const Duration(seconds: 4),
          action: offersUndo
              ? SnackBarAction(label: undoLabel, onPressed: onUndo)
              : null,
        ),
      );
  }

  /// [background] üzerinde okunan metin rengi.
  ///
  /// Flutter'ın `estimateBrightnessForColor` metodu "hangisi hoş durur"a göre
  /// karar veriyor, WCAG eşiğine göre değil: koyu temanın uyarı rengini koyu
  /// sayıp açık metin seçiyor ve kontrast 3.1'e düşüyordu. Burada iki aday
  /// ölçülüp kazanan seçiliyor.
  static Color readableOn(Color background) {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final lighter = la > lb ? la : lb;
      final darker = la > lb ? lb : la;
      return (lighter + 0.05) / (darker + 0.05);
    }

    return ratio(background, AppPalette.sand50) >=
            ratio(background, AppPalette.ink900)
        ? AppPalette.sand50
        : AppPalette.ink900;
  }

  /// Hata bildirimi.
  static void error(BuildContext context, String message) {
    final background = context.tokens.danger;
    final onBackground = readableOn(background);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: background,
          content: Text(message, style: TextStyle(color: onBackground)),
        ),
      );
  }
}
