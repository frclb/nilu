import 'package:shared_preferences/shared_preferences.dart';

/// Kaydedilen içerikler (tarif, yoga, egzersiz).
///
/// Bu ekranlardaki "Kaydet"/"Favorilere Ekle" düğmeleri yalnızca bir snackbar
/// gösteriyordu: kullanıcı kaydettiğini sanıyor, ekrandan çıkınca hiçbir iz
/// kalmıyordu.
class FavoritesRepository {
  static const String _key = 'favorite_content_ids';

  const FavoritesRepository();

  Future<Set<String>> all() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).toSet();
  }

  Future<bool> isFavorite(String id) async => (await all()).contains(id);

  /// Favoriyi ekler veya kaldırır. Yeni durumu döner (true = favoride).
  Future<bool> toggle(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? const []).toSet();

    final added = current.add(id);
    if (!added) current.remove(id);

    await prefs.setStringList(_key, current.toList()..sort());
    return added;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
