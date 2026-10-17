import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/localization/date_names.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/log_entry/log_entry_screen.dart';

import 'all_screens.dart';
import 'pregnancy_fixtures.dart';
import 'screen_harness.dart';

/// Erişilebilirlik taraması: VoiceOver ve büyük yazı.
///
/// - Her dokunma hedefinin bir etiketi var mı (VoiceOver "düğme" deyip
///   susmasın)?
/// - Dokunma hedefleri iOS'un önerdiği 44×44 pt'den küçük mü?
/// - Uygulamanın izin verdiği en büyük yazı ölçeğinde (bkz. `main.dart`,
///   1.5) en dar telefonda düzen taşıyor mu?
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  /// iPhone SE (3. nesil): desteklenen en dar ekran.
  const dar = Size(375, 667);

  /// `main.dart`taki üst sınır.
  const enBuyukOlcek = 1.5;

  for (final entry in allScreens().entries) {
    group(entry.key, () {
      setUp(() {
        FlutterSecureStorage.setMockInitialValues({});
        SharedPreferences.setMockInitialValues({});
      });

      testWidgets('dokunma hedefleri etiketli', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(tester, entry.value, size: screenSizes['iPhone 16e']!);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('dokunma hedefleri en az 44 pt', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(tester, entry.value, size: screenSizes['iPhone 16e']!);
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        handle.dispose();
      });

      testWidgets('en büyük yazıda en dar telefonda taşmıyor', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = enBuyukOlcek;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpScreen(tester, entry.value, size: dar);
        expect(find.byWidget(entry.value), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  }

  group('VoiceOver metinleri', () {
    testWidgets('takvim günü tarihi ve durumu söylüyor', (tester) async {
      resetStores();
      await seedCycles(lastStartAgo: 2);
      final handle = tester.ensureSemantics();
      await pumpScreen(
        tester,
        const CalendarScreen(),
        size: screenSizes['iPhone 16e']!,
      );
      final ctx = tester.element(find.byType(CalendarScreen));
      final bugun = today;
      final etiket = find.bySemanticsLabel(
        RegExp(
          '^${bugun.day} ${ctx.monthName(bugun.month)} ${bugun.year}, '
          '.*${RegExp.escape(ctx.tr('calendar_legend_period'))}',
        ),
      );
      expect(etiket, findsOneWidget);
      handle.dispose();
    });

    testWidgets('kayıt çipleri düğme ve seçim durumu bildiriyor', (
      tester,
    ) async {
      resetStores();
      final handle = tester.ensureSemantics();
      await pumpScreen(
        tester,
        const LogEntryScreen(),
        size: screenSizes['iPhone 16e']!,
      );
      final ctx = tester.element(find.byType(LogEntryScreen));
      final kramp = find.bySemanticsLabel(ctx.tr('log_symptom_cramp'));
      await tester.ensureVisible(kramp.first);
      expect(
        tester.getSemantics(kramp.first),
        containsSemantics(isButton: true, isSelected: false),
      );
      await tester.tap(kramp.first);
      await tester.pump();
      expect(
        tester.getSemantics(kramp.first),
        containsSemantics(isButton: true, isSelected: true),
      );
      handle.dispose();
    });
  });
}
