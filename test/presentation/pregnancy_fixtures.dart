import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/core/navigation/route_names.dart';
import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/data/repositories/period_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/care_templates.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';
import 'package:period_tracker/presentation/pregnancy/care_list_screen.dart';
import 'package:period_tracker/presentation/pregnancy/care_summary_screen.dart';
import 'package:period_tracker/presentation/pregnancy/danger_signs_screen.dart';
import 'package:period_tracker/presentation/pregnancy/end_pregnancy_screen.dart';
import 'package:period_tracker/presentation/pregnancy/past_pregnancies_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_months_screen.dart';
import 'package:period_tracker/presentation/pregnancy/pregnancy_setup_screen.dart';

/// Gebelik ve lohusalık ekranlarının testlerinde ortak veri.
///
/// Tarihler bugüne göre: ViewModel evreyi gerçek saatten çözüyor, sabit
/// bir tarih bir gün testi sessizce başka evreye düşürürdü.

DateTime get today {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

DateTime daysAgo(int n) => DateTime(today.year, today.month, today.day - n);

void resetStores({bool onboarded = true}) {
  FlutterSecureStorage.setMockInitialValues({});
  SharedPreferences.setMockInitialValues({
    if (onboarded) 'onboarding_complete': true,
  });
}

/// Bugün [weeks]+[days] haftalık süren gebelik.
Future<Pregnancy> seedPregnancy({
  int weeks = 24,
  int days = 2,
  String? template = 'tr',
}) async {
  final lmp = daysAgo(weeks * 7 + days);
  final g = Pregnancy.fromLmp(
    lmp: lmp,
    cycleLength: 28,
    confirmedAt: lmp.add(const Duration(days: 42)),
    id: 'g1',
    careTemplate: template,
  );
  await const PregnancyRepository().upsert(g);
  if (template == 'tr') {
    await const CareRepository().addMissing(
      CareTemplates.generate(g, CareTemplates.turkeyAntenatal),
    );
  }
  return g;
}

/// [daysSinceBirth] gün önce doğumla biten gebelik — lohusalık.
Future<Pregnancy> seedPostpartum({
  int daysSinceBirth = 10,
  String? template = 'tr',
}) async {
  final dogum = daysAgo(daysSinceBirth);
  final lmp = dogum.subtract(const Duration(days: 278));
  final g = Pregnancy.fromLmp(
    lmp: lmp,
    cycleLength: 28,
    confirmedAt: lmp.add(const Duration(days: 42)),
    id: 'g1',
    careTemplate: template,
  );
  final biten = g.ended(outcome: PregnancyOutcome.birth, at: dogum);
  await const PregnancyRepository().upsert(biten);
  if (template == 'tr') {
    await const CareRepository().addMissing([
      ...CareTemplates.generate(g, CareTemplates.turkeyAntenatal),
      ...CareTemplates.generate(biten, CareTemplates.turkeyPostnatal),
    ]);
  }
  return biten;
}

/// 28 günlük üç döngü; sonuncusu [lastStartAgo] gün önce başladı.
Future<void> seedCycles({int lastStartAgo = 20}) =>
    const PeriodRepository().savePeriodLogs([
      for (final once in [lastStartAgo + 56, lastStartAgo + 28, lastStartAgo])
        PeriodLog(
          id: 'p$once',
          startDate: daysAgo(once),
          endDate: daysAgo(once - 4),
        ),
    ]);

/// Ana sekmenin yerine konan işaret: `goNamed(home)` buraya düşüyor.
const String homeMarker = 'ana-ekran';

/// Gebelik ekranlarının gittiği rotalar; ilk ekran `/`.
List<RouteBase> pregnancyRoutes(Widget first) => [
  GoRoute(path: '/', builder: (_, _) => first),
  GoRoute(
    path: '/home',
    name: RouteNames.home,
    builder: (_, _) => const Scaffold(body: Text(homeMarker)),
  ),
  GoRoute(
    path: '/care',
    name: RouteNames.careList,
    builder: (_, _) => const CareListScreen(),
  ),
  GoRoute(
    path: '/danger',
    name: RouteNames.dangerSigns,
    builder: (_, s) => DangerSignsScreen(
      period: DangerPeriod.values.byName(
        s.uri.queryParameters['period'] ?? DangerPeriod.pregnancy.name,
      ),
      regionOverride: 'TR',
    ),
  ),
  GoRoute(
    path: '/pregnancy/end',
    name: RouteNames.endPregnancy,
    builder: (_, _) => const EndPregnancyScreen(),
  ),
  GoRoute(
    path: '/pregnancy/setup',
    name: RouteNames.pregnancySetup,
    builder: (_, _) => const PregnancySetupScreen(),
  ),
  GoRoute(
    path: '/log-entry',
    name: RouteNames.logEntry,
    builder: (_, s) => LogEntryScreen(
      date: DateTime.tryParse(s.uri.queryParameters['date'] ?? ''),
    ),
  ),
  GoRoute(
    path: '/pregnancy/months',
    name: RouteNames.pregnancyMonths,
    builder: (_, _) => const PregnancyMonthsScreen(),
  ),
  GoRoute(
    path: '/care/summary',
    name: RouteNames.careSummary,
    builder: (_, _) => const CareSummaryScreen(),
  ),
  GoRoute(
    path: '/pregnancy/history',
    name: RouteNames.pastPregnancies,
    builder: (_, _) => const PastPregnanciesScreen(),
  ),
  GoRoute(
    path: '/pregnancy/history/:id',
    name: RouteNames.pastPregnancy,
    builder: (_, s) => CareSummaryScreen(pregnancyId: s.pathParameters['id']),
  ),
  GoRoute(
    path: '/premium',
    name: RouteNames.premium,
    builder: (_, _) => const Scaffold(body: Text(premiumMarker)),
  ),
];

/// Ödeme duvarının yerine konan işaret.
const String premiumMarker = 'premium-ekrani';

/// Ekranda çevrilmemiş, anahtarın kendisi olarak duran metinler.
///
/// Çeviri eksikse önce İngilizceye düşülüyor; anahtar hiçbir dilde yoksa
/// ekrana olduğu gibi çıkıyor. Bu ikinci durum burada yakalanıyor, ilki
/// sözlük testinde (`test/localization/pregnancy_keys_test.dart`).
List<String> rawKeysOnScreen(WidgetTester tester) {
  final desen = RegExp(r'^[a-z][a-z0-9]*(_[a-z0-9]+)+$');
  return tester
      .widgetList<Text>(find.byType(Text, skipOffstage: false))
      .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
      .where(desen.hasMatch)
      .toList();
}
