import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/assistant/assistant_answer.dart';
import 'package:period_tracker/domain/services/assistant/assistant_parser.dart';
import 'package:period_tracker/domain/services/data_export_service.dart';
import 'package:period_tracker/domain/services/prediction_service.dart';
import 'package:period_tracker/localization/app_localizations.dart';
import 'package:period_tracker/localization/relative_time.dart';

/// Sayı 1 olduğunda tekil, fazlaysa çoğul.
///
/// Türkçede tekil/çoğul ayrımı yok ("1 gün", "3 gün"), diğer beş dilde var.
/// Tek anahtarla İngilizce "in 1 days", İspanyolca "hace 1 días" yazıyordu.
/// Çözüm projedeki yerleşik yol: sayı 1 iken `<anahtar>_one` seçiliyor.
Future<AppLocalizations> load(String languageCode) async {
  final localizations = AppLocalizations(Locale(languageCode));
  await localizations.load();
  return localizations;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('sözlükler', () {
    const diller = ['tr', 'en', 'de', 'fr', 'es', 'pt'];
    final sozlukler = {
      for (final d in diller)
        d:
            jsonDecode(File('lib/localization/$d.json').readAsStringSync())
                as Map<String, dynamic>,
    };

    test('her _one anahtarının çoğul eşi var ve altı dilde tanımlı', () {
      final tekiller = sozlukler['tr']!.keys.where((k) => k.endsWith('_one'));
      expect(tekiller, isNotEmpty);
      for (final tekil in tekiller) {
        final cogul = tekil.substring(0, tekil.length - '_one'.length);
        for (final d in diller) {
          expect(sozlukler[d], contains(tekil), reason: '$d: $tekil yok');
          // `notif_lead_one`ın eşi `notif_lead_many`; ötekiler düz ad.
          if (tekil == 'notif_lead_one') continue;
          expect(sozlukler[d], contains(cogul), reason: '$d: $cogul yok');
        }
      }
    });

    test('tekil metinlerde "1" ardından çoğul isim yok', () {
      final cogulIsim = RegExp(
        r'\b1 (days|cycles|Tage|Tagen|Zyklen|días|ciclos|jours|dias)\b',
      );
      for (final d in diller) {
        sozlukler[d]!.forEach((key, value) {
          if (!key.endsWith('_one')) return;
          expect(
            cogulIsim.hasMatch(value as String),
            isFalse,
            reason: '$d/$key: "$value"',
          );
        });
      }
    });
  });

  group('asistan cevapları', () {
    final now = DateTime(2026, 9, 20);
    final today = DateTime(now.year, now.month, now.day);

    /// [araliklar] uzunluğunda döngüler; son regl [sonBaslangic]'ta.
    List<PeriodLog> regller(DateTime sonBaslangic, List<int> araliklar) {
      var bas = sonBaslangic.subtract(
        Duration(days: araliklar.fold(0, (a, b) => a + b)),
      );
      final sonuc = <PeriodLog>[];
      for (var i = 0; i <= araliklar.length; i++) {
        sonuc.add(
          PeriodLog(
            id: 'p$i',
            startDate: bas,
            endDate: bas.add(const Duration(days: 4)),
          ),
        );
        if (i < araliklar.length) bas = bas.add(Duration(days: araliklar[i]));
      }
      return sonuc;
    }

    Future<String> sor(
      String dil,
      AssistantIntent intent,
      List<PeriodLog> logs,
    ) async {
      final cevap = AssistantAnswerBuilder.build(
        AssistantQuery(intent),
        cycleInfo: PredictionService().getCycleInfo(logs, today: today),
        periodLogs: logs,
        dailyLogs: const [],
        now: now,
        breaks: const [],
      );
      return (await load(dil)).translate(cevap.key, params: cevap.params);
    }

    /// 28 günlük döngüler; sonraki regl bugünden [kalan] gün sonra.
    List<PeriodLog> kalanGun(int kalan) =>
        regller(today.add(Duration(days: kalan - 28)), [28, 28]);

    const beklenen = {
      'en': (
        fark1:
            'Your cycles are steady: only 1 day between the shortest '
            'and the longest.',
        fark2:
            'Your cycles are steady: only 2 days between the shortest '
            'and the longest.',
        sonra1: 'expected in 1 day,',
        sonra2: 'expected in 2 days,',
        gecikme1: 'Your period is 1 day late;',
        gecikme2: 'Your period is 2 days late;',
        dongu1: '(based on 1 cycle)',
        dongu2: '(based on 2 cycles)',
      ),
      'es': (
        fark1:
            'Tus ciclos son regulares: solo 1 día entre el más corto y '
            'el más largo.',
        fark2:
            'Tus ciclos son regulares: solo 2 días entre el más corto y '
            'el más largo.',
        sonra1: 'se espera en 1 día,',
        sonra2: 'se espera en 2 días,',
        gecikme1: 'Tu regla lleva 1 día de retraso;',
        gecikme2: 'Tu regla lleva 2 días de retraso;',
        dongu1: '(según 1 ciclo)',
        dongu2: '(según 2 ciclos)',
      ),
    };

    for (final MapEntry(key: dil, value: metin) in beklenen.entries) {
      test('$dil: düzenlilik farkı', () async {
        final son = today.subtract(const Duration(days: 10));
        expect(
          await sor(dil, AssistantIntent.regularity, regller(son, [28, 29])),
          metin.fark1,
        );
        expect(
          await sor(dil, AssistantIntent.regularity, regller(son, [28, 30])),
          metin.fark2,
        );
      });

      test('$dil: sonraki regle kalan gün', () async {
        expect(
          await sor(dil, AssistantIntent.nextPeriod, kalanGun(1)),
          contains(metin.sonra1),
        );
        expect(
          await sor(dil, AssistantIntent.nextPeriod, kalanGun(2)),
          contains(metin.sonra2),
        );
      });

      test('$dil: gecikme', () async {
        expect(
          await sor(dil, AssistantIntent.nextPeriod, kalanGun(-1)),
          startsWith(metin.gecikme1),
        );
        expect(
          await sor(dil, AssistantIntent.nextPeriod, kalanGun(-2)),
          startsWith(metin.gecikme2),
        );
      });

      test('$dil: ortalamaya giren döngü sayısı', () async {
        final son = today.subtract(const Duration(days: 10));
        expect(
          await sor(dil, AssistantIntent.cycleLength, regller(son, [28])),
          contains(metin.dongu1),
        );
        expect(
          await sor(dil, AssistantIntent.cycleLength, regller(son, [28, 28])),
          contains(metin.dongu2),
        );
      });
    }
  });

  group('göreli zaman', () {
    Future<BuildContext> baglam(WidgetTester tester, String dil) async {
      late BuildContext ctx;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [Locale(dil)],
            locale: Locale(dil),
            home: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      return ctx;
    }

    const beklenen = {
      'en': ('1 day ago', '2 days ago'),
      'es': ('hace 1 día', 'hace 2 días'),
    };

    for (final MapEntry(key: dil, value: (bir, iki)) in beklenen.entries) {
      testWidgets('$dil: 1 ve 2 gün önce', (tester) async {
        final ctx = await baglam(tester, dil);
        expect(ctx.relativeTime(const Duration(days: 1)), bir);
        expect(ctx.relativeTime(const Duration(days: 2)), iki);
      });
    }
  });

  group('dışa aktarılan özet', () {
    /// Son iki döngü arasındaki farkı bildiren satır.
    Future<String> farkSatiri(String dil, List<int> araliklar) async {
      final l = await load(dil);
      var bas = DateTime(2026, 1, 1);
      final logs = <PeriodLog>[];
      for (var i = 0; i <= araliklar.length; i++) {
        logs.add(
          PeriodLog(
            id: 'p$i',
            startDate: bas,
            endDate: bas.add(const Duration(days: 4)),
          ),
        );
        if (i < araliklar.length) bas = bas.add(Duration(days: araliklar[i]));
      }
      final satirlar = DataExportService.summarySections(
        periodLogs: logs,
        dailyLogs: const [],
        translate: l.translate,
        breaks: const [],
      ).expand((s) => s.lines);
      final onEk = l.translate('export_variation').split('{days}').first;
      return satirlar.singleWhere((s) => s.startsWith(onEk));
    }

    const beklenen = {
      'en': (
        'Difference between shortest and longest: 1 day',
        'Difference between shortest and longest: 2 days',
      ),
      'es': (
        'Diferencia entre el más corto y el más largo: 1 día',
        'Diferencia entre el más corto y el más largo: 2 días',
      ),
    };

    for (final MapEntry(key: dil, value: (bir, iki)) in beklenen.entries) {
      test('$dil: en kısa ile en uzun arasındaki fark', () async {
        expect(await farkSatiri(dil, [28, 29]), bir);
        expect(await farkSatiri(dil, [28, 30]), iki);
      });
    }
  });
}
