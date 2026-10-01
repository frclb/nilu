import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/local/secure_store.dart';
import 'package:period_tracker/data/repositories/pregnancy_repository.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repo = PregnancyRepository();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('gebelik durumu şifreli depoda tutuluyor', () {
    // Uygulamadaki en hassas veri bu. Düz `SharedPreferences`'a düşerse
    // yedekte ve cihaz incelemesinde açıkta kalır.
    expect(
      SecureStore.sensitiveKeys,
      contains('pregnancies'),
      reason: 'Gebelik kaydı hassas anahtarlar listesinde olmalı',
    );
  });

  test('kayıt yoksa boş döner', () async {
    expect(await repo.getAll(), isEmpty);
    expect(await repo.getActive(), isNull);
  });

  test('yazılan kayıt geri okunuyor', () async {
    final g = Pregnancy.fromLmp(
      lmp: DateTime(2026, 1, 1),
      cycleLength: 30,
      confirmedAt: DateTime(2026, 2, 1),
    );
    await repo.upsert(g);

    final hepsi = await repo.getAll();
    expect(hepsi, hasLength(1));
    expect(hepsi.first.id, g.id);
    expect(hepsi.first.estimatedDueDate, g.estimatedDueDate);
    expect((await repo.getActive())?.id, g.id);
  });

  test('aynı kimlikle ikinci yazma üzerine yazar', () async {
    final g = Pregnancy.fromLmp(
      lmp: DateTime(2026, 1, 1),
      cycleLength: 28,
      confirmedAt: DateTime(2026, 2, 1),
    );
    await repo.upsert(g);
    await repo.upsert(
      g.ended(outcome: PregnancyOutcome.birth, at: DateTime(2026, 10, 8)),
    );

    final hepsi = await repo.getAll();
    expect(hepsi, hasLength(1), reason: 'Kopya kayıt oluşmamalı');
    expect(hepsi.first.outcome, PregnancyOutcome.birth);
    expect(await repo.getActive(), isNull);
  });

  test('biten gebelik geçmişte kalıyor, silinmiyor', () async {
    // Bakım şeması ilk gebelikte farklı (NHS 10 izlem, sonraki 7) ve
    // kullanıcının geçmişi onun verisi.
    final ilk = Pregnancy.fromLmp(
      lmp: DateTime(2024, 1, 1),
      cycleLength: 28,
      confirmedAt: DateTime(2024, 2, 1),
      id: 'ilk',
    ).ended(outcome: PregnancyOutcome.birth, at: DateTime(2024, 10, 1));
    final yeni = Pregnancy.fromLmp(
      lmp: DateTime(2026, 1, 1),
      cycleLength: 28,
      confirmedAt: DateTime(2026, 2, 1),
      id: 'yeni',
    );

    await repo.upsert(ilk);
    await repo.upsert(yeni);

    final hepsi = await repo.getAll();
    expect(hepsi.map((p) => p.id), ['ilk', 'yeni'], reason: 'eskiden yeniye');
    expect((await repo.getActive())?.id, 'yeni');
  });

  test('bozuk kayıt ötekileri düşürmüyor', () async {
    final saglam = Pregnancy.fromLmp(
      lmp: DateTime(2026, 1, 1),
      cycleLength: 28,
      confirmedAt: DateTime(2026, 2, 1),
      id: 'saglam',
    );
    await repo.upsert(saglam);

    // Araya elle bozuk bir satır sıkıştır (bozulmuş depo, elle düzenlenmiş
    // yedek). Tek satır yüzünden bütün gebelik geçmişi kaybolamaz.
    const store = SecureStore();
    final mevcut = await store.getStringList('pregnancies') ?? [];
    await store.setStringList('pregnancies', ['{bu json değil', ...mevcut]);

    final hepsi = await repo.getAll();
    expect(hepsi, hasLength(1));
    expect(hepsi.first.id, 'saglam');
  });

  test('birden çok süren kayıtta en yenisi geçerli', () async {
    for (final yil in [2025, 2026]) {
      await repo.upsert(
        Pregnancy.fromLmp(
          lmp: DateTime(yil, 1, 1),
          cycleLength: 28,
          confirmedAt: DateTime(yil, 2, 1),
          id: '$yil',
        ),
      );
    }

    expect(
      (await repo.getActive())?.id,
      '2026',
      reason:
          'Olmaması gereken bir durum ama olursa kullanıcının en son '
          'söylediğine inanmak daha az yanlış',
    );
  });
}
