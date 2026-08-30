import '../models/cycle_info.dart';

/// Yaklaşan bir döngü olayının türü.
enum AgendaKind { periodStart, fertileStart, ovulation }

/// Takvimde yaklaşan tek bir olay.
class AgendaEntry {
  final AgendaKind kind;
  final DateTime date;

  /// Bugünden kaç gün sonra.
  final int daysAway;

  const AgendaEntry({
    required this.kind,
    required this.date,
    required this.daysAway,
  });

  /// Sunum katmanının çözeceği metin anahtarı.
  String get labelKey => switch (kind) {
    AgendaKind.periodStart => 'agenda_period_start',
    AgendaKind.fertileStart => 'agenda_fertile_start',
    AgendaKind.ovulation => 'agenda_ovulation',
  };
}

/// Döngü tahminlerinden "sırada ne var" listesi üretir.
///
/// Ana ekranın merkezinde eskiden bir halka ve içinde döngü günü vardı. O sayı
/// bir saniyede okunmuyor: "5" görüp bunun döngü günü olduğunu bilmek
/// gerekiyor. Kullanıcının sorduğu soru genelde "kaçıncı gündeyim" değil,
/// "ne zaman başlayacak".
///
/// Bu servis o soruyu tarihlerle cevaplıyor. Saf: kamera, saat ya da depo
/// bilmeden test edilebiliyor.
class CycleAgenda {
  const CycleAgenda._();

  /// [now] gününden sonraki olayları, tarihe göre sıralı döndürür.
  ///
  /// Bugün olan olaylar listeye girmiyor: "bugün" zaten ekranın üstündeki
  /// cümlede söyleniyor, ajandada tekrar etmesi gereksiz.
  static List<AgendaEntry> upcoming(
    CycleInfo info, {
    required DateTime now,
    int limit = 3,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final entries = <AgendaEntry>[];

    // Aynı olay iki kaynaktan gelebiliyor: `predictedNextPeriod` çoğu zaman
    // `futurePredictions`'ın ilkiyle aynı tarih. Tekilleştirilmeseydi ajandada
    // "16 Eylül · Regl bekleniyor" iki kez yazıyordu.
    final seen = <String>{};

    void add(AgendaKind kind, DateTime? date) {
      if (date == null) return;
      final clean = DateTime(date.year, date.month, date.day);
      final days = clean.difference(today).inDays;
      if (days <= 0) return;
      if (!seen.add('${kind.name}@${clean.toIso8601String()}')) return;
      entries.add(AgendaEntry(kind: kind, date: clean, daysAway: days));
    }

    add(AgendaKind.periodStart, info.predictedNextPeriod);

    // Doğurganlık ve yumurtlama yalnızca izleniyorsa. Hormonal doğum
    // kontrolünde bunları listelemek olmayan bir şeyi vaat ederdi.
    if (info.fertilityTracked) {
      add(AgendaKind.fertileStart, info.fertileWindowStart);
      add(AgendaKind.ovulation, info.ovulationDay);
    }

    for (final prediction in info.futurePredictions) {
      add(AgendaKind.periodStart, prediction.startDate);
      if (info.fertilityTracked) {
        add(AgendaKind.fertileStart, prediction.fertileStart);
      }
    }

    entries.sort((a, b) => a.date.compareTo(b.date));
    return entries.take(limit).toList();
  }
}
