import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/presentation/calendar/view_models/calendar_view_model.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
import 'package:period_tracker/presentation/log_entry/widgets/mood_section.dart';
import 'package:period_tracker/presentation/log_entry/widgets/symptoms_section.dart';

import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// "+" kayıt ekranı günün kaydını **silmemeli**.
///
/// Ekran boş açılıyordu ve kaydedince günün kaydını bütünüyle yenisiyle
/// değiştiriyordu (`CalendarViewModel.updateDailyLog`). Aynı gün takvimden
/// girilen cinsel aktivite ya da lekelenme, lohusa panosundan girilen lohia,
/// sabah girilen belirtiler — akşam "+"ya basıp yalnızca ruh hâli seçen
/// kullanıcının hepsi gidiyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(resetStores);

  Future<CalendarViewModel> ac(WidgetTester tester) async {
    final router = await pumpRouter(
      tester,
      routes: pregnancyRoutes(const SizedBox(key: Key('kok'))),
    );
    final takvim = tester
        .element(find.byKey(const Key('kok')))
        .read<CalendarViewModel>();
    router.pushNamed('log_entry');
    await settleAsync(tester);
    expect(find.byType(LogEntryScreen), findsOneWidget);
    return takvim;
  }

  BuildContext ctx(WidgetTester tester) =>
      tester.element(find.byType(LogEntryScreen));

  Future<void> kaydet(WidgetTester tester) async {
    await tester.tap(find.text(ctx(tester).tr('log_save_button')));
    await settleAsync(tester);
  }

  /// Bölümler ekranın altında kalabiliyor; görünmeyen yere dokunuş boşa
  /// gidiyor ve test sessizce başka bir şey sınıyor.
  Future<void> dokun(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
  }

  Finder belirti(WidgetTester tester, String kod) => find.descendant(
    of: find.byType(SymptomsSection),
    matching: find.text(ctx(tester).tr('log_symptom_$kod')),
  );

  testWidgets('günün kaydı ön dolu; ekranda olmayan alanlar korunuyor', (
    tester,
  ) async {
    await const PeriodRepository().saveDailyLogs([
      DailyLog(
        date: today,
        flowIntensity: 'spotting',
        symptoms: const ['headache'],
        sexualActivity: 'protected',
        notes: 'sabah notu',
      ),
    ]);
    final takvim = await ac(tester);

    // Yalnızca ruh hâli seçiliyor.
    await dokun(
      tester,
      find.descendant(
        of: find.byType(MoodSection),
        matching: find.text(ctx(tester).tr('log_mood_happy')),
      ),
    );
    await kaydet(tester);

    final k = takvim.getDailyLogForDate(today);
    expect(k.moods, ['happy']);
    expect(k.symptoms, ['headache'], reason: 'Sabahki belirti silindi');
    expect(k.flowIntensity, 'spotting', reason: 'Lekelenme silindi');
    expect(
      k.sexualActivity,
      'protected',
      reason: 'Bu ekranda olmayan alan silindi',
    );
    expect(k.notes, 'sabah notu', reason: 'Not silindi');
  });

  testWidgets('ön dolu belirti kaldırılabiliyor', (tester) async {
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: today, symptoms: const ['headache', 'fatigue']),
    ]);
    final takvim = await ac(tester);

    await dokun(tester, belirti(tester, 'headache'));
    await dokun(tester, belirti(tester, 'fatigue'));
    await kaydet(tester);

    expect(
      takvim.getDailyLogForDate(today).symptoms,
      isEmpty,
      reason:
          'Seçimi kaldırılan belirti bir sonraki çizimde geri geliyor '
          've kaydediliyor',
    );
  });

  testWidgets('kaldırılan belirti ekranda da seçili görünmüyor', (
    tester,
  ) async {
    // Seçim her çizimde "boşsa başlangıç değerini yükle" kuralıyla
    // kuruluyordu: ikisi de kaldırılınca çipler yeniden seçili görünüyor,
    // kayıt ise boş kalıyordu. Kullanıcı seçili sandığı çipe dokununca
    // aslında **seçimi kaldırmış** oluyordu.
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: today, symptoms: const ['headache', 'fatigue']),
    ]);
    final takvim = await ac(tester);

    await dokun(tester, belirti(tester, 'headache'));
    await dokun(tester, belirti(tester, 'fatigue'));
    // Boş görünen "baş ağrısı"na yeniden dokunmak onu seçmeli.
    await dokun(tester, belirti(tester, 'headache'));
    await kaydet(tester);

    expect(takvim.getDailyLogForDate(today).symptoms, ['headache']);
  });

  testWidgets('yeni gün: ekran boş açılıyor', (tester) async {
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: daysAgo(1), symptoms: const ['headache']),
    ]);
    final takvim = await ac(tester);
    await kaydet(tester);
    expect(takvim.getDailyLogForDate(today).symptoms, isEmpty);
    expect(
      takvim.getDailyLogForDate(daysAgo(1)).symptoms,
      ['headache'],
      reason: 'Dünkü kayda dokunulmamalı',
    );
  });

  testWidgets('kaydetmeden çıkınca hiçbir şey yazılmıyor', (tester) async {
    await const PeriodRepository().saveDailyLogs([
      DailyLog(date: today, symptoms: const ['headache']),
    ]);
    final takvim = await ac(tester);
    await dokun(tester, belirti(tester, 'headache'));
    GoRouter.of(ctx(tester)).pop();
    await settleAsync(tester);
    expect(takvim.getDailyLogForDate(today).symptoms, ['headache']);
  });
}
