import 'dart:convert';
import 'package:clothing_app/local_notifications/navigation_helper.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class LocalNotificationsService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initializeLocalNotifications() async {
    const androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final settings = InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) async {

        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;

        final data = jsonDecode(payload);
        // final callID = data['call_id'];
        final conversationID = data['conversation_id'];

        // 🔥 THIS is how you detect which button was pressed
        final actionID = response.actionId;

        if (actionID == 'ACCEPT') {
          await ZegoUIKitPrebuiltCallInvitationService()
              .accept();
        }
        else if (actionID == 'REJECT') {
          await ZegoUIKitPrebuiltCallInvitationService()
              .reject();
        }
        else {
          // Normal notification tap
          if (conversationID != null) {
            await navigateToChatScreen(conversationID);
          }
        }
      },
    );
  }

  Future<void> showNotifications({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isCall = false,
    String? callId,
    bool isVideo = true,
  }) async {

    if (isCall && callId != null) {

      final androidDetails = AndroidNotificationDetails(
        'clothing_channel',
        'Incoming Calls',
        channelDescription: 'Incoming call notifications',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        ongoing: true,
        category: AndroidNotificationCategory.call,
        actions: const [
          AndroidNotificationAction(
            'ACCEPT',
            'Accept',
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'REJECT',
            'Reject',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      );

      final details = NotificationDetails(android: androidDetails);

      final callPayload = jsonEncode({
        'call_id': callId,
        'is_video': isVideo,
        'is_call': true,
      });

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: callPayload,
      );
    } else {

      const androidDetails = AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        channelDescription: 'channel_description',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    }
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}