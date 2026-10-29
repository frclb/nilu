import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:period_tracker/data/datasources/remote/firestore_datasource.dart';

/// Eşleşme sunucusunun bellek içi taklidi.
///
/// Testlerde Firebase yapılandırılmamış; gerçek kaynak "sunucu yok"
/// diyor. Bu sahte kaynak sunucu varmış gibi davranıyor, yazılanları
/// kaydediyor ve istenirse yazımları başarısız kılıyor.
class FakePartnerRemote extends FirestoreDataSource {
  FakePartnerRemote({this.available = true, this.writesSucceed = true});

  bool available;
  bool writesSucceed;

  /// Yayımlanmış kodlar: kod → sahip.
  final Map<String, String> tokens = {};

  /// Sahip → partner listesi.
  final Map<String, List<String>> partners = {};

  /// Paylaşılmış yakınlık durumları: sahip → veri.
  final Map<String, Map<String, dynamic>> intimacy = {};

  /// Bırakılan istekler: kod → istekte bulunanlar.
  final Map<String, Set<String>> requests = {};

  /// Yapılan çağrıların adları, sırayla.
  final List<String> calls = [];

  /// `intimacyStatusStream` için verilecek akış; verilmezse kapanmayan,
  /// sessiz bir akış.
  Stream<DocumentSnapshot<Map<String, dynamic>>> Function(String owner)?
  statusStream;
  int subscriptions = 0;

  @override
  bool get isAvailable => available;

  Future<bool> _write(String name, void Function() op) async {
    calls.add(name);
    if (!available || !writesSucceed) return false;
    op();
    return true;
  }

  @override
  Future<bool> updateIntimacyStatus(String uid, Map<String, dynamic> data) =>
      _write('updateIntimacyStatus', () => intimacy[uid] = data);

  @override
  Future<bool> deleteIntimacyStatus(String uid) =>
      _write('deleteIntimacyStatus', () => intimacy.remove(uid));

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> intimacyStatusStream(
    String ownerUid,
  ) {
    subscriptions++;
    return statusStream?.call(ownerUid) ??
        StreamController<DocumentSnapshot<Map<String, dynamic>>>().stream;
  }

  @override
  Future<bool> publishPairingToken(
    String uid,
    String token, {
    String? previousToken,
  }) => _write('publishPairingToken', () {
    if (previousToken != null) tokens.remove(previousToken);
    tokens[token] = uid;
  });

  @override
  Future<bool> revokePairingToken(String token) =>
      _write('revokePairingToken', () => tokens.remove(token));

  @override
  Future<String?> resolvePairingToken(String token) async {
    calls.add('resolvePairingToken');
    if (!available) throw const PairingUnavailable();
    return tokens[token];
  }

  @override
  Future<bool> requestPairing(String token, String requesterUid) => _write(
    'requestPairing',
    () => requests.putIfAbsent(token, () => {}).add(requesterUid),
  );

  /// `watchOwnPairingRequest` için verilecek akış; verilmezse kapanmayan,
  /// sessiz bir akış.
  Stream<DocumentSnapshot<Map<String, dynamic>>> Function(
    String token,
    String uid,
  )?
  requestStream;
  int requestWatches = 0;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOwnPairingRequest(
    String token,
    String requesterUid,
  ) {
    requestWatches++;
    return requestStream?.call(token, requesterUid) ??
        StreamController<DocumentSnapshot<Map<String, dynamic>>>().stream;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> watchPairingRequests(
    String token,
  ) => const Stream.empty();

  @override
  Future<bool> clearPairingRequest(String token, String requesterUid) => _write(
    'clearPairingRequest',
    () => requests[token]?.remove(requesterUid),
  );

  @override
  Future<bool> approvePartner(String uid, String partnerUid) =>
      _write('approvePartner', () => partners[uid] = [partnerUid]);

  @override
  Future<bool> removePartner(String uid, String partnerUid) =>
      _write('removePartner', () => partners[uid]?.remove(partnerUid));

  @override
  Future<bool> leavePartner({
    required String ownerUid,
    required String myUid,
  }) => _write('leavePartner', () => partners[ownerUid]?.remove(myUid));

  @override
  Future<bool> deleteUserData(
    String uid, {
    String? partnerId,
    String? pairingToken,
  }) => _write('deleteUserData', () {
    intimacy.remove(uid);
    partners.remove(uid);
  });
}

// `DocumentSnapshot` mühürlü; sahtelemek için bilinçli olarak yok sayılıyor.
// ignore: subtype_of_sealed_class
/// Yalnızca `exists` ve `data()` okunuyor; `noSuchMethod` gerisini karşılıyor.
class FakeSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  FakeSnapshot(this._data);

  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
