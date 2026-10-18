import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../services/backup_import_service.dart';
import 'care_event.dart';
import 'conception_intent.dart';
import 'daily_log.dart';
import 'period_log.dart';
import 'pregnancy.dart';

/// Döngü ayarlarının eşitlenen kısmı.
///
/// Süreler yalnızca kullanıcı girdiyse dolu: girilmemiş bir süreyi
/// varsayılanla doldurup buluta yazmak, öbür cihazda "kullanıcının
/// söylediği 28" gibi görünürdü.
class SyncCycleSettings {
  final int? cycleLength;
  final int? periodLength;
  final DateTime? updatedAt;
  final bool hormonalContraception;

  const SyncCycleSettings({
    this.cycleLength,
    this.periodLength,
    this.updatedAt,
    this.hormonalContraception = false,
  });

  bool get isEmpty =>
      cycleLength == null &&
      periodLength == null &&
      updatedAt == null &&
      !hormonalContraception;

  Map<String, dynamic> toMap() => {
    'cycleLength': cycleLength,
    'periodLength': periodLength,
    'updatedAt': updatedAt?.toIso8601String(),
    'hormonalContraception': hormonalContraception,
  };

  factory SyncCycleSettings.fromMap(Map<String, dynamic> map) =>
      SyncCycleSettings(
        cycleLength: (map['cycleLength'] as num?)?.toInt(),
        periodLength: (map['periodLength'] as num?)?.toInt(),
        updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
        hormonalContraception: map['hormonalContraception'] as bool? ?? false,
      );
}

/// Profilin eşitlenen kısmı.
class SyncProfile {
  final String? name;
  final String? email;
  final DateTime? birthDate;

  const SyncProfile({this.name, this.email, this.birthDate});

  bool get isEmpty =>
      (name ?? '').isEmpty && (email ?? '').isEmpty && birthDate == null;

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'birthDate': birthDate?.toIso8601String(),
  };

  factory SyncProfile.fromMap(Map<String, dynamic> map) => SyncProfile(
    name: map['name'] as String?,
    email: map['email'] as String?,
    birthDate: DateTime.tryParse(map['birthDate'] as String? ?? ''),
  );
}

/// Buluta giden ve buluttan gelen verinin tamamı.
///
/// Eşitleme kayıt kayıt değil, bütün kopya üzerinden yapılıyor: depolar
/// listeleri bütün olarak yazıyor ve tek tek değişiklik izlemiyor. Bütün
/// kopya, silmenin de öbür cihaza geçmesini sağlıyor — kayıt kayıt
/// birleştirme silinen bir regli geri getirirdi.
///
/// Değişiklik [hash] ile anlaşılıyor; bu yüzden kodlama **kararlı** olmak
/// zorunda: listeler sabit bir anahtarla sıralanıyor, haritaların anahtarları
/// alfabetik yazılıyor. Aynı veri her cihazda aynı metni ve aynı özeti
/// üretmeli, yoksa iki cihaz durmadan birbirinin kopyasını yeniler.
class SyncSnapshot {
  static const String format = 'nilu-sync';
  static const int version = 1;

  final List<PeriodLog> periodLogs;
  final List<DailyLog> dailyLogs;
  final List<Pregnancy> pregnancies;
  final List<CareEvent> careEvents;
  final ConceptionIntent? conception;
  final SyncCycleSettings cycleSettings;
  final SyncProfile profile;

  SyncSnapshot({
    List<PeriodLog> periodLogs = const [],
    List<DailyLog> dailyLogs = const [],
    List<Pregnancy> pregnancies = const [],
    List<CareEvent> careEvents = const [],
    this.conception,
    this.cycleSettings = const SyncCycleSettings(),
    this.profile = const SyncProfile(),
  }) : periodLogs = List.of(periodLogs)
         ..sort(
           (a, b) => a.startDate.compareTo(b.startDate) != 0
               ? a.startDate.compareTo(b.startDate)
               : a.id.compareTo(b.id),
         ),
       dailyLogs = List.of(dailyLogs)..sort((a, b) => a.date.compareTo(b.date)),
       pregnancies = List.of(pregnancies)..sort((a, b) => a.id.compareTo(b.id)),
       careEvents = List.of(careEvents)..sort((a, b) => a.id.compareTo(b.id));

