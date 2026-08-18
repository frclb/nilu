import '../models/cycle_info.dart';

/// Bir evre için önerilen aktivitenin türü.
///
/// İkon seçimi sunum katmanının işi; bu servis `material` içe aktarmadan saf
/// kalabilsin diye burada yalnızca tür var.
enum PhaseActivity { yinYoga, strength, cardio, meditation, gentle }

/// Bir döngü evresinde gösterilecek içeriğin çeviri anahtarları.
///
/// Metnin kendisini değil anahtarını taşır: servis dile bağımlı olmasın,
/// çeviri `context.tr` ile sunum katmanında çözülsün.
class PhaseGuidance {
  /// Evrenin adı ("Regl", "Foliküler Faz" …).
  final String titleKey;

  /// "Vücudunda şu an ne oluyor" açıklaması.
  final String bodyKey;

  /// O evre için kısa, uygulanabilir öneri.
  final String tipKey;

  final String activityTitleKey;
  final String activityDescKey;
  final int activityMinutes;
  final PhaseActivity activity;

  const PhaseGuidance({
    required this.titleKey,
    required this.bodyKey,
    required this.tipKey,
    required this.activityTitleKey,
    required this.activityDescKey,
    required this.activityMinutes,
    required this.activity,
  });
}

/// Döngü evresini gösterilecek içeriğe eşler.
///
/// Ana ekrandaki öneri kartı ile takvimdeki gün özeti aynı evre için farklı
/// şeyler söylemesin diye tek kaynak burası. Takvimde ayrıca **seçili günün**
/// evresi kullanılıyor; kullanıcı 20 gün sonrasına bakarken bugünün önerisini
/// okumak anlamsızdı.
class PhaseGuide {
  const PhaseGuide._();

  static const Map<CyclePhase, PhaseGuidance> _table = {
    CyclePhase.menstruation: PhaseGuidance(
      titleKey: 'phase_title_menstruation',
      bodyKey: 'phase_body_menstruation',
      tipKey: 'phase_tip_menstruation',
      activityTitleKey: 'suggestion_yin_yoga_title',
      activityDescKey: 'suggestion_yin_yoga_desc',
      activityMinutes: 15,
      activity: PhaseActivity.yinYoga,
    ),
    CyclePhase.follicular: PhaseGuidance(
      titleKey: 'phase_title_follicular',
      bodyKey: 'phase_body_follicular',
      tipKey: 'phase_tip_follicular',
      activityTitleKey: 'suggestion_energy_title',
      activityDescKey: 'suggestion_energy_desc',
      activityMinutes: 25,
      activity: PhaseActivity.strength,
    ),
    CyclePhase.ovulation: PhaseGuidance(
      titleKey: 'phase_title_ovulation',
      bodyKey: 'phase_body_ovulation',
      tipKey: 'phase_tip_ovulation',
      activityTitleKey: 'suggestion_hiit_title',
      activityDescKey: 'suggestion_hiit_desc',
      activityMinutes: 30,
      activity: PhaseActivity.cardio,
    ),
    CyclePhase.luteal: PhaseGuidance(
      titleKey: 'phase_title_luteal',
      bodyKey: 'phase_body_luteal',
      tipKey: 'phase_tip_luteal',
      activityTitleKey: 'suggestion_meditation_title',
      activityDescKey: 'suggestion_meditation_desc',
      activityMinutes: 10,
      activity: PhaseActivity.meditation,
    ),
    CyclePhase.unknown: PhaseGuidance(
      titleKey: 'phase_title_unknown',
      bodyKey: 'phase_body_unknown',
      tipKey: 'phase_tip_unknown',
      activityTitleKey: 'suggestion_wellness_title',
      activityDescKey: 'suggestion_wellness_desc',
      activityMinutes: 15,
      activity: PhaseActivity.gentle,
    ),
  };

  static PhaseGuidance forPhase(CyclePhase phase) => _table[phase]!;

  /// Bu servisin kullandığı tüm çeviri anahtarları.
  ///
  /// Testin, tabloya yeni bir evre eklendiğinde çevirisi unutulmuş anahtarı
  /// yakalayabilmesi için.
  static Iterable<String> get allKeys => _table.values.expand(
    (g) => [
      g.titleKey,
      g.bodyKey,
      g.tipKey,
      g.activityTitleKey,
      g.activityDescKey,
    ],
  );
}
