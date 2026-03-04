  import 'dart:developer';
  import 'package:clothing_app/local_notifications/zpn_event_handler.dart';
import 'package:clothing_app/screens/splashpage/splash_screen.dart';
  import 'package:clothing_app/utils/constant_variables.dart';
  import 'package:firebase_messaging/firebase_messaging.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_dotenv/flutter_dotenv.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:firebase_core/firebase_core.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
  import 'firebase_options.dart';
  import 'local_notifications/fcm_reception.dart';
  import 'local_notifications/local_notifications.dart';
import 'local_notifications/navigation_helper.dart';



  @pragma('vm:entry-point')
  Future<void> _backgroundMessagingHandler(RemoteMessage message) async {
    try{
    await Firebase.initializeApp();

    final localNotifications = LocalNotificationsService();
    await localNotifications.initializeLocalNotifications();

    log('FCM BACKGROUND DATA: ${message.data}');
    if(message.data['is_call'] == 'true'){
      await localNotifications.showNotifications(id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: message.data['title'] ?? 'New Message',
          body: message.data['body'] ?? '',
          isCall: true,
          callId: message.data['call_id'],
          isVideo: message.data['call_type'] == 'video');
    }

    else if(message.data['conversation_id'] != null)
    {await localNotifications.showNotifications(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: message.data['title'] ?? 'New Message',
      body: message.data['body'] ?? '',
      payload: message.data['conversation_id'],
    );
  } }catch(e,t){
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
    await setupFCMListeners();

    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);
    ZPNsEventHandlerManager.loadingEventHandler();

    await ZegoUIKit().initLog().then((value) async {
      await ZegoUIKitPrebuiltCallInvitationService().useSystemCallingUI(
        [ZegoUIKitSignalingPlugin()],
      );

      runApp(MyApp());
    });
  }

  class MyApp extends StatelessWidget {
    const MyApp({super.key});

    // This widget is the root of your application.
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Clothing App',
          navigatorKey: navigatorKey,
        builder: (context, child) {
          deviceHeight = MediaQuery.of(context).size.height;
          deviceWidth = MediaQuery.of(context).size.width;
          deviceAverageSize = (deviceHeight + deviceWidth) / 2;
          return child!;

        },
          home: SplashScreen(),
      );
    }
  }

