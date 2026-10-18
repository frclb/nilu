import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/services/sync_engine.dart';

/// Son eşitlemenin izi; hesap kimliğine göre ayrı.
///
/// Sağlık verisi değil (özet ve sürüm kimliği), şifresiz tercihlerde
/// durabiliyor. Hesaba göre ayrı tutuluyor: aynı cihazda başka bir hesaba
/// geçilince eski hesabın izi yenisini "zaten eşit" sanmasın.
class PrefsSyncStateStore implements SyncStateStore {
  const PrefsSyncStateStore();

  static String _key(String uid) => 'sync_state_$uid';

  @override
  Future<SyncState> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(uid));
    if (raw == null) return const SyncState();
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      return SyncState(
        lastHash: m['hash'] as String?,
        lastRemoteVersion: m['version'] as String?,
        lastSyncAt: DateTime.tryParse(m['at'] as String? ?? ''),
      );
    } catch (_) {
      return const SyncState();
    }
  }

  @override
  Future<void> save(String uid, SyncState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(uid),
      jsonEncode({
        'hash': state.lastHash,
        'version': state.lastRemoteVersion,
        'at': state.lastSyncAt?.toIso8601String(),
      }),
    );
  }

  @override
  Future<void> clear(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(uid));
  }
}
