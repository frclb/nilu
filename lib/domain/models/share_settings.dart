/// Partnerle hangi verilerin paylaşılacağını belirleyen tercihler.
///
/// Bu bir **gizlilik kontrolüdür**: kullanıcı kapattığı bir alanın partnerine
/// gitmediğinden emin olabilmelidir. Bu yüzden hem kalıcı olarak saklanır hem
/// de paylaşım anında [IntimacyShareService] tarafından uygulanır.
class ShareSettings {
  final bool phaseInfo;
  final bool symptomDetails;
  final bool mood;
  final bool predictions;

  const ShareSettings({
    this.phaseInfo = true,
    this.symptomDetails = true,
    this.mood = false,
    this.predictions = true,
  });

  /// Hiçbir şeyin paylaşılmadığı ayar.
  static const ShareSettings none = ShareSettings(
    phaseInfo: false,
    symptomDetails: false,
    mood: false,
    predictions: false,
  );

  bool get sharesAnything => phaseInfo || symptomDetails || mood || predictions;

  ShareSettings copyWith({
    bool? phaseInfo,
    bool? symptomDetails,
    bool? mood,
    bool? predictions,
  }) {
    return ShareSettings(
      phaseInfo: phaseInfo ?? this.phaseInfo,
      symptomDetails: symptomDetails ?? this.symptomDetails,
      mood: mood ?? this.mood,
      predictions: predictions ?? this.predictions,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShareSettings &&
      other.phaseInfo == phaseInfo &&
      other.symptomDetails == symptomDetails &&
      other.mood == mood &&
      other.predictions == predictions;

  @override
  int get hashCode => Object.hash(phaseInfo, symptomDetails, mood, predictions);
}
