import 'dart:developer';
import 'package:clothing_app/screens/splashpage/splash_screen.dart';
import 'package:clothing_app/utils/constant_variables.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'local_notifications/fcm_reception.dart';
import 'local_notifications/local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _backgroundMessagingHandler(RemoteMessage message) async {
  try{
  await Firebase.initializeApp();

  final localNotifications = LocalNotificationsService();
  await localNotifications.initializeLocalNotifications();

  log('FCM BACKGROUND DATA: ${message.data}');


  await localNotifications.showNotifications(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: message.data['title'] ?? 'New Message',
    body: message.data['body'] ?? '',
  );
} catch(e,t){
    log('PushNotificationService trigger catch: $e \n$t');

  }
}

Future<void> main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(url: dotenv.env['MY_SUPABASE_URL']!, anonKey: dotenv.env['MY_SUPABASE_KEY']!);
  await LocalNotificationsService().initializeLocalNotifications();

  FirebaseMessaging.onBackgroundMessage(_backgroundMessagingHandler);
  setupFCMListeners();
  
  runApp(MyApp());
}
final SupabaseClient client = Supabase.instance.client;


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clothing App',
      builder: (context, child) {
        deviceHeight = MediaQuery.of(context).size.height;
        deviceWidth = MediaQuery.of(context).size.width;
        deviceAverageSize = (deviceHeight + deviceWidth) / 2;
        return child!;

      },

      home: SplashScreen()
    );
  }
}

