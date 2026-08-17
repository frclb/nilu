import 'dart:convert';

/// Kullanıcının duygusal ve fiziksel yakınlık durumunu temsil eden model.
class IntimacyStatus {
  final String sexualDesire;
  final List<String> affectionNeeds;
  final DateTime timestamp;
  final bool isShared;

  IntimacyStatus({
    required this.sexualDesire,
    required this.affectionNeeds,
    required this.timestamp,
    this.isShared = false,
  });

  IntimacyStatus copyWith({
    String? sexualDesire,
    List<String>? affectionNeeds,
    DateTime? timestamp,
    bool? isShared,
  }) {
    return IntimacyStatus(
      sexualDesire: sexualDesire ?? this.sexualDesire,
      affectionNeeds: affectionNeeds ?? List.from(this.affectionNeeds),
      timestamp: timestamp ?? this.timestamp,
      isShared: isShared ?? this.isShared,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sexualDesire': sexualDesire,
      'affectionNeeds': affectionNeeds,
      'timestamp': timestamp.toIso8601String(),
      'isShared': isShared,
    };
  }

  factory IntimacyStatus.fromJson(Map<String, dynamic> json) {
    return IntimacyStatus(
      sexualDesire: json['sexualDesire'] as String? ?? '',
      affectionNeeds:
          (json['affectionNeeds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      isShared: json['isShared'] as bool? ?? false,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory IntimacyStatus.fromJsonString(String jsonStr) {
    return IntimacyStatus.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
  }
}
