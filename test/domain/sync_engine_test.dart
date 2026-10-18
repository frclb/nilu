import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/conception_intent.dart';
import 'package:period_tracker/domain/models/daily_log.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/models/sync_snapshot.dart';
import 'package:period_tracker/domain/services/sync_engine.dart';

import '../support/fake_sync.dart';

void main() {
  const uid = 'hesap';
  PeriodLog regl(String id, DateTime bas) => PeriodLog(
    id: id,
    startDate: bas,
    endDate: bas.add(const Duration(days: 4)),
  );

  late FakeRemote bulut;
  SyncEngine motor(FakeDevice d) =>
      SyncEngine(remote: bulut, local: d, state: d);

  setUp(() => bulut = FakeRemote());

  group('SyncSnapshot', () {
    test('kodlama kararlı: sıradan bağımsız aynı metin ve özet', () {
      final a = SyncSnapshot(
        periodLogs: [
          regl('2', DateTime(2026, 2, 1)),
          regl('1', DateTime(2026, 1, 1)),
        ],
      );
      final b = SyncSnapshot(
        periodLogs: [
          regl('1', DateTime(2026, 1, 1)),
          regl('2', DateTime(2026, 2, 1)),
        ],
      );
      expect(a.encode(), b.encode());
      expect(a.hash, b.hash);
    });

    test('gidiş-dönüşte özet aynı kalıyor', () {
      final s = SyncSnapshot(
        periodLogs: [regl('1', DateTime(2026, 1, 1))],
        dailyLogs: [
          DailyLog(
            date: DateTime(2026, 1, 2),
            symptoms: const ['cramp'],
            notes: 'not',
          ),
        ],
        conception: ConceptionIntent(since: DateTime(2025, 12, 1)),
        cycleSettings: const SyncCycleSettings(
          cycleLength: 30,
          hormonalContraception: true,
        ),
        profile: SyncProfile(name: 'Ada', birthDate: DateTime(1995, 5, 5)),
      );
      final geri = SyncSnapshot.decode(s.encode());
      expect(geri.hash, s.hash);
      expect(geri.cycleSettings.cycleLength, 30);
      expect(geri.profile.name, 'Ada');
    });

    test('tanınmayan biçim okunmuyor', () {
      expect(
        () => SyncSnapshot.decode('{"format":"baska","version":1}'),
        throwsFormatException,
      );
    });

    test('boş: kayıt ve ayar yok', () {
      expect(SyncSnapshot().isEmpty, isTrue);
      expect(
        SyncSnapshot(dailyLogs: [DailyLog(date: DateTime(2026, 1, 1))]).isEmpty,
        isTrue,
        reason: 'İçeriksiz gün kaydı veri sayılmaz',
      );
      expect(
        SyncSnapshot(periodLogs: [regl('1', DateTime(2026, 1, 1))]).isEmpty,
        isFalse,
      );
    });

    test(
      'birleşim: kayıtlar toplanıyor, ayar ve profilde bu cihaz kazanıyor',
      () {
        final yerel = SyncSnapshot(
          periodLogs: [regl('a', DateTime(2026, 1, 1))],
          cycleSettings: const SyncCycleSettings(cycleLength: 30),
          profile: const SyncProfile(name: 'Ada'),
        );
        final uzak = SyncSnapshot(
          periodLogs: [regl('b', DateTime(2026, 2, 1))],
          cycleSettings: const SyncCycleSettings(cycleLength: 26),
          profile: const SyncProfile(name: 'Başka', email: 'a@b.c'),
        );
        final m = SyncSnapshot.merge(local: yerel, remote: uzak);
        expect(m.periodLogs.map((l) => l.id), containsAll(['a', 'b']));
        expect(m.cycleSettings.cycleLength, 30);
        expect(m.profile.name, 'Ada');
        expect(m.profile.email, 'a@b.c', reason: 'Bu cihazda boş alan doluyor');
      },
    );
  });

  group('SyncEngine', () {
    test('bulut boş, cihaz dolu: yükleniyor', () async {
      final a = FakeDevice(
        SyncSnapshot(periodLogs: [regl('1', DateTime(2026, 1, 1))]),
      );
      expect(await motor(a).sync(uid), SyncOutcome.uploaded);
      expect(bulut.data[uid]!.$1.hash, a.snapshot.hash);
    });

    test('ikisi de boş: hiçbir şey yazılmıyor', () async {
      expect(await motor(FakeDevice()).sync(uid), SyncOutcome.nothing);
      expect(bulut.uploads, 0);
    });

    test('değişiklik yoksa ikinci eşitleme yüklemiyor', () async {
      final a = FakeDevice(
        SyncSnapshot(periodLogs: [regl('1', DateTime(2026, 1, 1))]),
      );
      await motor(a).sync(uid);
      expect(await motor(a).sync(uid), SyncOutcome.upToDate);
      expect(bulut.uploads, 1);
    });

    test('cihazda değişiklik: yükleniyor', () async {
      final a = FakeDevice(
        SyncSnapshot(periodLogs: [regl('1', DateTime(2026, 1, 1))]),
      );
      await motor(a).sync(uid);
      a.snapshot = SyncSnapshot(
        periodLogs: [
          regl('1', DateTime(2026, 1, 1)),
          regl('2', DateTime(2026, 1, 29)),
        ],
      );
      expect(await motor(a).sync(uid), SyncOutcome.uploaded);
      expect(bulut.data[uid]!.$1.hash, a.snapshot.hash);
    });

    test(
      'yeni telefon: boş cihaza bulut iniyor, üstüne boş yazılmıyor',
      () async {
        final a = FakeDevice(
          SyncSnapshot(periodLogs: [regl('1', DateTime(2026, 1, 1))]),
        );
        await motor(a).sync(uid);

        final b = FakeDevice();
        expect(await motor(b).sync(uid), SyncOutcome.downloaded);
        expect(b.snapshot.hash, a.snapshot.hash);
        expect(bulut.uploads, 1, reason: 'Boş cihaz buluta yazmadı');
      },
    );

    test('silme öbür cihaza geçiyor', () async {
      final a = FakeDevice(
        SyncSnapshot(
          periodLogs: [
            regl('1', DateTime(2026, 1, 1)),
            regl('yanlis', DateTime(2026, 1, 15)),
          ],
        ),
      );
      final b = FakeDevice();
      await motor(a).sync(uid);
      await motor(b).sync(uid);

      a.snapshot = SyncSnapshot(periodLogs: [regl('1', DateTime(2026, 1, 1))]);
      await motor(a).sync(uid);

      expect(await motor(b).sync(uid), SyncOutcome.downloaded);
      expect(b.snapshot.periodLogs.map((l) => l.id), ['1']);
    });

    test('iki cihaz da değiştiyse birleşim iki tarafa yazılıyor', () async {
      final a = FakeDevice(
        SyncSnapshot(periodLogs: [regl('1', DateTime(2026, 1, 1))]),
      );
      final b = FakeDevice();
      await motor(a).sync(uid);
      await motor(b).sync(uid);

      a.snapshot = SyncSnapshot(
        periodLogs: [...a.snapshot.periodLogs, regl('a', DateTime(2026, 2, 1))],
      );
      b.snapshot = SyncSnapshot(
        periodLogs: [...b.snapshot.periodLogs, regl('b', DateTime(2026, 3, 1))],
      );
      await motor(a).sync(uid);

      expect(await motor(b).sync(uid), SyncOutcome.merged);
      expect(b.snapshot.periodLogs.map((l) => l.id), ['1', 'a', 'b']);

      expect(await motor(a).sync(uid), SyncOutcome.downloaded);
      expect(a.snapshot.hash, b.snapshot.hash);
    });

    test(
      'ilk eşitlemede iki dolu cihaz birleşiyor (hiçbiri kaybolmuyor)',
      () async {
        final a = FakeDevice(
          SyncSnapshot(periodLogs: [regl('a', DateTime(2026, 1, 1))]),
        );
        final b = FakeDevice(
          SyncSnapshot(periodLogs: [regl('b', DateTime(2026, 2, 1))]),
        );
        await motor(a).sync(uid);
        expect(await motor(b).sync(uid), SyncOutcome.merged);
        expect(b.snapshot.periodLogs.map((l) => l.id), ['a', 'b']);
      },
    );

    test('başka cihazda kapatıldıysa bu cihaz da duruyor', () async {
      final a = FakeDevice(
        SyncSnapshot(periodLogs: [regl('1', DateTime(2026, 1, 1))]),
      );
      await motor(a).sync(uid);
      await bulut.delete(uid, keepDisabledMarker: true);

      expect(await motor(a).sync(uid), SyncOutcome.disabledRemotely);
      expect(bulut.data[uid]!.$1.disabled, isTrue, reason: 'Yükleme yapılmadı');

      expect(
        await motor(a).sync(uid, resume: true),
        SyncOutcome.uploaded,
        reason: 'Bu cihazda yeniden açılınca işaret kalkıyor',
      );
      expect(bulut.data[uid]!.$1.disabled, isFalse);
    });

    test('bozuk kopya indirilmiyor, cihazdaki veriye dokunulmuyor', () async {
      final a = FakeDevice(
        SyncSnapshot(periodLogs: [regl('1', DateTime(2026, 1, 1))]),
      );
      await motor(a).sync(uid);
      final (meta, _) = bulut.data[uid]!;
      bulut.data[uid] = (meta, '{"bozuk": true}');

      final b = FakeDevice(
        SyncSnapshot(periodLogs: [regl('b', DateTime(2026, 2, 1))]),
      );
      await expectLater(motor(b).sync(uid), throwsA(isA<SyncException>()));
      expect(b.snapshot.periodLogs.map((l) => l.id), ['b']);
    });

    test('çevrimdışı: hata, iz değişmiyor', () async {
      final a = FakeDevice(
        SyncSnapshot(periodLogs: [regl('1', DateTime(2026, 1, 1))]),
      );
      bulut.offline = true;
      await expectLater(motor(a).sync(uid), throwsA(isA<SyncException>()));
      expect((await a.load(uid)).lastHash, isNull);
    });
  });
}