  /// Kullanıcının girdiği hiçbir şey yok mu? Yeni kurulmuş bir cihazın
  /// boş kopyası buluttakinin üstüne yazılmasın diye.
  bool get isEmpty =>
      periodLogs.isEmpty &&
      dailyLogs.where((l) => l.hasContent).isEmpty &&
      pregnancies.isEmpty &&
      careEvents.isEmpty &&
      conception == null &&
      cycleSettings.isEmpty &&
      profile.isEmpty;

  Map<String, dynamic> toMap() => {
    'format': format,
    'version': version,
    'periodLogs': [for (final l in periodLogs) l.toMap()],
    'dailyLogs': [for (final l in dailyLogs) l.toMap()],
    'pregnancies': [for (final p in pregnancies) p.toMap()],
    'careEvents': [for (final e in careEvents) e.toMap()],
    'conceptionIntent': conception?.toMap(),
    'cycleSettings': cycleSettings.toMap(),
    'profile': profile.toMap(),
  };

  /// Kararlı metin: aynı veri, aynı metin.
  String encode() => jsonEncode(_canonical(toMap()));

  /// Değişiklik tespiti ve bütünlük denetimi için SHA-256.
  String get hash => sha256.convert(utf8.encode(encode())).toString();

  static Object? _canonical(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((k) => k.toString()).toList()..sort();
      return {for (final k in keys) k: _canonical(value[k])};
    }
    if (value is List) return [for (final v in value) _canonical(v)];
    return value;
  }

  /// Buluttan gelen metni okur. Biçim ya da sürüm tanınmazsa
  /// [FormatException]: yarım okunmuş bir kopya cihazdakinin üstüne
  /// yazılmamalı.
  static SyncSnapshot decode(String text) {
    final root = jsonDecode(text);
    if (root is! Map<String, dynamic> ||
        root['format'] != format ||
        root['version'] != version) {
      throw const FormatException('Not a nilu sync snapshot');
    }
    List<Map<String, dynamic>> list(String key) => [
      for (final e in (root[key] as List? ?? const []))
        if (e is Map<String, dynamic>) e,
    ];
    final niyet = root['conceptionIntent'];
    final ayar = root['cycleSettings'];
    final profil = root['profile'];
    return SyncSnapshot(
      periodLogs: [for (final m in list('periodLogs')) PeriodLog.fromMap(m)],
      dailyLogs: [for (final m in list('dailyLogs')) DailyLog.fromMap(m)],
      pregnancies: [for (final m in list('pregnancies')) Pregnancy.fromMap(m)],
      careEvents: [for (final m in list('careEvents')) CareEvent.fromMap(m)],
      conception: niyet is Map<String, dynamic>
          ? ConceptionIntent.fromMap(niyet)
          : null,
      cycleSettings: ayar is Map<String, dynamic>
          ? SyncCycleSettings.fromMap(ayar)
          : const SyncCycleSettings(),
      profile: profil is Map<String, dynamic>
          ? SyncProfile.fromMap(profil)
          : const SyncProfile(),
    );
  }

  /// İki cihaz da değiştiyse: ikisinin birleşimi.
  ///
  /// Kurallar yedeği geri yüklemeyle aynı (bkz. [BackupImportService]):
  /// bu cihazdaki kayıt kazanır, öbüründen yalnızca eksik olan eklenir.
  /// Bedeli, iki cihazda aynı anda yapılan bir silmenin geri gelebilmesi —
  /// veri kaybından iyi.
  static SyncSnapshot merge({
    required SyncSnapshot local,
    required SyncSnapshot remote,
  }) {
    final birlesik = BackupImportService.merge(
      json: jsonEncode(remote.toMap()),
      periodLogs: local.periodLogs,
      dailyLogs: local.dailyLogs,
      pregnancies: local.pregnancies,
      careEvents: local.careEvents,
    );
    return SyncSnapshot(
      periodLogs: birlesik.periodLogs,
      dailyLogs: birlesik.dailyLogs,
      pregnancies: birlesik.pregnancies,
      careEvents: birlesik.careEvents,
      conception: local.conception ?? remote.conception,
      cycleSettings: local.cycleSettings.isEmpty
          ? remote.cycleSettings
          : local.cycleSettings,
      profile: SyncProfile(
        name: (local.profile.name ?? '').isNotEmpty
            ? local.profile.name
            : remote.profile.name,
        email: (local.profile.email ?? '').isNotEmpty
            ? local.profile.email
            : remote.profile.email,
        birthDate: local.profile.birthDate ?? remote.profile.birthDate,
      ),
    );
  }
}
