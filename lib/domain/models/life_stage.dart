import 'pregnancy.dart';

/// Kanamanın bu evrede ne anlama geldiği.
enum BleedingMeaning {
  /// Regl: döngü kaydı.
  period,

  /// Hekime götürülmesi gereken bir bulgu. Regl kaydı **açılmaz**.
  warningSign,

  /// Doğum sonrası beklenen kanama. Regl değil; seyri izlenir, çünkü
  /// azaldıktan sonra yeniden artması bir tehlike işareti.
  lochia,
}

/// Kullanıcının bulunduğu yaşam evresi.
///
/// Uygulamadaki her "kanama kaydı" kararı buradan geçiyor. Önceden bu bilgi
/// dağınık bayraklarla tutuluyordu ve gebelik için yazılan koruma lohusalık
/// için ikinci kez yazılmak üzereydi — bu oturumda defalarca bulunan hata
/// tam olarak buydu: aynı kural iki yerde, biri eskiyor.
///
/// Partner modu burada **yok**: o bir evre değil, bir kullanıcı rolü
/// (partnerin telefonu). Hormonal doğum kontrolü de yok: o, döngü evresinin
/// içinde bir ayar.
///
/// Bkz. `LIFE_STAGES.md` §1.
enum LifeStage {
  cycle,
  pregnancy,
  postpartum;

  /// Lohusalık süresi (gün).
  ///
  /// T.C. Sağlık Bakanlığı Doğum Sonu Bakım Yönetim Rehberi (2018): son
  /// lohusa izlemi doğumu takip eden 30–42. günler arasında.
  static const int postpartumDays = 42;

  /// Doğumla sonuçlanan (lohusalık başlatan) sonuçlar.
  ///
  /// Ölü doğumda da lohia, süt ve lohusa izlemi aynı biçimde geçerli. Erken
  /// kayıplarda lohusa protokolü uygulanmıyor; o durumda döngüye dönülüyor
  /// ve gebelik aralığı istatistikten dışlanıyor (bkz. `CycleBreaks`).
  static const Set<PregnancyOutcome> deliveries = {
    PregnancyOutcome.birth,
    PregnancyOutcome.stillbirth,
  };

  /// Kayıtlardan bugünkü evreyi çıkarır.
  static LifeStage resolve(
    Iterable<Pregnancy> pregnancies, {
    required DateTime today,
  }) {
    final gun = DateTime(today.year, today.month, today.day);

    // Süren gebelik her şeyin önüne geçer: lohusalık penceresi içinde
    // yeniden gebe kalınması nadir ama mümkün.
    if (pregnancies.any((p) => p.isActive)) return LifeStage.pregnancy;

    for (final p in pregnancies) {
      final bitis = p.endedAt;
      if (bitis == null || !deliveries.contains(p.outcome)) continue;

      final gecen = gun.difference(bitis).inDays;
      if (gecen >= 0 && gecen < postpartumDays) return LifeStage.postpartum;
    }

    return LifeStage.cycle;
  }

  BleedingMeaning get bleedingMeaning => switch (this) {
    LifeStage.cycle => BleedingMeaning.period,
    LifeStage.pregnancy => BleedingMeaning.warningSign,
    LifeStage.postpartum => BleedingMeaning.lochia,
  };

  /// Bu evrede kanama regl kaydı açar mı?
  bool get recordsPeriods => bleedingMeaning == BleedingMeaning.period;

  /// Döngü tahminleri (sonraki regl, doğurganlık) gösterilir mi?
  ///
  /// Gebelikte anlamsız; lohusalıkta ilk reglin ne zaman geleceği
  /// öngörülemez — "henüz tahmin edemiyorum" dürüst cevap.
  bool get showsCyclePredictions => this == LifeStage.cycle;
}
