import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/presentation/calendar/widgets/calendar_grid.dart';

/// Takvimdeki regl çubuğu yalnızca **aynı satırdaki** komşuya uzanmalı.
///
/// Komşuluk yalnızca tarihe bakıyordu: satır sonundaki pazar için "ertesi gün
/// de regl" doğru ama o gün yan hücrede değil, bir alt satırın başında.
/// Çubuk hücrenin sağ kenarına kadar düz uzanıp hiçbir şeye bağlanmadan
/// kesiliyordu.
void main() {
  group('takvim satır sınırları', () {
    test('pazartesi satırı başlatır, pazar bitirir', () {
      // 14 Eylül 2026 pazartesi, 13 Eylül pazar.
      final monday = DateTime(2026, 9, 14);
      final sunday = DateTime(2026, 9, 13);

      expect(monday.weekday, DateTime.monday);
      expect(sunday.weekday, DateTime.sunday);

      expect(startsCalendarRow(monday), isTrue);
      expect(endsCalendarRow(monday), isFalse);

      expect(endsCalendarRow(sunday), isTrue);
      expect(startsCalendarRow(sunday), isFalse);
    });

    test('hafta ortası günler satırı ne başlatır ne bitirir', () {
      for (var day = 15; day <= 19; day++) {
        final date = DateTime(2026, 9, day);
        expect(
          startsCalendarRow(date),
          isFalse,
          reason: '$day Eylül satır başı sayılmamalı',
        );
        expect(
          endsCalendarRow(date),
          isFalse,
          reason: '$day Eylül satır sonu sayılmamalı',
        );
      }
    });

    test('bir hafta boyunca tam olarak bir başlangıç ve bir bitiş var', () {
      final week = [
        for (var day = 14; day <= 20; day++) DateTime(2026, 9, day),
      ];
      expect(week.where(startsCalendarRow).length, 1);
      expect(week.where(endsCalendarRow).length, 1);
    });
  });
}
