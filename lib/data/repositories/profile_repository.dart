import '../local/secure_store.dart';

/// Kullanıcının kişisel bilgileri.
///
/// Ad, e-posta ve doğum tarihi kişisel veridir (doğum tarihi sağlık verisiyle
/// birlikte kimliklendirici sayılır), bu yüzden şifreli depoda tutulur.
class ProfileRepository {
  static const String nameKey = 'profile_name';
  static const String emailKey = 'profile_email';
  static const String birthDateKey = 'profile_birth_date';

  final SecureStore _store;

  const ProfileRepository({SecureStore store = const SecureStore()})
    : _store = store;

  Future<String?> getName() => _store.getString(nameKey);
  Future<String?> getEmail() => _store.getString(emailKey);

  Future<DateTime?> getBirthDate() async {
    final raw = await _store.getString(birthDateKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Profili olduğu gibi yazar: `null` alan **silinir** (bulut eşitleme).
  ///
  /// [save] `null`u "dokunma" sayıyor; öbür cihazda silinmiş bir ad
  /// burada kalırdı.
  Future<void> replace({
    String? name,
    String? email,
    DateTime? birthDate,
  }) async {
    (name ?? '').trim().isEmpty
        ? await _store.remove(nameKey)
        : await _store.setString(nameKey, name!.trim());
    (email ?? '').trim().isEmpty
        ? await _store.remove(emailKey)
        : await _store.setString(emailKey, email!.trim());
    birthDate == null
        ? await _store.remove(birthDateKey)
        : await _store.setString(birthDateKey, birthDate.toIso8601String());
  }

  Future<void> save({String? name, String? email, DateTime? birthDate}) async {
    if (name != null) {
      name.trim().isEmpty
          ? await _store.remove(nameKey)
          : await _store.setString(nameKey, name.trim());
    }
    if (email != null) {
      email.trim().isEmpty
          ? await _store.remove(emailKey)
          : await _store.setString(emailKey, email.trim());
    }
    if (birthDate != null) {
      await _store.setString(birthDateKey, birthDate.toIso8601String());
    }
  }
}
