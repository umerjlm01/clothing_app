import 'dart:developer';

import 'package:clothing_app/local_notifications/local_notifications.dart';
import 'package:clothing_app/local_notifications/navigation_helper.dart';
import 'package:clothing_app/reusable_widgets/snack_bar_helper.dart';
import 'package:clothing_app/screens/bottom_nav_bar/bottom_nav_bloc.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


Future<void> setupFCMListeners() async{
  final localNotifications = LocalNotificationsService();
  await localNotifications.initializeLocalNotifications();

  void showSnackBar(RemoteMessage message) {
    SnackBarHelper.showSnackBar(BottomNavBloc.instance!.context, message.data['body'] ?? '');
  }



  // Foreground message
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    log('FCM FOREGROUND DATA: ${message.data}');

    if(BottomNavBloc.instance?.currentIndex == 2){
      log("Already in chat screen");
      showSnackBar(message);
    }

    localNotifications.showNotifications(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.data['title'] ?? 'New Message',
      body: message.data['body'] ?? '',
      payload: message.data['conversation_id'], // pass conversationId
    );
  });

  // Background message tap
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final conversationId = message.data['conversation_id'];
    if (conversationId != null) {
      // Navigate to ChatScreen
      Future.delayed((const Duration(milliseconds: 500)), () {
        navigateToChatScreen(conversationId);
      });

    }
  });

  // App opened from terminated state
  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      final conversationId = message.data['conversation_id'];
      if (conversationId != null) {
        // Navigate to ChatScreen
        Future.delayed((const Duration(seconds: 2)), () {
          navigateToChatScreen(conversationId);
        });

    }}
  });
}

