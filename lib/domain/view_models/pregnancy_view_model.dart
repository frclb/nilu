import 'package:flutter/foundation.dart';

import '../../data/repositories/care_repository.dart';
import '../../data/repositories/conception_repository.dart';
import '../../data/repositories/pregnancy_repository.dart';
import '../models/care_event.dart';
import '../models/conception_intent.dart';
import '../models/life_stage.dart';
import '../models/pregnancy.dart';
import '../services/care_templates.dart';
import '../services/pregnancy_calendar.dart';

/// Gebelik, bakım kalemleri ve gebelik planlama niyeti — bellekteki tek
/// kaynak.
///
/// Takvim koruması (`CalendarViewModel`) evreyi buradan alıyor
/// (bkz. `main.dart`'taki `ChangeNotifierProxyProvider`). Her işlem önce
/// depoya yazıp sonra burayı güncelliyor: ikisi ayrışırsa uygulamanın iki
/// parçası farklı evrede olduğunu sanar — gebeliği bitirmiş kullanıcı regl
/// işaretleyemez ya da gebe kullanıcı işaretleyebilir.
class PregnancyViewModel extends ChangeNotifier {
  PregnancyViewModel({
    PregnancyRepository pregnancies = const PregnancyRepository(),
    CareRepository care = const CareRepository(),
    ConceptionRepository conception = const ConceptionRepository(),
    DateTime Function()? clock,
  }) : _pregnancyRepo = pregnancies,
       _careRepo = care,
       _conceptionRepo = conception,
       _clock = clock ?? DateTime.now;

  final PregnancyRepository _pregnancyRepo;
  final CareRepository _careRepo;
  final ConceptionRepository _conceptionRepo;
  final DateTime Function() _clock;

  List<Pregnancy> _pregnancies = const [];
  List<CareEvent> _events = const [];
  ConceptionIntent? _conception;
  bool _loaded = false;
  int _revision = 0;

  bool get loaded => _loaded;
  List<Pregnancy> get pregnancies => _pregnancies;
  ConceptionIntent? get conception => _conception;

  /// Her değişiklikte artıyor. Takvim ViewModel'i aynı sürümü ikinci kez
  /// uygulamamak için bunu kullanıyor.
  int get revision => _revision;

  LifeStage get stage => LifeStage.resolve(_pregnancies, today: _clock());

  /// Evreye ait gebelik: gebelikte süren, lohusalıkta doğumla biten.
  Pregnancy? get current =>
      LifeStage.relevantPregnancy(_pregnancies, today: _clock());

  /// O anki gebeliğin bakım kalemleri, gösterim sırasıyla
  /// (bkz. `CareOrder`: önce izlem, tarama ve aşı; destekler sonda).
  List<CareEvent> get currentEvents {
    final g = current;
    if (g == null) return const [];
    return eventsOf(g);
  }

  /// [p] gebeliğinin bakım kalemleri, gösterim sırasıyla.
  List<CareEvent> eventsOf(Pregnancy p) =>
      CareOrder.sorted(_events.where((e) => e.pregnancyId == p.id), p);

  /// Biten gebelikler, en son biten önce (geçmiş gebelikler).
  List<Pregnancy> get pastPregnancies =>
      _pregnancies.where((p) => !p.isActive).toList()
        ..sort((a, b) => b.endedAt!.compareTo(a.endedAt!));

  /// [date] gününün takvimdeki gebelik bilgisi (bkz. `PregnancyCalendar`).
  PregnancyDayInfo dayInfo(DateTime date) => PregnancyCalendar.dayInfo(
    pregnancies: _pregnancies,
    events: _events,
    date: date,
  );

  Future<void> load() async {
    _pregnancies = await _pregnancyRepo.getAll();
    _events = await _careRepo.getAll();
    _conception = await _conceptionRepo.get();
    _loaded = true;
    _changed();
  }

  // ─── Gebelik ───

  Future<Pregnancy> startFromLmp({
    required DateTime lmp,
    required int cycleLength,
    String? careTemplate,
  }) => _start(
    Pregnancy.fromLmp(
      lmp: lmp,
      cycleLength: cycleLength,
      confirmedAt: _clock(),
      careTemplate: careTemplate,
    ),
  );

  Future<Pregnancy> startFromDueDate({
    required DateTime dueDate,
    DateTime? lmp,
    String? careTemplate,
  }) => _start(
    Pregnancy.fromDueDate(
      dueDate: dueDate,
      lmp: lmp,
      confirmedAt: _clock(),
      careTemplate: careTemplate,
    ),
  );

