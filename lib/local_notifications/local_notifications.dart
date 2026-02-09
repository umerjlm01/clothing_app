import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationsService {

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();


  Future<void> initializeLocalNotifications() async{
    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('ic_notification');
    const InitializationSettings initializationSettings =
    InitializationSettings(android: androidInitializationSettings);
    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  Future<void> showNotifications ({required int id, required String title, required String body}) async{
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'channel_description',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await _notificationsPlugin.show(id: id, title: title, body: body, notificationDetails: notificationDetails);
  }

  Future<void> cancelNotification (int id) async{
    await _notificationsPlugin.cancel(id: id);
  }
  Future<void> cancelAllNotifications() async{
    await _notificationsPlugin.cancelAll();

  }

}