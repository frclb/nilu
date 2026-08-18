/// Rehberli bir seansın tek adımı.
///
/// Metin değil anahtar taşır: servis dile bağımlı olmasın, çeviri sunum
/// katmanında çözülsün.
class SessionStep {
  final String nameKey;
  final String descriptionKey;

  /// Bu adımda kalınacak süre.
  final Duration duration;

  const SessionStep({
    required this.nameKey,
    required this.descriptionKey,
    required this.duration,
  });
}

/// Rehberli seans planları.
///
/// Ekranlarda poz adları, açıklamaları ve süreleri zaten vardı ama "Başlat"
/// düğmesi yalnızca bir bildirim çubuğu gösteriyordu — hiçbir şey
/// başlamıyordu. Aynı içerikten zamanlayıcılı bir akış kuruluyor; yeni bir
/// video ya da varlık gerekmiyor.
class SessionPlan {
  final String titleKey;
  final List<SessionStep> steps;

  const SessionPlan({required this.titleKey, required this.steps});

  /// Seansın toplam süresi.
  Duration get total =>
      steps.fold(Duration.zero, (sum, step) => sum + step.duration);

  /// [elapsed] anında hangi adımda olunduğunu döndürür.
  ///
  /// Seans bittiyse `null`. Sınırda (bir adımın tam bitiş anında) bir sonraki
  /// adım döner: 3 dakikalık ilk adımın 3. dakikasında artık ikinci
  /// adımdayız.
  int? stepIndexAt(Duration elapsed) {
    if (elapsed.isNegative) return 0;
    var boundary = Duration.zero;
    for (var i = 0; i < steps.length; i++) {
      boundary += steps[i].duration;
      if (elapsed < boundary) return i;
    }
    return null;
  }

  /// [index] numaralı adımın seans başından itibaren başlangıç anı.
  Duration startOf(int index) =>
      steps.take(index).fold(Duration.zero, (sum, step) => sum + step.duration);

  /// Regl döneminde yumuşak akış. İçerik ekrandaki poz listesiyle aynı.
  static const yoga = SessionPlan(
    titleKey: 'yoga_title',
    steps: [
      SessionStep(
        nameKey: 'yoga_pose_child',
        descriptionKey: 'yoga_pose_child_desc',
        duration: Duration(minutes: 3),
      ),
      SessionStep(
        nameKey: 'yoga_pose_cat_cow',
        descriptionKey: 'yoga_pose_cat_cow_desc',
        duration: Duration(minutes: 3),
      ),
      SessionStep(
        nameKey: 'yoga_pose_butterfly',
        descriptionKey: 'yoga_pose_butterfly_desc',
        duration: Duration(minutes: 4),
      ),
      SessionStep(
        nameKey: 'yoga_pose_twist',
        descriptionKey: 'yoga_pose_twist_desc',
        duration: Duration(minutes: 3),
      ),
      SessionStep(
        nameKey: 'yoga_pose_legs_up',
        descriptionKey: 'yoga_pose_legs_up_desc',
        duration: Duration(minutes: 4),
      ),
      SessionStep(
        nameKey: 'yoga_pose_savasana',
        descriptionKey: 'yoga_pose_savasana_desc',
        duration: Duration(minutes: 3),
      ),
    ],
  );
}
