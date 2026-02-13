import 'package:clothing_app/local_notifications/navigation_helper.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class LocalNotificationsService {



  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();





  Future<void> initializeLocalNotifications() async{
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings settings = InitializationSettings(android: androidInitializationSettings);

    await _notificationsPlugin.initialize(settings: settings, onDidReceiveNotificationResponse: (payload) async{
      if(payload.payload != null && payload.payload!.isNotEmpty){
        // Navigate to ChatScreen
       await navigateToChatScreen(payload.payload!);
      }
    });


  }

  Future<void> showNotifications ({required int id, required String title, required String body, String? payload}) async{
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel_description',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      enableVibration: true,
      playSound: true,

    );
    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await _notificationsPlugin.show(id: id, title: title, body: body, notificationDetails: notificationDetails, payload: payload);
  }

  Future<void> cancelNotification (int id) async{
    await _notificationsPlugin.cancel(id: id);
  }
  Future<void> cancelAllNotifications() async{
    await _notificationsPlugin.cancelAll();

  }

}
