/// Ana ekran widget'ının bir günlük içeriği; metinler çevrilmiş hâlde.
///
/// Widget ayrı bir süreçte çalışıyor, uygulamanın sözlüğüne de belleğine de
/// erişemiyor. Önceden yalnızca döngü günü ve kalan gün sayısını alıp
/// metinleri kendisi (yalnız Türkçe) kuruyordu; gebelikte döngü günü
/// olmadığı için "kayıt ekle" diyordu, gecikmede "bugün başlıyor" yazıyordu
/// ve uygulama açılmadığı sürece gece yarısından sonra da dünün sayısını
/// gösteriyordu. Artık uygulama önümüzdeki günlerin her biri için hazır
/// metni yazıyor; widget yalnızca o günün girdisini çiziyor.
///
/// Ham sağlık kaydı yazılmıyor: yalnızca ekranda görünecek kısa metinler.
class HomeWidgetEntry {
  final DateTime date;
  final bool hasData;

  /// Büyük harfli küçük başlık: "DÖNGÜ GÜNÜ", "GEBELİK", "LOHUSALIK".
  final String label;

  /// Büyük yazılan değer: "14", "24+2", "10. gün".
  final String value;

  /// Değerin altındaki satır: evre adı, gebelik ayı.
  final String caption;

  /// Alt satır: "Regle 3 gün kaldı", "Tahmini doğuma 112 gün". Veri yokken
  /// widget'ın tek metni.
  final String detail;

  /// VoiceOver'ın okuyacağı cümle. "24+2" sesli okununca "yirmi dört artı
  /// iki" oluyordu.
  final String spoken;

  /// Halkanın dolu kısmı (0–1); bilinmiyorsa `null`, halka boş kalıyor.
  final double? progress;

  /// Renk: döngü evresi (`CyclePhase.name`) ya da `pregnancy` /
  /// `postpartum`. Karşılıkları `CycleWidget.swift`'te.
  final String colorKey;

  const HomeWidgetEntry({
    required this.date,
    required this.hasData,
    this.label = '',
    this.value = '',
    this.caption = '',
    this.detail = '',
    this.spoken = '',
    this.progress,
    this.colorKey = 'unknown',
  });

  /// Anahtar adları `CycleWidget.swift`teki `WidgetDay` ile aynı olmalı.
  Map<String, Object?> toJson() => {
    'date':
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}',
    'hasData': hasData,
    'label': label,
    'value': value,
    'caption': caption,
    'detail': detail,
    'spoken': spoken,
    'progress': progress,
    'colorKey': colorKey,
  };
}
