import 'package:flutter/foundation.dart';

/// "Gebe kalmak istiyorum" niyeti.
///
/// Ayrı bir evre değil: döngü evresinin içinde bir niyet. Veriyi değiştirmiyor,
/// vurguyu değiştiriyor (bkz. `LIFE_STAGES.md` §1, §3).
@immutable
class ConceptionIntent {
  /// Denemeye başlanan gün.
  final DateTime since;

  ConceptionIntent({required DateTime since})
    : since = DateTime(since.year, since.month, since.day);

  /// Hekime başvurmanın önerildiği gün.
  ///
  /// ASRM (2021): 35 yaş altında 12 ay, 35 ve üstünde 6 ay denemeden sonra
  /// değerlendirme. Yaş değerlendirme anına göre: 34 yaşında başlayıp 9. ayda
  /// 35'ine basan için eşik 35. yaş günü. Doğum tarihi bilinmiyorsa 12 ay.
  ///
  /// 40 ve üstünde `null`: ASRM "daha erken" diyor ama bir sayı vermiyor.
  /// Uydurma bir ay koymaktansa baştan söylemek dürüst ([consultEarly]).
  DateTime? consultAt({required DateTime? birthDate}) {
    final oniki = DateTime(since.year, since.month + 12, since.day);
    if (birthDate == null) return oniki;
    if (consultEarly(birthDate: birthDate)) return null;

    final alti = DateTime(since.year, since.month + 6, since.day);
    final otuzBes = DateTime(
      birthDate.year + 35,
      birthDate.month,
      birthDate.day,
    );
    if (!otuzBes.isAfter(alti)) return alti;
    if (!otuzBes.isAfter(oniki)) return otuzBes;
    return oniki;
  }

  /// 40 yaş ve üstü: değerlendirme beklemeden önerilir.
  bool consultEarly({required DateTime? birthDate}) {
    if (birthDate == null) return false;
    final kirk = DateTime(birthDate.year + 40, birthDate.month, birthDate.day);
    return !since.isBefore(kirk);
  }

  Map<String, dynamic> toMap() => {'since': since.toIso8601String()};

  static ConceptionIntent? fromMap(Map<String, dynamic> map) {
    final raw = map['since'];
    final parsed = raw is String ? DateTime.tryParse(raw) : null;
    return parsed == null ? null : ConceptionIntent(since: parsed);
  }
}
