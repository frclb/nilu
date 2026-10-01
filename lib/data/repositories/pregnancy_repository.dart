import 'dart:convert';

import '../local/secure_store.dart';
import '../../domain/models/pregnancy.dart';

/// Gebelik kayıtlarını **şifreli** yerel depoda yönetir.
///
/// Geçmiş gebelikler de saklanıyor, yalnızca süren değil. İki sebebi var:
/// doğum öncesi bakım şeması ilk gebelikte farklı (NHS 10 izlem, sonraki
/// gebelikte 7), ve kullanıcının kendi geçmişi onun verisi — sessizce
/// silmek bizim kararımız değil.
class PregnancyRepository {
  static const String _key = 'pregnancies';

  final SecureStore _store;

  const PregnancyRepository({SecureStore store = const SecureStore()})
    : _store = store;

  /// Tüm gebelikler, eskiden yeniye.
  Future<List<Pregnancy>> getAll() async {
    final raw = await _store.getStringList(_key) ?? const [];

    final kayitlar = <Pregnancy>[];
    for (final json in raw) {
      // Tek bozuk kayıt yüzünden hepsini kaybetmek olmaz.
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map<String, dynamic>) {
          kayitlar.add(Pregnancy.fromMap(decoded));
        }
      } catch (_) {
        continue;
      }
    }

    kayitlar.sort((a, b) => a.confirmedAt.compareTo(b.confirmedAt));
    return kayitlar;
  }

  /// Süren gebelik; yoksa null.
  ///
  /// Aynı anda birden fazla süren kayıt olmamalı ama olursa en yenisi
  /// kazanıyor: kullanıcıya hangisinin geçerli olduğunu sormak yerine
  /// en son söylediğine inanmak daha az yanlış.
  Future<Pregnancy?> getActive() async {
    final hepsi = await getAll();
    for (final p in hepsi.reversed) {
      if (p.isActive) return p;
    }
    return null;
  }

  Future<void> saveAll(List<Pregnancy> kayitlar) => _store.setStringList(
    _key,
    kayitlar.map((p) => jsonEncode(p.toMap())).toList(),
  );

  /// Ekler ya da aynı `id`'li kaydın üzerine yazar.
  Future<void> upsert(Pregnancy kayit) async {
    final hepsi = await getAll();
    final i = hepsi.indexWhere((p) => p.id == kayit.id);
    if (i == -1) {
      hepsi.add(kayit);
    } else {
      hepsi[i] = kayit;
    }
    await saveAll(hepsi);
  }
}