  Future<Pregnancy> _start(Pregnancy yeni) async {
    // Süren gebelik varken ikincisi açılmıyor: evre çözümlemesi belirsiz
    // kalırdı. Çift dokunuş ya da geri tuşuyla tekrar gelinen ekran buraya
    // ikinci kez düşebilir.
    final suren = _pregnancies.where((p) => p.isActive).firstOrNull;
    if (suren != null) return suren;

    await _pregnancyRepo.upsert(yeni);
    if (yeni.careTemplate == 'tr') {
      await _careRepo.addMissing(
        CareTemplates.generate(yeni, CareTemplates.turkeyAntenatal),
      );
    }
    // Artık planlamıyor, gebe: planlama hatırlatıcıları (folik asit, hekime
    // başvuru) susmalı.
    await _conceptionRepo.set(null);

    await _reload();
    return yeni;
  }

  /// Tahmini doğum tarihini düzeltir (ör. hekim ultrasonla yeniden tarihledi).
  Future<void> updateDueDate(
    DateTime dueDate, {
    required bool fromClinician,
  }) async {
    final g = current;
    if (g == null || !g.isActive) return;
    await _pregnancyRepo.upsert(
      g.withDueDate(dueDate, fromClinician: fromClinician),
    );
    await _reload();
  }

  /// Gebeliği sonlandırır. Sebep zorunlu değil: [PregnancyOutcome.undisclosed].
  ///
  /// Kayıtlar silinmiyor; geçmişte kalıyor. Hatırlatıcıların durması
  /// evreden geliyor (bkz. `ReminderPlanner`).
  Future<void> end(PregnancyOutcome outcome, {DateTime? at}) async {
    final g = _pregnancies.where((p) => p.isActive).firstOrNull;
    if (g == null) return;

    final biten = g.ended(outcome: outcome, at: at ?? _clock());
    await _pregnancyRepo.upsert(biten);

    if (LifeStage.deliveries.contains(outcome) && biten.careTemplate == 'tr') {
      await _careRepo.addMissing(
        CareTemplates.generate(biten, CareTemplates.turkeyPostnatal),
      );
    }
    await _reload();
  }

  /// Lohusalığı erken bitirip regl takibine döner.
  ///
  /// Doğum kaydı ve randevular kalıyor; lohusa hatırlatıcıları evreden
  /// geldiği için kendiliğinden duruyor (bkz. `ReminderPlanner`).
  Future<void> endPostpartum() async {
    if (stage != LifeStage.postpartum) return;
    final g = current;
    if (g == null) return;
    await _pregnancyRepo.upsert(g.withPostpartumEndedAt(_clock()));
    await _reload();
  }

  // ─── Bakım kalemleri ───

  /// Kalemi kaydeder. Yalnızca o anki gebeliğin kalemleri yazılabilir.
  Future<void> saveEvent(CareEvent e) async {
    if (current?.id != e.pregnancyId) return;
    await _careRepo.upsert(e);
    await _reload();
  }

  Future<void> addCustomEvent({
    required String title,
    DateTime? scheduledAt,
  }) async {
    final g = current;
    if (g == null || title.trim().isEmpty) return;
    await _careRepo.upsert(
      CareEvent.custom(
        pregnancyId: g.id,
        title: title.trim(),
        scheduledAt: scheduledAt,
      ),
    );
    await _reload();
  }

  Future<void> removeEvent(String id) async {
    final g = current;
    if (g == null) return;
    final e = _events.where((x) => x.id == id).firstOrNull;
    if (e == null || e.pregnancyId != g.id) return;
    await _careRepo.remove(id);
    await _reload();
  }

  // ─── Gebelik planlama ───

  /// Niyeti açar ya da kapatır.
  ///
  /// Zaten açıkken tekrar açmak başlangıç tarihini **değiştirmiyor**: ekran
  /// yeniden açıldığında anahtara tekrar basılırsa ASRM'nin 6/12 aylık sayacı
  /// sıfırlanmamalı.
  Future<void> setConception(bool on) async {
    if (on && _conception != null) return;
    await _conceptionRepo.set(on ? ConceptionIntent(since: _clock()) : null);
    await _reload();
  }

  Future<void> _reload() async {
    _pregnancies = await _pregnancyRepo.getAll();
    _events = await _careRepo.getAll();
    _conception = await _conceptionRepo.get();
    _changed();
  }

  void _changed() {
    _revision++;
    notifyListeners();
  }
}
