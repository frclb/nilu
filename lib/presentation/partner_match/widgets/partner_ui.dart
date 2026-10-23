import 'package:flutter/material.dart';

import '../../../design_system/app_decor.dart';
import '../../../design_system/app_tokens.dart';

/// Partner ekranlarının ortak süsleri.
///
/// Eşleşme, paylaşım ayarları, durum ve rehber ekranı aynı başlık, aynı
/// erik kart ve aynı "kodu vurgula" kalıbını kullanıyor; her dosya kendi
/// kopyasını yazınca ekranlar arasında küçük farklar birikiyordu.
class PartnerUi {
  const PartnerUi._();

  /// Koyu erik kart: durum kartı ve rehberin girişi.
  ///
  /// Markanın ana degradesiyle aynı renkler, kartta çapraz. Üstündeki yazı
  /// her zaman `onPrimary`.
  static LinearGradient plum(BuildContext context) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppGradients.primary(context).colors,
    stops: const [0, 0.55, 1],
  );

  /// [full] içindeki [part]'ı (doğrulama kodu) kalın gösterir.
  ///
  /// Metin tek parça kalıyor: çeviri cümlenin neresine kodu koyarsa koysun
  /// vurgu doğru yere düşüyor, ekran okuyucu da tek cümle duyuyor.
  static TextSpan emphasize(String full, String part, TextStyle strong) {
    final i = part.isEmpty ? -1 : full.indexOf(part);
    if (i < 0) return TextSpan(text: full);
    return TextSpan(
      children: [
        TextSpan(text: full.substring(0, i)),
        TextSpan(text: part, style: strong),
        TextSpan(text: full.substring(i + part.length)),
      ],
    );
  }
}

/// Bölüm başlığı ("Paylaşılan Bilgiler", "Ne Yapabilirsin?").
class PartnerSectionTitle extends StatelessWidget {
  const PartnerSectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final title = Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontSize: 18,
        color: context.tokens.text,
      ),
    );
    if (trailing == null) return title;
    return Row(
      children: [
        Flexible(child: title),
        const SizedBox(width: 10),
        trailing!,
      ],
    );
  }
}
