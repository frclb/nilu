import 'package:flutter/foundation.dart';

/// Gebeliğin nasıl sonlandığı.
///
/// Liste eksiksiz olmak zorunda: kullanıcının yaşadığı şey burada yoksa
/// uygulamayı kapatmaktan başka yolu kalmıyor. [undisclosed] bilerek var —
/// **sebep hiçbir zaman zorunlu değil.**
enum PregnancyOutcome {
  birth,
  miscarriage,
  termination,
  ectopic,
  stillbirth,

  /// "Artık gebe değilim" — sebep belirtmeden.
  undisclosed,
}

/// Trimester. Sınırlar ACOG'a göre: 1. 0+0–13+6, 2. 14+0–27+6, 3. 28+0–.
enum Trimester { first, second, third }

/// Gebelik yaşı: tam hafta + artan gün.
///
/// Klinikte "24+3" diye yazılıyor ve kullanıcı da hekiminden bunu duyuyor.
/// Tek sayıya (ör. "24. hafta") indirgemek bilgi kaybı.
@immutable
class GestationalAge {
  final int weeks;
  final int days;

  const GestationalAge(this.weeks, this.days);

  int get totalDays => weeks * 7 + days;

  @override
  bool operator ==(Object other) =>
      other is GestationalAge && other.weeks == weeks && other.days == days;

  @override
  int get hashCode => Object.hash(weeks, days);

  @override
  String toString() => '$weeks+$days';
}

/// Bir gebelik.
///
/// Tek doğruluk kaynağı **tahmini doğum tarihi (EDD)**, son adet tarihi
/// değil. Sebep klinik: ilk trimester ultrasonu yapıldıysa gebelik yaşı ona
/// göre atanıyor ve SAT'tan hesaplanan tarih geçersiz kalıyor (ACOG
/// Committee Opinion 700). T.C. Sağlık Bakanlığı rehberi de SAT bilinmiyor
/// ya da şüpheliyse ultrason raporlarına göre belirlenmesini söylüyor.
///
/// Bu yüzden hafta hesabı daima EDD'den geriye doğru yapılıyor: hekim tarihi
/// düzelttiğinde ekrandaki hafta da kendiliğinden düzeliyor. SAT yalnızca
/// referans olarak saklanıyor.
@immutable
class Pregnancy {
  /// Gebeliğin normal süresi (gün). Naegele kuralı.
  static const int termDays = 280;

  /// Döngü uzunluğunun güvenilir sayıldığı aralık.
  ///
  /// `CycleSettingsRepository` ile aynı sınırlar; dışındaki bir değer
  /// (bozuk kayıt, elle düzenlenmiş yedek) tahmini saçmalaştırmasın diye
  /// 28'e düşülüyor.
  static const int minCycleLength = 21;
  static const int maxCycleLength = 45;

  final String id;

  /// Bilinen son adet tarihi. Yalnızca referans — hesap EDD'den yapılıyor.
  final DateTime? lmp;

  final DateTime estimatedDueDate;

  /// Tarih hekimden mi geldi?
  ///
  /// Saklanıyor çünkü klinik olarak anlamlı: hekimin tarihi uygulamanınkini
  /// ezer ve arayüz bunu kullanıcıya söyleyebilmeli.
  final bool dueDateFromClinician;

  final DateTime confirmedAt;
  final PregnancyOutcome? outcome;
  final DateTime? endedAt;

  /// Kurulumda seçilen bakım şablonu (`'tr'`) ya da `null` (kendi
  /// randevularım). Doğumda lohusa şablonunun üretilip üretilmeyeceği buna
  /// bağlı: kendi randevularını tutan kullanıcıya Bakanlık takvimi
  /// dayatılmamalı.
  final String? careTemplate;

  /// Kullanıcının lohusalığı erken bitirip regl takibine döndüğü gün.
  ///
  /// Lohusalık doğumdan sonra 42 gün sürüyor (bkz. `LifeStage`); ilk regl
  /// daha önce gelebilir, kullanıcı lohusa ekranlarını istemeyebilir.
  /// Önceden bu evreden çıkmanın bir yolu yoktu.
  final DateTime? postpartumEndedAt;

  const Pregnancy({
    required this.id,
    required this.estimatedDueDate,
    required this.confirmedAt,
    this.lmp,
    this.dueDateFromClinician = false,
    this.outcome,
    this.endedAt,
    this.careTemplate,
    this.postpartumEndedAt,
  });

  /// Son adet tarihinden kurar.
  ///
  /// Naegele kuralı 28 günlük döngü varsayıyor; yumurtlama geç olduğunda
  /// tahmin erken çıkıyor. Uygulama kullanıcının döngü uzunluğunu zaten
  /// bildiği için düzeltebiliyor — 35 günlük döngüde düz Naegele bir hafta
  /// şaşırırdı.
  factory Pregnancy.fromLmp({
    required DateTime lmp,
    required int cycleLength,
    DateTime? confirmedAt,
    String? id,
    String? careTemplate,
  }) {
    final gun = _day(lmp);
    final guvenilir =
        cycleLength >= minCycleLength && cycleLength <= maxCycleLength;
    final duzeltme = guvenilir ? cycleLength - 28 : 0;

    return Pregnancy(
      id: id ?? _id(confirmedAt ?? DateTime.now()),
      lmp: gun,
      estimatedDueDate: gun.add(Duration(days: termDays + duzeltme)),
      confirmedAt: _day(confirmedAt ?? DateTime.now()),
      careTemplate: careTemplate,
    );
  }

