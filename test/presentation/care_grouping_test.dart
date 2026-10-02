import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/life_stage.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/care_templates.dart';
import 'package:period_tracker/presentation/pregnancy/care_grouping.dart';

void main() {
  final sat = DateTime(2026, 1, 1);
  final g = Pregnancy.fromLmp(
    lmp: sat,
    cycleLength: 28,
    confirmedAt: DateTime(2026, 2, 1),
    id: 'g1',
  );
  final olaylar = CareTemplates.generate(g, CareTemplates.turkeyAntenatal);
  CareEvent kod(String c) => olaylar.singleWhere((e) => e.code == c);

  // 20+0 haftada: anomali taraması (18–22) şimdi, OGTT (24–28) yaklaşan,
  // kombine test (11–14) geçmiş.
  final bugun = sat.add(const Duration(days: 140));

  test('pencereye göre', () {
    expect(CareGrouping.of(kod('tr_screen_anomaly'), g, bugun), CareGroup.now);
    expect(
      CareGrouping.of(kod('tr_screen_ogtt'), g, bugun),
      CareGroup.upcoming,
    );
    expect(
      CareGrouping.of(kod('tr_screen_combined'), g, bugun),
      CareGroup.past,
    );
  });

  test('yapılan geçmişe gidiyor', () {
    expect(
      CareGrouping.of(kod('tr_screen_anomaly').copyWith(done: true), g, bugun),
      CareGroup.past,
    );
  });

  test('yakın randevu "şimdi", uzak randevu "yaklaşan"', () {
    final yarin = kod(
      'tr_screen_ogtt',
    ).copyWith(scheduledAt: bugun.add(const Duration(days: 1, hours: 10)));
    final uzak = kod(
      'tr_screen_ogtt',
    ).copyWith(scheduledAt: bugun.add(const Duration(days: 40)));
    expect(
      CareGrouping.of(yarin, g, bugun),
      CareGroup.now,
      reason: 'Penceresi gelecekte olsa bile yarınki randevu öne çıkmalı',
    );
    expect(CareGrouping.of(uzak, g, bugun), CareGroup.upcoming);
  });

  test('tarihi geçmiş randevu geçmişte', () {
    final dun = kod(
      'tr_screen_anomaly',
    ).copyWith(scheduledAt: bugun.subtract(const Duration(days: 1)));
    expect(CareGrouping.of(dun, g, bugun), CareGroup.past);
  });

  test('tarihsiz kendi kalemi görünür kalıyor', () {
    final o = CareEvent.custom(pregnancyId: 'g1', title: 'Diş hekimi');
    expect(CareGrouping.of(o, g, bugun), CareGroup.now);
  });

  test('lohusalıkta gebelik taramaları gizleniyor', () {
    final dogum = g.ended(
      outcome: PregnancyOutcome.birth,
      at: DateTime(2026, 10, 1),
    );
    final hepsi = [
      ...olaylar,
      ...CareTemplates.generate(dogum, CareTemplates.turkeyPostnatal),
      CareEvent.custom(pregnancyId: 'g1', title: 'Pediatri'),
    ];
    final gorunen = CareGrouping.visible(hepsi, LifeStage.postpartum);

    expect(
      gorunen.where((e) => e.anchor == CareAnchor.gestation && !e.isCustom),
      isEmpty,
    );
    expect(gorunen.map((e) => e.code), contains('tr_pp_visit_5'));
    expect(gorunen.where((e) => e.isCustom), hasLength(1));
    expect(
      CareGrouping.visible(hepsi, LifeStage.pregnancy),
      hasLength(hepsi.length),
    );
  });
}
