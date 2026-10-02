import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:period_tracker/data/local/secure_store.dart';
import 'package:period_tracker/data/repositories/care_repository.dart';
import 'package:period_tracker/domain/models/pregnancy.dart';
import 'package:period_tracker/domain/services/care_templates.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repo = CareRepository();
  final gebelik = Pregnancy.fromLmp(
    lmp: DateTime(2026, 1, 1),
    cycleLength: 28,
    confirmedAt: DateTime(2026, 2, 1),
    id: 'g1',
  );

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('randevular şifreli depoda', () {
    expect(
      SecureStore.sensitiveKeys,
      contains('care_events'),
      reason: '"18–22. hafta: anomali taraması" gebeliği ele veriyor',
    );
  });

  test('şablon yeniden uygulanınca kullanıcının işaretleri korunuyor', () async {
    final olaylar = CareTemplates.generate(
      gebelik,
      CareTemplates.turkeyAntenatal,
    );
    await repo.addMissing(olaylar);

    final ilk = olaylar.first;
    await repo.upsert(
      ilk.copyWith(done: true, note: 'Yapıldı, sonuç normal'),
    );

    // Uygulama yeniden kuruldu, şablon tekrar uygulanıyor.
    await repo.addMissing(
      CareTemplates.generate(gebelik, CareTemplates.turkeyAntenatal),
    );

    final hepsi = await repo.forPregnancy('g1');
    expect(hepsi, hasLength(olaylar.length), reason: 'Kopya oluşmamalı');
    final geri = hepsi.singleWhere((e) => e.id == ilk.id);
    expect(geri.done, isTrue, reason: '"Yapıldı" işareti sıfırlanmamalı');
    expect(geri.note, 'Yapıldı, sonuç normal');
  });

  test('bozuk satır ötekileri düşürmüyor', () async {
    await repo.addMissing(
      CareTemplates.generate(gebelik, CareTemplates.turkeyAntenatal),
    );
    const store = SecureStore();
    final mevcut = await store.getStringList('care_events') ?? [];
    await store.setStringList('care_events', ['{bozuk', ...mevcut]);

    expect(
      await repo.getAll(),
      hasLength(CareTemplates.turkeyAntenatal.length),
    );
  });

  test('gebeliğe göre süzülüyor', () async {
    await repo.addMissing(
      CareTemplates.generate(gebelik, CareTemplates.turkeyAntenatal),
    );
    expect(await repo.forPregnancy('baska'), isEmpty);
  });

  test('kalem silinebiliyor', () async {
    final olaylar = CareTemplates.generate(
      gebelik,
      CareTemplates.turkeyAntenatal,
    );
    await repo.addMissing(olaylar);
    await repo.remove(olaylar.first.id);
    expect(await repo.getAll(), hasLength(olaylar.length - 1));
  });
}