  /// Hekimin verdiği tahmini doğum tarihinden kurar.
  factory Pregnancy.fromDueDate({
    required DateTime dueDate,
    DateTime? lmp,
    DateTime? confirmedAt,
    String? id,
    String? careTemplate,
  }) => Pregnancy(
    id: id ?? _id(confirmedAt ?? DateTime.now()),
    lmp: lmp == null ? null : _day(lmp),
    estimatedDueDate: _day(dueDate),
    dueDateFromClinician: true,
    confirmedAt: _day(confirmedAt ?? DateTime.now()),
    careTemplate: careTemplate,
  );

  /// Tahmini doğum tarihini değiştirir.
  ///
  /// Hekim ilk trimester ultrasonuyla tarihi düzelttiğinde kullanılıyor.
  /// Hafta hesabı ve bakım pencereleri EDD'den türediği için onlar da
  /// kendiliğinden kayıyor (bkz. [gestationStart]).
  Pregnancy withDueDate(DateTime dueDate, {required bool fromClinician}) =>
      Pregnancy(
        id: id,
        lmp: lmp,
        estimatedDueDate: _day(dueDate),
        dueDateFromClinician: fromClinician,
        confirmedAt: confirmedAt,
        outcome: outcome,
        endedAt: endedAt,
        careTemplate: careTemplate,
        postpartumEndedAt: postpartumEndedAt,
      );

  /// Lohusalığı [at] gününde bitirir ("regl takibine dön").
  Pregnancy withPostpartumEndedAt(DateTime at) => Pregnancy(
    id: id,
    lmp: lmp,
    estimatedDueDate: estimatedDueDate,
    dueDateFromClinician: dueDateFromClinician,
    confirmedAt: confirmedAt,
    outcome: outcome,
    endedAt: endedAt,
    careTemplate: careTemplate,
    postpartumEndedAt: _day(at),
  );

  bool get isActive => endedAt == null;

  /// Gebeliğin 0+0 kabul edilen günü (EDD − 280).
  ///
  /// SAT değil: hekim tarihi düzelttiyse bu gün de onunla kayıyor. Döngü
  /// istatistiğinden dışlanacak aralık da buradan başlıyor.
  DateTime get gestationStart =>
      estimatedDueDate.subtract(const Duration(days: termDays));

  /// Verilen gündeki gebelik haftası.
  ///
  /// Başlangıçtan önce ya da gebelik bittikten sonra `null`: olmayan bir
  /// gebeliğin haftasını saymak kullanıcıya hatırlatmaktan başka bir şey
  /// yapmaz.
  GestationalAge? gestationOn(DateTime date) {
    if (!isActive) return null;

    final fark = _day(date).difference(gestationStart).inDays;
    if (fark < 0) return null;

    return GestationalAge(fark ~/ 7, fark % 7);
  }

  Trimester? trimesterOn(DateTime date) {
    final ga = gestationOn(date);
    if (ga == null) return null;

    if (ga.weeks < 14) return Trimester.first;
    if (ga.weeks < 28) return Trimester.second;
    return Trimester.third;
  }

  /// Gebeliği sonlandırır.
  Pregnancy ended({required PregnancyOutcome outcome, DateTime? at}) =>
      Pregnancy(
        id: id,
        lmp: lmp,
        estimatedDueDate: estimatedDueDate,
        dueDateFromClinician: dueDateFromClinician,
        confirmedAt: confirmedAt,
        outcome: outcome,
        endedAt: _day(at ?? DateTime.now()),
        careTemplate: careTemplate,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    if (lmp != null) 'lmp': _iso(lmp!),
    'estimatedDueDate': _iso(estimatedDueDate),
    'dueDateFromClinician': dueDateFromClinician,
    'confirmedAt': _iso(confirmedAt),
    if (outcome != null) 'outcome': outcome!.name,
    if (endedAt != null) 'endedAt': _iso(endedAt!),
    if (careTemplate != null) 'careTemplate': careTemplate,
    if (postpartumEndedAt != null)
      'postpartumEndedAt': _iso(postpartumEndedAt!),
  };

  factory Pregnancy.fromMap(Map<String, dynamic> map) {
    final bitis = _parse(map['endedAt']);
    return Pregnancy(
      id: map['id'] as String? ?? _id(DateTime.now()),
      lmp: _parse(map['lmp']),
      estimatedDueDate: _parse(map['estimatedDueDate']) ?? _day(DateTime.now()),
      dueDateFromClinician: map['dueDateFromClinician'] as bool? ?? false,
      confirmedAt: _parse(map['confirmedAt']) ?? _day(DateTime.now()),
      // Bitiş tarihi varsa sonuç da olmalı: tanınmayan ya da eksik bir sonuç
      // yüzünden kayıt "hâlâ sürüyor" görünmesin.
      outcome: bitis == null ? null : _outcome(map['outcome']),
      endedAt: bitis,
      careTemplate: map['careTemplate'] as String?,
      // Bitişten önce ya da bitişsiz bir lohusalık sonu bozuk kayıt demek;
      // düşüyor (gebeliğin kendisi kalıyor).
      postpartumEndedAt: switch (_parse(map['postpartumEndedAt'])) {
        final son? when bitis != null && !son.isBefore(bitis) => son,
        _ => null,
      },
    );
  }

  /// Tanınmayan sonuç değerini düşürmek yerine "belirtilmedi" sayar.
  ///
  /// İleri sürümde yeni bir sonuç eklenirse eski sürüm kaydı okuyamayıp
  /// atmamalı — bu veri geri getirilemez.
  static PregnancyOutcome _outcome(Object? raw) {
    if (raw is! String) return PregnancyOutcome.undisclosed;
    for (final o in PregnancyOutcome.values) {
      if (o.name == raw) return o;
    }
    return PregnancyOutcome.undisclosed;
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parse(Object? raw) {
    if (raw is! String) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed == null ? null : _day(parsed);
  }

  static String _id(DateTime seed) => 'preg_${seed.microsecondsSinceEpoch}';
}
