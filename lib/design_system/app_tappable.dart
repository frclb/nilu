import 'package:flutter/widgets.dart';

/// Dokunulabilir özel bir yüzey — `GestureDetector`'ın erişilebilir hâli.
///
/// Uygulamadaki çipler, kartlar ve takvim günleri `GestureDetector` ile
/// yazılmıştı. Görsel olarak düğmeydiler ama VoiceOver yalnızca metni
/// okuyordu: düğme olduklarını ve seçili olup olmadıklarını söylemiyordu.
/// Kör bir kullanıcı "Kramp" çipine dokunduğunda seçildiğini duymuyordu.
///
/// [selected] verilirse seçim durumu da bildiriliyor. Etiket çocuktaki
/// metinden geliyor; metni olmayan yüzeyler [label] vermeli.
class AppTappable extends StatelessWidget {
  const AppTappable({
    super.key,
    required this.onTap,
    required this.child,
    this.selected,
    this.label,
    this.excludeChildSemantics = false,
  });

  final VoidCallback? onTap;
  final Widget child;
  final bool? selected;
  final String? label;

  /// Etiket çocuktaki metnin yerine geçsin mi? Takvim gününde çocuk
  /// yalnızca "17"; etiket "17 Ekim, regl günü" diyor — ikisi birden
  /// okunursa sayı iki kez duyuluyor.
  final bool excludeChildSemantics;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: excludeChildSemantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}
