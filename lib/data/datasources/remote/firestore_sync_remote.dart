import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../../core/firebase/firebase_config.dart';
import '../../../domain/services/sync_engine.dart';

/// Bulut kopyası Cloud Firestore'da.
///
/// Yapı:
///   syncData/{uid}                -> üst bilgi (sürüm, özet, parça sayısı)
///   syncData/{uid}/chunks/{i}     -> metnin i. parçası
///
/// Firestore'da bir belge en fazla 1 MB; yıllarca kayıt tutmuş bir
/// kullanıcının kopyası bunu aşabilir. Metin [chunkSize] karakterlik
/// parçalara bölünüyor ve hepsi üst bilgiyle **tek bir toplu yazımda**
/// gidiyor: yarısı yazılmış bir kopya hiçbir zaman görünmüyor.
///
/// Kurallar (firestore.rules): yalnızca hesabın sahibi okur ve yazar, ve
/// yalnızca Apple ya da Google ile giriş yapmışsa — anonim partner kimliği
/// bu yola erişemiyor.
class FirestoreSyncRemote implements SyncRemote {
  FirestoreSyncRemote({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;
  FirebaseFirestore get _db => _injected ?? FirebaseFirestore.instance;

  /// Türkçe karakterler UTF-8'de iki bayt: 300 bin karakter en kötü
  /// durumda ~900 KB, 1 MB sınırının altında.
  static const int chunkSize = 300000;

  static const Duration _timeout = Duration(seconds: 30);

  @override
  bool get isAvailable => FirebaseConfig.isAvailable;

  DocumentReference<Map<String, dynamic>> _meta(String uid) =>
      _db.collection('syncData').doc(uid);

  DocumentReference<Map<String, dynamic>> _chunk(String uid, int i) =>
      _meta(uid).collection('chunks').doc('$i');

  Future<T> _guard<T>(String what, Future<T> Function() op) async {
    if (!isAvailable) throw const SyncException('Firebase not configured');
    try {
      return await op().timeout(_timeout);
    } on SyncException {
      rethrow;
    } on TimeoutException {
      throw SyncException('$what timed out');
    } catch (e) {
      throw SyncException('$what failed: $e');
    }
  }

  @override
  Future<SyncMeta?> fetchMeta(String uid) => _guard('fetch meta', () async {
    // Önbellekten değil sunucudan: eski bir üst bilgi "bulut değişmedi"
    // sanılıp başka cihazın yüklemesinin üstüne yazılmasına yol açardı.
    final doc = await _meta(uid).get(const GetOptions(source: Source.server));
    final d = doc.data();
    if (!doc.exists || d == null) return null;
    return SyncMeta(
      version: d['version'] as String?,
      hash: d['hash'] as String?,
      chunkCount: (d['chunkCount'] as num?)?.toInt() ?? 0,
      disabled: d['disabled'] == true,
    );
  });

  @override
  Future<String> download(String uid, SyncMeta meta) =>
      _guard('download', () async {
        final parcalar = await Future.wait([
          for (var i = 0; i < meta.chunkCount; i++)
            _chunk(uid, i).get(const GetOptions(source: Source.server)),
        ]);
        final buffer = StringBuffer();
        for (final p in parcalar) {
          final data = p.data()?['data'];
          if (data is! String) throw const SyncException('Missing chunk');
          buffer.write(data);
        }
        final metin = buffer.toString();
        final ozet = sha256.convert(utf8.encode(metin)).toString();
        if (ozet != meta.hash) {
          throw const SyncException('Cloud copy failed integrity check');
        }
        return metin;
      });

  @override
  Future<SyncMeta> upload(String uid, String payload, String hash) => _guard(
    'upload',
    () async {
      final onceki = await _meta(uid).get();
      final eskiSayi = (onceki.data()?['chunkCount'] as num?)?.toInt() ?? 0;

      final parcalar = <String>[
        for (var i = 0; i < payload.length; i += chunkSize)
          payload.substring(
            i,
            i + chunkSize > payload.length ? payload.length : i + chunkSize,
          ),
      ];
      final surum = const Uuid().v4();

      final batch = _db.batch();
      for (var i = 0; i < parcalar.length; i++) {
        batch.set(_chunk(uid, i), {'index': i, 'data': parcalar[i]});
      }
      for (var i = parcalar.length; i < eskiSayi; i++) {
        batch.delete(_chunk(uid, i));
      }
      batch.set(_meta(uid), {
        'version': surum,
        'hash': hash,
        'chunkCount': parcalar.length,
        'schema': 1,
        'disabled': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      return SyncMeta(version: surum, hash: hash, chunkCount: parcalar.length);
    },
  );

  @override
  Future<void> delete(String uid, {bool keepDisabledMarker = false}) =>
      _guard('delete', () async {
        final onceki = await _meta(uid).get();
        final sayi = (onceki.data()?['chunkCount'] as num?)?.toInt() ?? 0;
        final batch = _db.batch();
        for (var i = 0; i < sayi; i++) {
          batch.delete(_chunk(uid, i));
        }
        if (keepDisabledMarker) {
          // Sağlık verisi yok; yalnızca "kapatıldı" işareti ve zamanı.
          batch.set(_meta(uid), {
            'disabled': true,
            'chunkCount': 0,
            'schema': 1,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          batch.delete(_meta(uid));
        }
        await batch.commit();
      });
}
