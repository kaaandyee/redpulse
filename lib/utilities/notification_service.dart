/*

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize notification settings
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInitSettings);
    await _localNotifications.initialize(initSettings);

    // Handle FCM messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  // Store user's FCM token in Firestore
  static Future<void> saveUserToken(String userId) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'fcmToken': token});
    }
  }

  // Send notification to user about reservation status
  static Future<void> sendReservationStatusNotification({
    required String userId,
    required String status,
    required String bloodType,
    required String bloodBankName,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) return;

      String? fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) return;

      // Prepare notification data
      final notificationData = {
        'to': fcmToken,
        'notification': {
          'title': 'Blood Reservation Update',
          'body': 'Your $bloodType blood reservation at $bloodBankName has been $status',
        },
        'data': {
          'type': 'reservation_update',
          'status': status,
          'bloodType': bloodType,
          'bloodBankName': bloodBankName,
        }
      };

      // Save notification to Firestore for history
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'Blood Reservation Update',
        'body': 'Your $bloodType blood reservation at $bloodBankName has been $status',
        'status': status,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // For sending FCM, you'll need a Firebase Cloud Function or server-side code
      // This would call your serverless function that handles sending FCM messages
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Handle foreground messages
  static void _handleForegroundMessage(RemoteMessage message) {
    // Show local notification when app is in foreground
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reservation_channel',
            'Reservation Updates',
            'Notifications for blood reservation updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }
}
*/
