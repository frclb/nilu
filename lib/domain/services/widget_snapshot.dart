import '../models/cycle_info.dart';

/// Ana ekran widget'ının göstereceği veri.
///
/// Widget ayrı bir süreçte çalışıyor ve uygulamanın belleğine erişemiyor;
/// paylaşılan depoya yazılan bu küçük özeti okuyor. Ham sağlık kaydı
/// **yazılmaz**: widget'ın döngü gününden ve kalan gün sayısından fazlasına
/// ihtiyacı yok, paylaşılan depo da uygulamanın şifreli deposu kadar korumalı
/// değil.
class WidgetSnapshot {
  /// Bugünün döngü günü. Hesaplanamıyorsa null.
  final int? cycleDay;

  /// Sonraki regle kalan gün. Hesaplanamıyorsa null.
  final int? daysUntilPeriod;

  /// Faz anahtarı — widget kendi diline çevirir.
  final String phaseKey;

  const WidgetSnapshot({
    this.cycleDay,
    this.daysUntilPeriod,
    required this.phaseKey,
  });

  /// Gösterilecek bir şey var mı.
  ///
  /// Yoksa widget "kayıt ekle" der; boş bir daire göstermek anlamsız.
  bool get hasData => cycleDay != null;

  factory WidgetSnapshot.from(CycleInfo info) => WidgetSnapshot(
    cycleDay: info.currentCycleDay,
    daysUntilPeriod: info.daysUntilNextPeriod,
    phaseKey: _phaseKey(info.currentPhase),
  );

  Map<String, Object?> toMap() => {
    'cycleDay': cycleDay,
    'daysUntilPeriod': daysUntilPeriod,
    'phaseKey': phaseKey,
    'hasData': hasData,
  };

  static String _phaseKey(CyclePhase phase) => switch (phase) {
    CyclePhase.menstruation => 'menstruation',
    CyclePhase.follicular => 'follicular',
    CyclePhase.ovulation => 'ovulation',
    CyclePhase.luteal => 'luteal',
    CyclePhase.suppressed => 'suppressed',
    CyclePhase.unknown => 'unknown',
  };
}
