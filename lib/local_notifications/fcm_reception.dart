import 'dart:developer';

import 'package:clothing_app/local_notifications/local_notifications.dart';
import 'package:clothing_app/local_notifications/navigation_helper.dart';
import 'package:clothing_app/reusable_widgets/snack_bar_helper.dart';
import 'package:clothing_app/screens/bottom_nav_bar/bottom_nav_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


Future<void> setupFCMListeners() async {
  final localNotifications = LocalNotificationsService();
  await localNotifications.initializeLocalNotifications();


  void showSnackBar(RemoteMessage message) {
    SnackBarHelper.showSnackBar(
      BottomNavBloc.instance!.context,
      message.data['body'] ?? '',
    );
  }

  // Foreground message
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    log('FCM FOREGROUND DATA: ${message.data}');

    // If it's a call, Zego SDK handles the UI automatically
    if (message.data['is_call'] == 'true') {
      log('Foreground call notification received, handled by Zego');
      return; // Skip local notification
    }

    // Chat message handling
    if (BottomNavBloc.instance?.currentIndex == 2) {
      log("Already in chat screen");
      showSnackBar(message);
    }

    localNotifications.showNotifications(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.data['title'] ?? 'New Message',
      body: message.data['body'] ?? '',
      payload: message.data['conversation_id'],
    );
  });

  // Background / notification tap
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    _handleMessageTap(message);
  });

  // App opened from terminated state
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      _handleMessageTap(message, isTerminated: true);
    }
  });
}

void _handleMessageTap(RemoteMessage message, {bool isTerminated = false}) {
  // If it's a call, Zego SDK will handle navigation automatically
  if (message.data['is_call'] == 'true')return;

  final conversationId = message.data['conversation_id'];

  if (conversationId != null && conversationId.isNotEmpty) {
    Future.delayed(
      isTerminated ? const Duration(seconds: 2) : const Duration(milliseconds: 500),
          () => navigateToChatScreen(conversationId),
    );
  }
}