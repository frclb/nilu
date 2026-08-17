import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/firebase/firebase_config.dart';

/// Firebase Cloud Messaging sarmalayıcısı.
///
/// Plugin instance'ları **getter** olarak tutulur (field değil): Firebase
/// yapılandırılmamışken sınıfın kurulması bile çökmesin diye.
class NotificationService {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<void> initialize(String userId) async {
    if (!FirebaseConfig.isAvailable) return;
    try {
      // İzin iste
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');

        // Token al
        String? token = await _fcm.getToken();
        if (token != null) {
          await _saveTokenToFirestore(userId, token);
        }

        // Token yenilemelerini dinle
        _fcm.onTokenRefresh.listen((newToken) {
          _saveTokenToFirestore(userId, newToken);
        });
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint("Notification initialize error: $e");
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    if (!FirebaseConfig.isAvailable) return;
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  Future<void> removeToken(String userId) async {
    if (!FirebaseConfig.isAvailable) return;
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
    } catch (e) {
      debugPrint("Error removing FCM token: $e");
    }
  }

  // NOTE: Gerçek bir uygulamada Cloud Function veya Backend Server üzerinden
  // push bildirimi gönderilir. Firestore üzerinden tetiklenen bir trigger yazılması gerekir.
}
