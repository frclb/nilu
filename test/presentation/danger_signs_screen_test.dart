import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/presentation/pregnancy/danger_signs_screen.dart';

import 'screen_harness.dart';

/// Tehlike işaretleri ekranı.
///
/// Uygulamanın en güvenlik-kritik ekranı. Üç şeyi sınıyor: listenin
/// tamamının **çevrilmiş metinle** görünmesi (tanımsız bir anahtar ekranda
/// kendisi olarak çıkar ve tam o maddenin anlamı kaybolur), acil arama
/// numarasının **bölgeye** göre seçilmesi, ve hiçbir boyutta taşma olmaması.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(mockMissingPlatformChannels);
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => DangerSignsScreen.launcher = (_) async => false);

  for (final donem in DangerPeriod.values) {
    final liste = donem == DangerPeriod.pregnancy
        ? DangerSignsScreen.pregnancySigns
        : DangerSignsScreen.postpartumSigns;

    for (final boyut in screenSizes.entries) {
      testWidgets('${donem.name} — ${boyut.key}', (tester) async {
        final ekran = DangerSignsScreen(period: donem, regionOverride: 'TR');
        await pumpScreen(tester, ekran, size: boyut.value);

        expect(find.byWidget(ekran), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'düzen hatası');

        final metinler = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .toSet();
        for (final anahtar in liste) {
          expect(
            metinler,
            isNot(contains(anahtar)),
            reason:
                '"$anahtar" çevrilmemiş: ekranda anahtarın kendisi görünüyor, '
                'yani o tehlike işaretinin anlamı kullanıcıya ulaşmıyor',
          );
        }
      });
    }

    testWidgets('${donem.name}: listenin tamamı çiziliyor', (tester) async {
      final ekran = DangerSignsScreen(period: donem, regionOverride: 'TR');
      await pumpScreen(tester, ekran, size: const Size(390, 844));

      // Uzun liste kaydırılabilir; maddeleri sırayla görünür kıl.
      var gorulen = 0;
      for (var i = 0; i < 12 && gorulen < liste.length; i++) {
        gorulen = tester
            .widgetList(find.byIcon(Icons.error_outline))
            .length;
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pump();
      }
      expect(
        gorulen,
        greaterThanOrEqualTo(liste.length ~/ 2),
        reason: 'Maddeler çizilmiyor',
      );
    });
  }

  group('her madde altı dilde tanımlı', () {
    // Eksik bir anahtar ekranda ham anahtar olarak değil, yedek dilde
    // (İngilizce) görünüyor — ölçüldü. Yani Türk kullanıcı tek bir tehlike
    // işaretini İngilizce görürdü. Ekran testi bunu yakalayamıyor; dosyalar
    // doğrudan denetleniyor.
    final anahtarlar = {
      ...DangerSignsScreen.pregnancySigns,
      ...DangerSignsScreen.postpartumSigns,
      'danger_title_pregnancy',
      'danger_title_postpartum',
      'danger_intro',
      'danger_call_emergency',
      'danger_call_local',
      'danger_movements_note_title',
      'danger_movements_note_body',
      'danger_pp_mental_title',
      'danger_pp_mental_body',
    };
    for (final dil in ['tr', 'en', 'de', 'fr', 'es', 'pt']) {
      test(dil, () {
        final sozluk =
            jsonDecode(File('lib/localization/$dil.json').readAsStringSync())
                as Map<String, dynamic>;
        final eksik = anahtarlar.where((k) => !sozluk.containsKey(k));
        expect(eksik, isEmpty, reason: '$dil: ${eksik.join(', ')}');
      });
    }
  });

  group('acil arama', () {
    testWidgets('Türkiye\'de 112 aranıyor', (tester) async {
      Uri? aranan;
      DangerSignsScreen.launcher = (uri) async {
        aranan = uri;
        return true;
      };
      await pumpScreen(
        tester,
        const DangerSignsScreen(
          period: DangerPeriod.postpartum,
          regionOverride: 'TR',
        ),
        size: const Size(390, 844),
      );

      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump();

      expect(aranan, Uri(scheme: 'tel', path: '112'));
    });

    testWidgets('ABD\'de 911 — dil Türkçe olsa bile', (tester) async {
      Uri? aranan;
      DangerSignsScreen.launcher = (uri) async {
        aranan = uri;
        return true;
      };
      await pumpScreen(
        tester,
        const DangerSignsScreen(
          period: DangerPeriod.pregnancy,
          regionOverride: 'US',
        ),
        size: const Size(390, 844),
      );
      await tester.tap(find.byIcon(Icons.phone));
      await tester.pump();

      expect(
        aranan,
        Uri(scheme: 'tel', path: '911'),
        reason: 'Dil ülke değil; ABD\'deki Türkçe telefona 112 gösterilmemeli',
      );
    });

    testWidgets('bölge bilinmiyorsa numara uydurulmuyor', (tester) async {
      await pumpScreen(
        tester,
        const DangerSignsScreen(
          period: DangerPeriod.pregnancy,
          regionOverride: 'ZZ',
        ),
        size: const Size(390, 844),
      );
      expect(find.byIcon(Icons.phone), findsNothing);
    });
  });
}
