import 'dart:convert';

import '../local/secure_store.dart';
import '../../domain/models/care_event.dart';

/// Gebelik ve lohusalık bakım kalemlerini (izlem, tarama, destek, aşı,
/// kullanıcının kendi randevuları) **şifreli** yerel depoda tutar.
///
/// Gebelik bittiğinde kalemler silinmiyor: kullanıcının geçmişi onun verisi.
/// Hatırlatıcıların durması depodan değil, plandan geliyor — planlayıcı
/// yalnızca o anki evreye ait gebeliğin kalemlerini planlıyor
/// (bkz. `CareReminders`).
class CareRepository {
  static const String _key = 'care_events';

  final SecureStore _store;

  const CareRepository({SecureStore store = const SecureStore()})
    : _store = store;

  Future<List<CareEvent>> getAll() async {
    final raw = await _store.getStringList(_key) ?? const [];
    final olaylar = <CareEvent>[];
    for (final json in raw) {
      // Tek bozuk satır yüzünden bütün randevular kaybolmasın.
      try {
        final decoded = jsonDecode(json);
        if (decoded is Map<String, dynamic>) {
          olaylar.add(CareEvent.fromMap(decoded));
        }
      } catch (_) {
        continue;
      }
    }
    return olaylar;
  }

  Future<List<CareEvent>> forPregnancy(String pregnancyId) async =>
      (await getAll()).where((e) => e.pregnancyId == pregnancyId).toList();

  Future<void> saveAll(List<CareEvent> olaylar) => _store.setStringList(
    _key,
    olaylar.map((e) => jsonEncode(e.toMap())).toList(),
  );

  /// Ekler ya da aynı kimlikli kalemin üzerine yazar.
  Future<void> upsert(CareEvent olay) async {
    final hepsi = await getAll();
    final i = hepsi.indexWhere((e) => e.id == olay.id);
    if (i == -1) {
      hepsi.add(olay);
    } else {
      hepsi[i] = olay;
    }
    await saveAll(hepsi);
  }

  /// Birden fazla kalemi ekler; zaten var olanlara **dokunmaz**.
  ///
  /// Şablon ikinci kez uygulandığında (ör. uygulama yeniden kurulduktan
  /// sonra) kullanıcının işaretlediği "yapıldı", notlar ve randevu saatleri
  /// sıfırlanmamalı.
  Future<void> addMissing(List<CareEvent> olaylar) async {
    final hepsi = await getAll();
    final mevcut = hepsi.map((e) => e.id).toSet();
    hepsi.addAll(olaylar.where((e) => !mevcut.contains(e.id)));
    await saveAll(hepsi);
  }

  Future<void> remove(String id) async {
    final hepsi = await getAll()
      ..removeWhere((e) => e.id == id);
    await saveAll(hepsi);
  }
}
