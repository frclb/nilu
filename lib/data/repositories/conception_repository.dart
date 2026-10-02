import 'dart:convert';

import '../local/secure_store.dart';
import '../../domain/models/conception_intent.dart';

/// Gebelik planlama niyetini **şifreli** yerel depoda tutar.
class ConceptionRepository {
  static const String _key = 'conception_intent';

  final SecureStore _store;

  const ConceptionRepository({SecureStore store = const SecureStore()})
    : _store = store;

  Future<ConceptionIntent?> get() async {
    final raw = await _store.getString(_key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? ConceptionIntent.fromMap(decoded)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> set(ConceptionIntent? niyet) => niyet == null
      ? _store.remove(_key)
      : _store.setString(_key, jsonEncode(niyet.toMap()));
}
