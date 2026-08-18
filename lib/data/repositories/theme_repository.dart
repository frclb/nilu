import 'package:shared_preferences/shared_preferences.dart';
import '../../design_system/app_flavor.dart';

/// Seçili tema çeşidi.
///
/// Hassas veri değil, yalnızca görünüm tercihi — şifreli depoya gerek yok.
class ThemeRepository {
  static const String _key = 'app_flavor';

  const ThemeRepository();

  Future<AppFlavor> getFlavor() async {
    final prefs = await SharedPreferences.getInstance();
    return AppFlavor.fromName(prefs.getString(_key));
  }

  Future<void> setFlavor(AppFlavor flavor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, flavor.name);
  }

  /// Abonelik bittiğinde ücretsiz temaya döner.
  ///
  /// Aksi hâlde kullanıcı ödemeyi bıraktıktan sonra da premium temayı
  /// kullanmaya devam ederdi.
  Future<AppFlavor> resolveFor({required bool isPremium}) async {
    final stored = await getFlavor();
    if (stored.requiresPremium && !isPremium) return AppFlavor.free;
    return stored;
  }
}
