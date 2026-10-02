import 'package:flutter/material.dart' show DateUtils;

import '../models/daily_log.dart';
import '../models/log_vocabulary.dart';
import '../models/period_log.dart';
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

  /// Regl dönemlerinin dışında tekrarlayan kanama.
  ///
  /// NHS ve ACOG'un ayrıca sorduğu bulgu bu: reglin dışında kanama.
  /// Çoğu zaman iyi huylu bir sebebi var (yumurtlama kanaması, yeni bir
  /// doğum kontrol yöntemine alışma) ama tekrar ediyorsa hekimin bilmek
  /// istediği şeylerden biri.
  recurrentIntermenstrualBleeding,
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

  /// Reglin kenarındaki lekelenmeyi "ara kanama" saymamak için bırakılan
  /// pay (dönemin öncesi ve sonrası, gün).
  ///
  /// Reglin hemen öncesinde ya da sonrasında birkaç damla görmek olağan;
  /// onu ara kanama diye işaretlemek yersiz bir uyarı üretirdi.
  static const int perimenstrualBufferDays = 2;

  /// Uyarı için gereken en az ayrı kanama atağı sayısı.
  ///
  /// Tek bir ara kanama uyarı sebebi değil: yumurtlama sırasında görülen
  /// tek seferlik lekelenme yaygın ve iyi huylu. Uyarının anlamı
  /// "tekrarlıyor" — o yüzden iki ayrı atak aranıyor.
  static const int minBleedingEpisodes = 2;

  /// [points] gözlenmiş döngü uzunlukları (en yeniden eskiye ya da tersi;
  /// sıra önemli değil).
  ///
  /// [dailyLogs] ve [periodLogs] verilirse ara kanama da değerlendirilir.
  /// Döngü uyarılarından farklı olarak bu bulgu az sayıda döngüde de
  /// anlamlı, o yüzden [minObservations] eşiğine tabi değil.
  static Set<CycleAlert> evaluate(
    List<CycleLengthPoint> points, {
    required List<DateSpan> breaks,
    List<DailyLog> dailyLogs = const [],
    List<PeriodLog> periodLogs = const [],
  }) {
    final alerts = <CycleAlert>{};

    if (intermenstrualEpisodes(
          dailyLogs: dailyLogs,
          periodLogs: periodLogs,
          breaks: breaks,
        ).length >=
        minBleedingEpisodes) {
      alerts.add(CycleAlert.recurrentIntermenstrualBleeding);
    }

    if (points.length < minObservations) return alerts;
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
    CycleAlert.recurrentIntermenstrualBleeding => 'alert_spotting_title',
  };

  static String bodyKey(CycleAlert alert) => switch (alert) {
    CycleAlert.consistentlyShort => 'alert_short_body',
    CycleAlert.consistentlyLong => 'alert_long_body',
    CycleAlert.highlyVariable => 'alert_variable_body',
    CycleAlert.recurrentIntermenstrualBleeding => 'alert_spotting_body',
  };

  /// Regl dönemlerinin dışında kalan kanama atakları (her atağın ilk günü).
  ///
  /// Arka arkaya gelen günler tek atak sayılıyor: iki gün süren bir
  /// lekelenme, iki ayrı olay değil.
  static List<DateTime> intermenstrualEpisodes({
    required List<DailyLog> dailyLogs,
    required List<PeriodLog> periodLogs,
    required List<DateSpan> breaks,
  }) {
    // Hiç regl kaydı yoksa hangi kanamanın "ara"da kaldığı bilinemez.
    // Böyle bir veriyle uyarı üretmek tahminden ibaret olurdu.
    if (periodLogs.isEmpty) return const [];

    final days =
        dailyLogs
            .where((l) => LogVocabulary.isBleeding(l.flowIntensity))
            .map((l) => DateUtils.dateOnly(l.date))
            .where((d) => !_nearPeriod(d, periodLogs))
            // Gebelikteki kanama tehlike işareti, lohusalıktaki lohia —
            // ikisi de "ara kanama" değil. Sayılsalardı lohusa bir annenin
            // her günü alarm üretir ve hekime giden özet lohiayı ara kanama
            // diye listelerdi. O kanamaların kendi değerlendirmesi var
            // (bkz. `LifeStage.bleedingMeaning`).
            .where((d) => !breaks.any((k) => k.contains(d)))
            .toSet()
            .toList()
          ..sort();

    final episodes = <DateTime>[];
    for (var i = 0; i < days.length; i++) {
      final previous = i == 0 ? null : days[i - 1];
      if (previous == null || days[i].difference(previous).inDays > 1) {
        episodes.add(days[i]);
      }
    }
    return episodes;
  }

  /// [day] bir reglin içinde ya da kenarında mı?
  static bool _nearPeriod(DateTime day, List<PeriodLog> periods) {
    for (final period in periods) {
      final start = DateUtils.dateOnly(period.startDate);
      // Devam eden dönemin bitişi bilinmiyor; modeldeki varsayılan süre
      // kullanılıyor. Fazla kısa tahmin etmek reglin son günlerini "ara
      // kanama" diye işaretlerdi — yani hata payı bu yönde bırakılıyor.
      final end = DateUtils.dateOnly(
        period.endDate ??
            period.startDate.add(
              const Duration(days: PeriodLog.defaultOngoingLength - 1),
            ),
      );

      final from = start.subtract(
        const Duration(days: perimenstrualBufferDays),
      );
      final to = end.add(const Duration(days: perimenstrualBufferDays));

      if (!day.isBefore(from) && !day.isAfter(to)) return true;
    }
    return false;
  }
}
