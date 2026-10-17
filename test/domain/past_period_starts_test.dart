import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/domain/models/period_log.dart';
import 'package:period_tracker/domain/services/period_service.dart';

/// Geçmiş başlangıçları toplu ekleme kuralları.
void main() {
  final service = PeriodService();
  final bugun = DateTime(2026, 10, 18);
  DateTime once(int n) => DateTime(bugun.year, bugun.month, bugun.day - n);

  PeriodLog kayit(String id, int basOnce, int bitOnce) =>
      PeriodLog(id: id, startDate: once(basOnce), endDate: once(bitOnce));

  test('her başlangıç beklenen süreli kapalı bir dönem oluyor', () {
    final r = service.addStarts(
      const [],
      [once(60), once(30)],
      today: bugun,
      expectedLength: 4,
    );
    expect(r.added, 2);
    expect(r.logs.map((l) => (l.startDate, l.endDate)), [
      (once(60), once(57)),
      (once(30), once(27)),
    ]);
  });

  test('gelecek gün, kayıtlı gün ve engelli gün atlanıyor', () {
    final mevcut = [kayit('a', 40, 36)];
    final r = service.addStarts(
      mevcut,
      [once(-3), once(38), once(90), once(120)],
      today: bugun,
      expectedLength: 5,
      blocked: (d) => d == once(90),
    );
    expect(r.added, 1, reason: 'Yalnızca 120 gün önce eklenebilir');
    expect(r.logs.map((l) => l.startDate), [once(120), once(40)]);
  });

  test('yeni dönem bir sonraki başlangıca taşmıyor', () {
    final mevcut = [kayit('a', 20, 16)];
    final r = service.addStarts(
      mevcut,
      [once(22)],
      today: bugun,
      expectedLength: 5,
    );
    final yeni = r.logs.firstWhere((l) => l.startDate == once(22));
    expect(yeni.endDate, once(21), reason: 'Beş gün sürseydi 20 günü yutardı');
  });

  test('aynı dönemin içine düşen ikinci seçim yeni dönem açmıyor', () {
    // İki gün arayla iki başlangıç bir döngü değil; büyük olasılıkla aynı
    // dönemin günleri işaretlendi.
    final r = service.addStarts(
      const [],
      [once(50), once(48)],
      today: bugun,
      expectedLength: 5,
    );
    expect(r.added, 1);
    expect(r.logs.single.startDate, once(50));
  });

  test('beklenen süresi dolmamış başlangıç açık kalıyor', () {
    final r = service.addStarts(
      const [],
      [once(1)],
      today: bugun,
      expectedLength: 5,
    );
    expect(r.logs.single.isOngoing, isTrue);
  });

  test('kimlikler tekil, aynı gün iki kez seçilse de bir kayıt', () {
    final r = service.addStarts(
      const [],
      // Saatli tarih günüyle aynı sayılıyor: 50 gün önce, öğleden sonra.
      [once(80), once(80), once(50), once(50).add(const Duration(hours: 15))],
      today: bugun,
    );
    expect(r.added, 2);
    expect(r.logs.map((l) => l.id).toSet(), hasLength(2));
  });
}
