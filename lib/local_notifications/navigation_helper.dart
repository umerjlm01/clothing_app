import 'dart:developer';

import 'package:clothing_app/screens/bottom_nav_bar/bottom_nav_bloc.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/chatpage/chat_screen.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


// Shared function to navigate to ChatScreen
Future<void> navigateToChatScreen(String conversationId) async {
  try {
    int authRetryCount = 0;
    while(Supabase.instance.client.auth.currentUser == null && authRetryCount < 5){
      await Future.delayed(const Duration(seconds: 1));
      authRetryCount++;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if(user == null) return;
    final currentUserId = user.id;

    final response = await Supabase.instance.client
        .from("conversations")
        .select("sender_id, receiver_id, receiver_name")
        .eq('id', conversationId)
        .single();
    if (response.isEmpty) {
      log('Conversation not found');
    }


    String receiverId;
    String receiverName;

    if (response['sender_id'] == currentUserId) {
      receiverId = response['receiver_id'];
      receiverName = response['receiver_name'];
    } else {
      receiverId = response['sender_id'];
      receiverName = response['receiver_name'];
    }

    int retryCount = 0;
    while ((BottomNavBloc.instance == null || navigatorKey.currentState == null) && retryCount < 10) {
      log("Waiting for app state... Attempt $retryCount");
      await Future.delayed(const Duration(milliseconds: 500));
      retryCount++;
    }

    BottomNavBloc.instance?.updateIndex(2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) =>
              ChatScreen(
                conversationId: conversationId,
                currentUserId: currentUserId,
                receiverId: receiverId,
                receiverName: receiverName,
              ),
      ),


      );
    });
  }catch(e,t){
    log('navigateToChatScreen error: $e\n$t');
  }
  }




