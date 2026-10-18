import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:period_tracker/data/datasources/remote/account_auth.dart';
import 'package:period_tracker/domain/models/sync_snapshot.dart';
import 'package:period_tracker/domain/services/sync_engine.dart';

/// Bellekte bir bulut: hesap → (üst bilgi, metin).
class FakeRemote implements SyncRemote {
  final Map<String, (SyncMeta, String)> data = {};
  int uploads = 0;
  int metaReads = 0;
  bool offline = false;
  int _v = 0;

  @override
  bool get isAvailable => true;

  void _check() {
    if (offline) throw const SyncException('offline');
  }

  @override
  Future<SyncMeta?> fetchMeta(String uid) async {
    _check();
    metaReads++;
    return data[uid]?.$1;
  }

  @override
  Future<String> download(String uid, SyncMeta meta) async {
    _check();
    final metin = data[uid]!.$2;
    if (sha256.convert(utf8.encode(metin)).toString() != meta.hash) {
      throw const SyncException('integrity');
    }
    return metin;
  }

  @override
  Future<SyncMeta> upload(String uid, String payload, String hash) async {
    _check();
    uploads++;
    final meta = SyncMeta(version: 'v${++_v}', hash: hash, chunkCount: 1);
    data[uid] = (meta, payload);
    return meta;
  }

  @override
  Future<void> delete(String uid, {bool keepDisabledMarker = false}) async {
    _check();
    if (keepDisabledMarker) {
      data[uid] = (const SyncMeta(disabled: true), '');
    } else {
      data.remove(uid);
    }
  }
}

/// Bir cihaz: kendi verisi ve kendi eşitleme izi.
class FakeDevice implements SyncLocal, SyncStateStore {
  FakeDevice([SyncSnapshot? s]) : snapshot = s ?? SyncSnapshot();
  SyncSnapshot snapshot;
  final Map<String, SyncState> _iz = {};

  @override
  Future<SyncSnapshot> read() async => snapshot;

  @override
  Future<void> write(SyncSnapshot s) async => snapshot = s;

  @override
  Future<SyncState> load(String uid) async => _iz[uid] ?? const SyncState();

  @override
  Future<void> save(String uid, SyncState state) async => _iz[uid] = state;

  @override
  Future<void> clear(String uid) async => _iz.remove(uid);
}

/// Sahte hesap girişi.
class FakeAccountAuth implements AccountAuth {
  FakeAccountAuth({this.available = true});

  bool available;
  AccountUser? _current;
  SignInStatus nextStatus = SignInStatus.signedIn;
  bool switchIdentity = false;
  bool reauthOk = true;
  int reauthCalls = 0;
  String nextUid = 'hesap-1';
  final _changes = StreamController<AccountUser?>.broadcast();

  @override
  bool get isAvailable => available;

  @override
  AccountUser? get currentAccount => _current;

  @override
  Stream<AccountUser?> get accountChanges => _changes.stream;

  @override
  Future<SignInResult> signIn(AccountProvider provider) async {
    if (!available) return const SignInResult(SignInStatus.unavailable);
    if (nextStatus != SignInStatus.signedIn) return SignInResult(nextStatus);
    _current = AccountUser(
      uid: nextUid,
      provider: provider,
      email: 'ada@ornek.com',
    );
    return SignInResult(
      SignInStatus.signedIn,
      user: _current,
      switchedIdentity: switchIdentity,
    );
  }

  @override
  Future<void> signOut() async => _current = null;

  @override
  Future<bool> reauthenticateForDeletion() async {
    reauthCalls++;
    return reauthOk;
  }
}
