import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/data/repositories/conception_repository.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/data/repositories/privacy_settings_repository.dart';
import 'package:period_tracker/domain/models/care_event.dart';
import 'package:period_tracker/domain/models/conception_intent.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/backup_import_service.dart';
import 'package:period_tracker/domain/services/care_templates.dart';

/// Gebelik kaydı yedekle birlikte gidip geliyor mu?
///
/// Yedek gebeliği taşımasaydı yeni telefona geri yüklenen gebe bir
/// kullanıcının uygulaması döngü moduna düşerdi: regl kaydı korumasız kalır,
/// tahminler gebelik öncesi SAT'tan yapılır, randevular kaybolur.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bugun = DateTime(2026, 6, 1);
  final gebelik = Pregnancy.fromLmp(
    lmp: DateTime(2026, 2, 1),
    cycleLength: 28,
    confirmedAt: DateTime(2026, 3, 5),
    id: 'g1',
  );
  final kalemler = CareTemplates.generate(
    gebelik,
    CareTemplates.turkeyAntenatal,
  );

  ImportedData birlestir(
    Map<String, dynamic> yedek, {
    List<Pregnancy> cihazdaki = const [],
    List<CareEvent> cihazdakiKalemler = const [],
  }) => BackupImportService.merge(
    json: jsonEncode(yedek),
    periodLogs: const [],
    dailyLogs: const [],
    pregnancies: cihazdaki,
    careEvents: cihazdakiKalemler,
    today: bugun,
  );

  Map<String, dynamic> yedekle({
    List<Pregnancy> gebelikler = const [],
    List<CareEvent> bakim = const [],
  }) => {
    'periodLogs': const [],
    'dailyLogs': const [],
    'pregnancies': gebelikler.map((p) => p.toMap()).toList(),
    'careEvents': bakim.map((e) => e.toMap()).toList(),
  };

  group('birleştirme', () {
    test('boş cihaza gebelik ve randevular geri geliyor', () {
      final s = birlestir(yedekle(gebelikler: [gebelik], bakim: kalemler));

      expect(s.pregnancies.single.id, 'g1');
      expect(s.pregnancies.single.isActive, isTrue);
      expect(s.careEvents, hasLength(kalemler.length));
      expect(s.report.succeeded, isTrue);
      expect(
        s.report.totalAdded,
        1 + kalemler.length,
        reason: 'Kullanıcıya gösterilen sayı gebelik kayıtlarını da saymalı',
      );
    });

    test('cihazdaki kayıt kazanıyor', () {
      // Eski bir yedek, cihazda biten gebeliği "süren" hâline döndüremez.
      final cihazda = gebelik.ended(
        outcome: PregnancyOutcome.birth,
        at: DateTime(2026, 5, 20),
      );
      final s = birlestir(
        yedekle(gebelikler: [gebelik]),
        cihazdaki: [cihazda],
      );

      expect(s.pregnancies.single.isActive, isFalse);
      expect(s.report.alreadyPresent, 1);
    });

    test('ikinci bir süren gebelik oluşturulmuyor', () {
      final baska = Pregnancy.fromLmp(
        lmp: DateTime(2026, 3, 1),
        cycleLength: 28,
        confirmedAt: DateTime(2026, 4, 1),
        id: 'g2',
      );
      final s = birlestir(yedekle(gebelikler: [baska]), cihazdaki: [gebelik]);

      expect(
        s.pregnancies.where((p) => p.isActive),
        hasLength(1),
        reason:
            'Aynı anda iki süren gebelik evre çözümlemesini belirsiz bırakır; '
            'cihazdaki kazanır',
      );
      expect(s.pregnancies.single.id, 'g1');
    });

    test('sahibi olmayan randevu alınmıyor', () {
      final s = birlestir(yedekle(bakim: kalemler));

      expect(
        s.careEvents,
        isEmpty,
        reason:
            'Gebeliği bulunmayan randevu hiçbir ekranda gösterilemez ve '
            'hatırlatılamaz',
      );
      expect(s.report.invalid, kalemler.length);
    });

    test('cihazdaki randevu notu yedekle ezilmiyor', () {
      final cihazda = kalemler.first.copyWith(
        done: true,
        note: 'Sonuç normal',
      );
      final s = birlestir(
        yedekle(gebelikler: [gebelik], bakim: kalemler),
        cihazdaki: [gebelik],
        cihazdakiKalemler: [cihazda],
      );

      final geri = s.careEvents.singleWhere((e) => e.id == cihazda.id);
      expect(geri.done, isTrue);
      expect(geri.note, 'Sonuç normal');
    });

    test('yalnızca gebelik içeren yedek de geçerli', () {
      // Eski biçimde regl/günlük alanı yoksa "yanlış biçim" denmemeli.
      final s = BackupImportService.merge(
        json: jsonEncode({'pregnancies': [gebelik.toMap()]}),
        periodLogs: const [],
        dailyLogs: const [],
        pregnancies: const [],
        careEvents: const [],
        today: bugun,
      );
      expect(s.report.succeeded, isTrue);
      expect(s.pregnancies, hasLength(1));
    });

    test('eski biçimli yedek (gebelik alanı yok) bozulmuyor', () {
      final s = BackupImportService.merge(
        json: jsonEncode({'periodLogs': const [], 'dailyLogs': const []}),
        periodLogs: const [],
        dailyLogs: const [],
        pregnancies: [gebelik],
        careEvents: kalemler,
        today: bugun,
      );
      expect(s.pregnancies, [gebelik], reason: 'Cihazdaki dokunulmadan');
      expect(s.careEvents, hasLength(kalemler.length));
    });
  });

  group('elle bozulmuş yedek', () {
    // Yedek, kullanıcının elle düzenleyebileceği tek girdi.
    Map<String, dynamic> ham(Map<String, dynamic> p) =>
        yedekle()..['pregnancies'] = [p];

    test('yakın gelecekte başlayan gebelik alınmıyor', () {
      // Başlangıç 10 gün sonra: tahmini doğum tarihi makul sınırın içinde
      // kaldığı için yalnızca başlangıç kontrolü yakalayabilir. Aşağıdaki
      // uzak gelecek vakası tahmini doğum tarihi sınırına takılıyor.
      final s = birlestir(
        ham(
          Pregnancy.fromDueDate(
            dueDate: bugun.add(const Duration(days: 290)),
            id: 'yakin',
          ).toMap(),
        ),
      );
      expect(s.pregnancies, isEmpty);
      expect(s.report.invalid, 1);
    });

    test('gelecekte başlayan gebelik alınmıyor', () {
      final s = birlestir(
        ham(
          Pregnancy.fromDueDate(
            dueDate: bugun.add(const Duration(days: 400)),
            id: 'x',
          ).toMap(),
        ),
      );
      expect(s.pregnancies, isEmpty);
      expect(s.report.invalid, 1);
    });

    test('başlangıcından önce biten gebelik alınmıyor', () {
      final m = gebelik.toMap()
        ..['endedAt'] = '2025-01-01'
        ..['outcome'] = 'birth';
      final s = birlestir(ham(m));
      expect(s.pregnancies, isEmpty);
    });

    test('gelecekte biten gebelik alınmıyor', () {
      final m = gebelik.toMap()
        ..['endedAt'] = '2027-01-01'
        ..['outcome'] = 'birth';
      final s = birlestir(ham(m));
      expect(s.pregnancies, isEmpty);
    });

    test('nesne olmayan girdiler sayılıyor, çökmüyor', () {
      final s = birlestir(
        yedekle()
          ..['pregnancies'] = [42, 'metin', null, gebelik.toMap()]
          ..['careEvents'] = ['x', 7],
      );
      expect(s.pregnancies, hasLength(1));
      expect(s.report.invalid, 5);
    });

    test('ters pencereli randevu alınmıyor', () {
      final m = kalemler.first.toMap()
        ..['fromDay'] = 50
        ..['toDay'] = 10;
      final s = birlestir(
        yedekle(gebelikler: [gebelik])..['careEvents'] = [m],
      );
      expect(s.careEvents, isEmpty);
    });
  });

  group('depo uçtan uca', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    test('dışa aktar → temiz cihaza içe aktar', () async {
      const repo = PrivacySettingsRepository();
      await const PregnancyRepository().upsert(gebelik);
      await const CareRepository().addMissing(kalemler);

      final json = await repo.exportDataAsJson();

      // Yeni telefon.
      FlutterSecureStorage.setMockInitialValues({});
      final rapor = await repo.importDataFromJson(json);

      expect(rapor.succeeded, isTrue);
      expect((await const PregnancyRepository().getActive())?.id, 'g1');
      expect(
        await const CareRepository().forPregnancy('g1'),
        hasLength(kalemler.length),
      );
    });

    test('gebelik planlama niyeti taşınıyor', () async {
      const repo = PrivacySettingsRepository();
      await const ConceptionRepository().set(
        ConceptionIntent(since: DateTime(2026, 1, 10)),
      );
      final json = await repo.exportDataAsJson();

      FlutterSecureStorage.setMockInitialValues({});
      await repo.importDataFromJson(json);

      expect(
        (await const ConceptionRepository().get())?.since,
        DateTime(2026, 1, 10),
        reason: 'Kaybolursa ASRM sayacı yeni telefonda sıfırlanır',
      );
    });

    test('hesap silmede gebelik ve randevular da siliniyor', () async {
      await const PregnancyRepository().upsert(gebelik);
      await const CareRepository().addMissing(kalemler);

      // Kullanıcının bastığı gerçek akış.
      await const PrivacySettingsRepository().deleteAllLocalData();

      expect(await const PregnancyRepository().getAll(), isEmpty);
      expect(await const CareRepository().getAll(), isEmpty);
    });

    test('hesap silmede planlama niyeti de siliniyor', () async {
      await const ConceptionRepository().set(
        ConceptionIntent(since: DateTime(2026, 1, 10)),
      );
      await const PrivacySettingsRepository().deleteAllLocalData();
      expect(await const ConceptionRepository().get(), isNull);
    });
  });
}
