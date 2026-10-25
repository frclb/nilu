import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/localization/date_names.dart';
import 'package:period_tracker/presentation/calendar/calendar_screen.dart';
import 'package:period_tracker/presentation/log_entry/widgets/log_entry_header.dart';

import '../presentation/pregnancy_fixtures.dart';
import '../presentation/screen_harness.dart';

/// Fransızca, İspanyolca ve Portekizcede ay adı cümle içinde küçük harfle
/// yazılıyor ("25 octobre"); yalnızca etiketin başındaysa büyüyor
/// ("Octobre 2026"). Türkçe, İngilizce ve Almancada ay adı hep büyük.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);

  group('capitalizeFirst', () {
    test('yalnızca ilk harfi büyütüyor', () {
      expect(capitalizeFirst('fr', 'octobre 2026'), 'Octobre 2026');
      expect(
        capitalizeFirst('fr', 'août 2025 – mars 2026'),
        'Août 2025 – mars 2026',
      );
      expect(capitalizeFirst('es', 'énfasis'), 'Énfasis');
    });

    test('zaten büyükse ya da harfle başlamıyorsa dokunmuyor', () {
      expect(capitalizeFirst('tr', 'Ekim 2026'), 'Ekim 2026');
      expect(capitalizeFirst('fr', '25 octobre'), '25 octobre');
      expect(capitalizeFirst('fr', ''), '');
    });

    test('Türkçede "i" → "İ"', () {
      expect(capitalizeFirst('tr', 'ilk gün'), 'İlk gün');
      expect(capitalizeFirst('en', 'in'), 'In');
    });
  });

  group('JSON ay adları', () {
    Map<String, dynamic> oku(String dil) =>
        jsonDecode(File('lib/localization/$dil.json').readAsStringSync())
            as Map<String, dynamic>;

    for (final dil in ['fr', 'es', 'pt']) {
      test('$dil: tam ve kısa adlar küçük harf', () {
        final d = oku(dil);
        for (final anahtar in ['calendar_months', 'calendar_months_short']) {
          final adlar = d[anahtar] as String;
          expect(adlar, adlar.toLowerCase(), reason: '$dil $anahtar');
        }
      });
    }

    for (final dil in ['tr', 'en', 'de']) {
      test('$dil: tam ve kısa adlar büyük harfle başlıyor', () {
        final d = oku(dil);
        for (final anahtar in ['calendar_months', 'calendar_months_short']) {
          for (final ad in (d[anahtar] as String).split(',')) {
            expect(ad[0], isNot(ad[0].toLowerCase()), reason: '$dil "$ad"');
          }
        }
      });
    }
  });

  group('ekranda', () {
    testWidgets('takvim başlığı ayla başlıyor: ilk harf büyük', (tester) async {
      resetStores();
      await seedCycles(lastStartAgo: 2);
      await pumpScreen(
        tester,
        const CalendarScreen(),
        size: screenSizes['iPhone 16e']!,
        locale: const Locale('fr'),
      );
      final ctx = tester.element(find.byType(CalendarScreen));
      final ay = ctx.monthName(today.month);
      expect(ay, ay.toLowerCase());
      expect(
        find.text(
          '${ay.substring(0, 1).toUpperCase()}${ay.substring(1)} '
          '${today.year}',
        ),
        findsOneWidget,
      );
    });

    // Gün, ay, yıl ve aynı aydaki aralık. İspanyolca ve Portekizcede
    // araya "de", Almancada günün ardına nokta giriyor.
    const tarihler = {
      'tr': ('25 Ekim', '25 Ekim 2026', '20–23 Ekim'),
      'en': ('25 October', '25 October 2026', '20–23 October'),
      'de': ('25. Oktober', '25. Oktober 2026', '20.–23. Oktober'),
      'es': ('25 de octubre', '25 de octubre de 2026', '20–23 de octubre'),
      'fr': ('25 octobre', '25 octobre 2026', '20–23 octobre'),
      'pt': ('25 de outubro', '25 de outubro de 2026', '20–23 de outubro'),
    };
    for (final MapEntry(key: dil, value: (gunAy, gunAyYil, aralik))
        in tarihler.entries) {
      testWidgets('tarih biçimleri ($dil)', (tester) async {
        late BuildContext ctx;
        await pumpScreen(
          tester,
          Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
          size: screenSizes['iPhone 16e']!,
          locale: Locale(dil),
        );
        final gun = DateTime(2026, 10, 25);
        expect(ctx.dayMonth(gun), gunAy);
        expect(ctx.dayMonthYear(gun), gunAyYil);
        expect(ctx.dayRange(gun, gun), gunAy);
        expect(
          ctx.dayRange(DateTime(2026, 10, 20), DateTime(2026, 10, 23)),
          aralik,
        );
      });
    }

    testWidgets('ay değişen aralık kısa adlarla, küçük harf (fr)', (
      tester,
    ) async {
      late BuildContext ctx;
      await pumpScreen(
        tester,
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
        size: screenSizes['iPhone 16e']!,
        locale: const Locale('fr'),
      );
      expect(
        ctx.dayRange(DateTime(2026, 9, 30), DateTime(2026, 10, 2)),
        '30 sept – 2 oct',
      );
    });

    // Gün önde: ay küçük kalıyor. İngilizcede ay önde ve zaten büyük.
    // Geçmiş bir gün: bugün olsaydı başlık "Bugün, …" olurdu.
    const beklenen = {
      'fr': '25 octobre 2025',
      'es': '25 de octubre de 2025',
      'pt': '25 de outubro de 2025',
      'de': '25. Oktober 2025',
      'en': 'October 25, 2025',
      'tr': '25 Ekim 2025',
    };
    for (final MapEntry(key: dil, value: metin) in beklenen.entries) {
      testWidgets('kayıt başlığı ($dil): "$metin"', (tester) async {
        await pumpScreen(
          tester,
          LogEntryHeader(date: DateTime(2025, 10, 25)),
          size: screenSizes['iPhone 16e']!,
          locale: Locale(dil),
        );
        expect(find.text(metin), findsOneWidget);
      });
    }
  });
}
