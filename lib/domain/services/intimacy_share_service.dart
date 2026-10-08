import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../models/intimacy_status.dart';

/// Sahibin paylaştığı yakınlık durumunu sunucuya yazar ve geri çeker.
///
/// Push bildirimi yok: partner durumu uygulamayı açınca görüyor. Önceden
/// burada bildirim anahtarı üreten bir metot ve "Cloud Function ile push"
/// notu vardı; hiçbir şey gönderilmediği hâlde jetonlar toplanıyordu.
class IntimacyShareService {
  final FirestoreDataSource _firestoreDS;

  IntimacyShareService({FirestoreDataSource? firestore})
    : _firestoreDS = firestore ?? FirestoreDataSource();

  /// Durumu yazar. Sunucuya yazılamazsa (Firebase yok, bağlantı yok)
  /// `false` — önceden hata yutulup hep `true` dönüyordu.
  Future<bool> shareWithPartner(String uid, IntimacyStatus status) =>
      _firestoreDS.updateIntimacyStatus(uid, {
        'sexualDesire': status.sexualDesire,
        'affectionNeeds': status.affectionNeeds,
        'timestamp': Timestamp.fromDate(status.timestamp),
        'isShared': true,
      });

  /// Paylaşılmış durumu siler.
  Future<bool> retract(String uid) => _firestoreDS.deleteIntimacyStatus(uid);
}
