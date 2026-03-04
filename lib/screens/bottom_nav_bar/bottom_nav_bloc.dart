import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:clothing_app/bloc/bloc.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';
import '../cartpage/cart_screen.dart';
import '../chat_list_page/chat_list_screen.dart';
import '../homepage/homepage_screen.dart';
import '../profilepage/profile_screen.dart';


class BottomNavBloc extends Bloc {
  static BottomNavBloc? instance;
  BuildContext context;
  State<StatefulWidget> state;
  BottomNavBloc(this.context, this.state){
    initializeFCM();

    instance = this;
  }
 final BehaviorSubject<int> _currentIndex = BehaviorSubject.seeded(0);
  Stream<int> get currentIndexStream => _currentIndex.stream;
  int get currentIndex => _currentIndex.value;
  final supabase = Supabase.instance.client;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<RemoteMessage>? _messageSubscription;




late List<Widget> screens = [
  HomepageScreen(),
  CartScreen(),
  ChatListScreen(),
  ProfileScreen(),
];

  void updateIndex(int index){
    _currentIndex.add(index);

  }



  ///FCM token

  bool _fcmInitialized = false;


  Future<void> initializeFCM() async {
    try{
    if(_fcmInitialized) return;
    _fcmInitialized = true;
    await FirebaseMessaging.instance.requestPermission();
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null){
    await _getFcmToken(fcmToken);
    }}
    catch (e,s){
      log('BottomNavBloc initializeFCM catch $e \n $s');
    }
    _tokenRefreshSubscription= FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async{
      try{ _getFcmToken(fcmToken);
    }
    catch (e,t){
        log('BottomNavBloc _tokenRefreshSubscription catch $e \n $t');
    }
    }
    );
    _messageSubscription = FirebaseMessaging.onMessage.listen((message){
      final notification = message.notification;
      if(notification != null && state.mounted){
      return log('New notification: ${notification.title} ${notification.body}');
      }

    });
  }

  Future<void> _getFcmToken(String fcmToken) async {

    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from(ConstantStrings.profileTable)
        .update({'fcm_token': fcmToken})
        .eq('id', user.id);


    log('FCM Token: $fcmToken');
  }

  Future<void> updateFcmToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _getFcmToken(fcmToken);
      log('FCM token updated after splash: $fcmToken');
    }
  }




  String zegoUserID(String originalID) {
    // SHA256 hash, take first 32 characters
    final bytes = utf8.encode(originalID);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }
  bool isInitialized = false;

  Future<void> initZego() async {
    if (isInitialized) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {



        // 2️⃣ Initialize Prebuilt Call Invitation Service
        await ZegoUIKitPrebuiltCallInvitationService().init(
          appID: int.parse(dotenv.env['MY_APP_ID']!),
          appSign: dotenv.env['MY_APP_SIGN']!,
          userID: zegoUserID(user.id),
          userName: user.email ?? "User",
          plugins: [ZegoUIKitSignalingPlugin()],
        );

        // 1️⃣ Configure Zego push
        log('ZegoUIKit initialized, signalingPlugin null? ${ZegoPluginAdapter().signalingPlugin == null}');
        isInitialized = true;

      } else {
        log('initZego skipped: user is null');
      }
    } catch (e, t) {
      log('initZego error: $e\n$t');
    }
  }






  @override
  void dispose() {
    _currentIndex.close();
    _tokenRefreshSubscription?.cancel();
    _messageSubscription?.cancel();
    // TODO: implement dispose
  }



}