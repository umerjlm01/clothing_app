import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../screens/profilepage/profile_screen.dart';
import 'local_notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void setupFCMListeners() {
  final localNotifications = LocalNotificationsService();


  // Foreground message
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      localNotifications.showNotifications(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? '',
      );
    }
  });

  // Background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {

    final conversationId = message.data['conversation_id'];
    if (conversationId != null) {
      localNotifications.showNotifications(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: message.notification?.title ?? 'New Message',
        body: message.notification?.body ?? '',
      );
      navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => ProfileScreen()));

    }
  });

  // Terminated state
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      final conversationId = message.data['conversation_id'];
      if (conversationId != null) {
        localNotifications.showNotifications(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: message.notification?.title ?? 'New Message',
          body: message.notification?.body ?? '',
        );
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (context) => ProfileScreen()));
      }
    }
  });
}
