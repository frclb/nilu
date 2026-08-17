import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../data/datasources/remote/firestore_datasource.dart';
import '../models/intimacy_status.dart';

/// Partner'a yakınlık durumu verisi gönderen servis.
/// Firestore üzerinden gerçek zamanlı senkronizasyon sağlar.
class IntimacyShareService {
  final FirestoreDataSource _firestoreDS = FirestoreDataSource();

  /// Durumu partner'a gönderir.
  Future<bool> shareWithPartner(String uid, IntimacyStatus status) async {
    try {
      await _firestoreDS.updateIntimacyStatus(uid, {
        'sexualDesire': status.sexualDesire,
        'affectionNeeds': status.affectionNeeds,
        // Firestore'un kendi zaman tipi kullanılır: sıralanabilir ve
        // okurken tip dönüşümü gerektirmez. (Eskiden ISO-8601 string
        // yazılıyordu; okuyucu taraf geriye dönük uyumlu.)
        'timestamp': Timestamp.fromDate(status.timestamp),
        'isShared': status.isShared,
      });

      // TODO: Backend/Cloud Function tarafında push notification tetikleme
      // (FCM ile partner'a getNotificationKey'in çözülmüş hâlini gönderme)
      return true;
    } catch (e) {
      debugPrint("Error sharing intimacy status: $e");
      return false;
    }
  }

  /// Partner'a gönderilecek bildirim için **lokalizasyon anahtarı** döndürür.
  ///
  /// Metnin kendisi değil anahtar döner: push bildirimi *alıcının* diline göre
  /// çözülmelidir (istemcide ya da Cloud Function'da), gönderenin diline değil.
  /// Gönderilecek bir şey yoksa null döner.
  String? getNotificationKey(IntimacyStatus status) {
    // Cinsel istek, sevgi ihtiyaçlarına göre önceliklidir.
    switch (status.sexualDesire) {
      case 'no_interest':
        break; // Bu durumda bildirim gönderilmez.
      case 'slight_closeness':
        return 'push_desire_slight_closeness';
      case 'feel_closer':
        return 'push_desire_feel_closer';
      case 'passionate':
        return 'push_desire_passionate';
    }

    const needKeys = <String, String>{
      'hug': 'push_need_hug',
      'kiss': 'push_need_kiss',
      'be_together': 'push_need_be_together',
      'hear_voice': 'push_need_hear_voice',
      'text': 'push_need_text',
      'spend_time': 'push_need_spend_time',
      'attention': 'push_need_attention',
      'alone_time': 'push_need_alone_time',
    };

    for (final need in status.affectionNeeds) {
      final key = needKeys[need];
      if (key != null) return key;
    }

    if (status.sexualDesire.isEmpty && status.affectionNeeds.isEmpty) {
      return null;
    }

    return 'push_status_updated';
  }
}
