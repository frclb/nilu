import 'insights_service.dart';

/// Kullanıcıya gösterilmeye değer döngü uyarıları.
///
/// Bunlar teşhis değil; sağlık kurumlarının "bu durumda hekime danış" dediği
/// eşikler. Uygulama zaten döngü uzunluklarını hesaplıyordu ama sonuç pasif
/// bir sayı olarak duruyordu — eşik aşıldığında kullanıcıya bir şey
/// söylemiyordu.
enum CycleAlert {
  /// Döngüler düzenli olarak 24 günden kısa.
  ///
  /// Kaynak: Office on Women's Health — 24 günden kısa ya da 38 günden uzun
  /// döngüler için hekime danışılması öneriliyor.
  consistentlyShort,

  /// Döngüler düzenli olarak 38 günden uzun.
  ///
  /// Seyrek ya da düzensiz regl, PCOS'un tanımlayıcı belirtilerinden biri.
  consistentlyLong,

  /// Döngü uzunluğu belirgin biçimde oynuyor.
  ///
  /// NHS "aniden değiştiyse" hekime danışılmasını öneriyor.
  highlyVariable,
}

/// Döngü uzunluklarından uyarı üretir.
class CycleAlertService {
  const CycleAlertService._();

  /// Sağlıklı kabul edilen alt sınır.
  static const int minTypicalDays = 24;

  /// Sağlıklı kabul edilen üst sınır.
  static const int maxTypicalDays = 38;

  /// "Belirgin oynama" eşiği: uçlar arası gün farkı.
  ///
  /// [CycleRegularity.irregular] ile aynı eşik (8+ gün) kullanılıyor;
  /// ekranda iki farklı düzen tanımı olması kafa karıştırırdı.
  static const int variationThreshold = 8;

  /// Uyarı üretmek için gereken en az gözlenmiş döngü sayısı.
  ///
  /// Tek bir döngüye bakıp "düzensizsin" demek olmaz: ilk döngüsünü
  /// kaydeden kullanıcıya sağlık uyarısı göstermek hem yanlış hem ürkütücü.
  static const int minObservations = 3;

  /// [points] gözlenmiş döngü uzunlukları (en yeniden eskiye ya da tersi;
  /// sıra önemli değil).
  static Set<CycleAlert> evaluate(List<CycleLengthPoint> points) {
    if (points.length < minObservations) return const {};

    final alerts = <CycleAlert>{};
    final lengths = points.map((p) => p.lengthInDays).toList();

    // "Düzenli olarak" — tek bir kısa döngü uyarı sebebi değil; hepsi
    // eşiğin dışındaysa örüntüden söz edilebilir.
    if (lengths.every((l) => l < minTypicalDays)) {
      alerts.add(CycleAlert.consistentlyShort);
    }
    if (lengths.every((l) => l > maxTypicalDays)) {
      alerts.add(CycleAlert.consistentlyLong);
    }

    final spread = InsightsService.variation(points);
    if (spread != null && spread >= variationThreshold) {
      alerts.add(CycleAlert.highlyVariable);
    }

    return alerts;
  }

  static String titleKey(CycleAlert alert) => switch (alert) {
    CycleAlert.consistentlyShort => 'alert_short_title',
    CycleAlert.consistentlyLong => 'alert_long_title',
    CycleAlert.highlyVariable => 'alert_variable_title',
  };

  static String bodyKey(CycleAlert alert) => switch (alert) {
    CycleAlert.consistentlyShort => 'alert_short_body',
    CycleAlert.consistentlyLong => 'alert_long_body',
    CycleAlert.highlyVariable => 'alert_variable_body',
  };
}
