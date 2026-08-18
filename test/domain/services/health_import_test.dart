import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/health_import.dart';

void main() {
  var counter = 0;
  String nextId() => 'h${counter++}';

  setUp(() => counter = 0);

  HealthFlowDay day(int month, int d) =>
      HealthFlowDay(date: DateTime(2026, month, d));

  PeriodLog period(String id, DateTime start, DateTime end) =>
      PeriodLog(id: id, startDate: start, endDate: end);

  group('gün gün veriyi dönemlere toplama', () {
    test('kayıt yokken boş döner', () {
      expect(HealthImport.toPeriods(const [], nextId: nextId), isEmpty);
    });

    test('ardışık günler tek dönem olur', () {
      final periods = HealthImport.toPeriods([
        day(3, 1), day(3, 2), day(3, 3), day(3, 4),
      ], nextId: nextId);

      expect(periods, hasLength(1));
      expect(periods.first.startDate, DateTime(2026, 3, 1));
      expect(periods.first.endDate, DateTime(2026, 3, 4));
    });

    test('bir günlük boşluk dönemi bölmez', () {
      // Kullanıcı bir günü işaretlemeyi unutmuş olabilir; o boşluk yüzünden
      // tek dönemi ikiye bölmek ortalama döngü uzunluğunu bozar.
      final periods = HealthImport.toPeriods([
        day(3, 1), day(3, 2), day(3, 4), day(3, 5),
      ], nextId: nextId);

      expect(periods, hasLength(1));
      expect(periods.first.endDate, DateTime(2026, 3, 5));
    });

    test('geniş boşluk ayrı dönem üretir', () {
      final periods = HealthImport.toPeriods([
        day(3, 1), day(3, 2),
        day(3, 29), day(3, 30),
      ], nextId: nextId);

      expect(periods, hasLength(2));
      expect(periods[1].startDate, DateTime(2026, 3, 29));
    });

    test('sırasız ve yinelenen günler düzeltilir', () {
      final periods = HealthImport.toPeriods([
        day(3, 3), day(3, 1), day(3, 2), day(3, 2),
      ], nextId: nextId);

      expect(periods, hasLength(1));
      expect(periods.first.startDate, DateTime(2026, 3, 1));
      expect(periods.first.endDate, DateTime(2026, 3, 3));
    });
  });

  group('birleştirme', () {
    final mevcut = [
      period('a', DateTime(2026, 3, 1), DateTime(2026, 3, 5)),
    ];

    test('çakışmayan dönem eklenir', () {
      final gelen = [period('h0', DateTime(2026, 4, 1), DateTime(2026, 4, 4))];

      final merged = HealthImport.merge(existing: mevcut, incoming: gelen);
      expect(merged, hasLength(2));
    });

    test('çakışan dönem kullanıcının kaydını ezmez', () {
      // Elle işaretlenen bir dönemi dış veriyle ezmek, kullanıcının
      // düzeltmesini geri almak olurdu.
      final gelen = [period('h0', DateTime(2026, 3, 3), DateTime(2026, 3, 7))];

      final merged = HealthImport.merge(existing: mevcut, incoming: gelen);
      expect(merged, hasLength(1));
      expect(merged.first.id, 'a');
    });

    test('bitişik ama çakışmayan dönem eklenir', () {
      final gelen = [period('h0', DateTime(2026, 3, 6), DateTime(2026, 3, 9))];

      expect(
        HealthImport.merge(existing: mevcut, incoming: gelen),
        hasLength(2),
      );
    });

    test('sonuç tarihe göre sıralı döner', () {
      final gelen = [
        period('h0', DateTime(2026, 1, 1), DateTime(2026, 1, 4)),
        period('h1', DateTime(2026, 5, 1), DateTime(2026, 5, 4)),
      ];

      final merged = HealthImport.merge(existing: mevcut, incoming: gelen);
      expect(
        merged.map((p) => p.startDate.month).toList(),
        [1, 3, 5],
      );
    });

    test('newOnes yalnızca eklenecekleri sayar', () {
      final gelen = [
        period('h0', DateTime(2026, 3, 3), DateTime(2026, 3, 7)), // çakışıyor
        period('h1', DateTime(2026, 6, 1), DateTime(2026, 6, 4)), // yeni
      ];

      final yeni = HealthImport.newOnes(existing: mevcut, incoming: gelen);
      expect(yeni, hasLength(1));
      expect(yeni.first.id, 'h1');
    });

    test('bitiş tarihi olmayan devam eden dönem de çakışma sayılır', () {
      final devamEden = [
        PeriodLog(id: 'a', startDate: DateTime(2026, 3, 1)),
      ];
      final gelen = [period('h0', DateTime(2026, 3, 1), DateTime(2026, 3, 4))];

      expect(
        HealthImport.merge(existing: devamEden, incoming: gelen),
        hasLength(1),
      );
    });
  });
}
