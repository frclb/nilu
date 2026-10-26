import 'package:flutter/material.dart';

import '../core/platform/app_haptics.dart';
import 'app_contrast.dart';
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

  /// Bildirim hedefi: `await`'ten önce alınıp sonra kullanılıyor.
  ///
  /// Bir işi bekledikten sonra `context` kullanılamıyor (ekran kapanmış
  /// olabilir); bildirim kuyruğu ve hata rengi önceden alınıyor.
  static SnackTarget of(BuildContext context) =>
      SnackTarget._(ScaffoldMessenger.of(context), context.tokens.danger);

  /// Nötr bildirim. [onUndo] verilirse geri alma teklif edilir.
  static void show(
    BuildContext context,
    String message, {
    String? undoLabel,
    VoidCallback? onUndo,
  }) => of(context).show(message, undoLabel: undoLabel, onUndo: onUndo);

  /// Önemli bir iş tamamlandı: nötr bildirim ve başarı titreşimi.
  static void success(
    BuildContext context,
    String message, {
    String? undoLabel,
    VoidCallback? onUndo,
  }) => of(context).success(message, undoLabel: undoLabel, onUndo: onUndo);

  /// Hata bildirimi ve hata titreşimi.
  static void error(BuildContext context, String message) =>
      of(context).error(message);
}

/// [AppSnack.of] ile alınan bildirim hedefi.
///
/// Sonuç bildirimi yalnızca renk ve yazıyla değil titreşimle de veriliyor
/// (Apple'ın geri bildirim yönergeleri): başarı ve hata ayrı titreşiyor,
/// nötr bildirim titreşmiyor. Küçük işlerde (kopyalandı, favorilere eklendi)
/// nötr bildirim kullanılıyor; titreşim yalnızca önemli sonuçlarda anlamlı.
class SnackTarget {
  const SnackTarget._(this._messenger, this._danger);

  final ScaffoldMessengerState _messenger;
  final Color _danger;

  /// Nötr bildirim. [onUndo] verilirse geri alma teklif edilir.
  void show(String message, {String? undoLabel, VoidCallback? onUndo}) {
    final offersUndo = onUndo != null && undoLabel != null;
    _messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: offersUndo
              ? AppSnack.undoDuration
              : const Duration(seconds: 4),
          action: offersUndo
              ? SnackBarAction(label: undoLabel, onPressed: onUndo)
              : null,
        ),
      );
  }

  /// Önemli bir iş tamamlandı: nötr bildirim ve başarı titreşimi.
  void success(String message, {String? undoLabel, VoidCallback? onUndo}) {
    show(message, undoLabel: undoLabel, onUndo: onUndo);
    AppHaptics.success();
  }

  /// İş yapıldı ama eksik kaldı: nötr bildirim ve uyarı titreşimi.
  void warning(String message) {
    show(message);
    AppHaptics.warning();
  }

  /// Hata bildirimi ve hata titreşimi.
  void error(String message) {
    final onBackground = AppContrast.on(_danger);
    _messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _danger,
          content: Text(message, style: TextStyle(color: onBackground)),
        ),
      );
    AppHaptics.error();
  }
}
