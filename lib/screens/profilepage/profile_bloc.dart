import 'dart:async';
import 'dart:developer';
import 'package:clothing_app/bloc/bloc.dart';
import 'package:clothing_app/local_notifications/push_notification.dart';
import 'package:clothing_app/screens/profilepage/messages_models.dart';
import 'package:clothing_app/screens/profilepage/profile_models.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/secure_storage.dart';

class ProfileBloc extends Bloc {
  final BuildContext context;
  final State<StatefulWidget> state;

  ProfileBloc(this.context, this.state);

  final supabase = Supabase.instance.client;

  //Profile

  final _storage = SecureStorage();

  // Profile

  Future<Profile> getProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final response = await supabase
          .from(ConstantStrings.profileTable)
          .select()
          .eq('id', userId)
          .single(); // 👈 ensures one row

      return Profile.fromJson(response);
    } catch (e) {
      log('ProfileBloc getProfile catch $e');
      rethrow; // 👈 propagate error properly
    }
  }


  Future<List<Profile>> fetchUsers() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final response = await supabase
          .from(ConstantStrings.profileTable)
          .select()
          .neq('id', currentUserId); // exclude the logged in user

      return response.map((e) => Profile.fromJson(e)).toList();
    } catch (e) {
      log('Error fetching users: $e');
      return [];
    }
  }


  Future<void> logout() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId != null){
        await supabase.from(ConstantStrings.profileTable).update({
          'fcm_token': null,
        }).eq('id', userId);
      }
      await supabase.auth.signOut();
      await _storage.delete('accessToken');
      messageController.clear();
    } catch (e) {
      log('Logout failed: $e');
    }
  }

  //  Chat
  final BehaviorSubject<List<Message>> _messageStream = BehaviorSubject<List<Message>>.seeded([]);
  Stream<List<Message>> get messageStream => _messageStream.stream;
  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;

  String? conversationId;
  final TextEditingController messageController = TextEditingController();


  void createConversation(String receiverId) async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    final sorted = [currentUserId, receiverId]..sort();
    conversationId = '${sorted[0]}_${sorted[1]}';

    try {
      final convo = await supabase.from(ConstantStrings.conversationsTable).select().eq('id', conversationId!).maybeSingle();

      if (convo == null) {
        await supabase.from(ConstantStrings.conversationsTable).insert({
          'sender_id': sorted[0],
          'receiver_id': sorted[1],
          'last_message': '',
        });
      }

      _initMessageStream();
    } catch (e) {
      log('Error creating conversation: $e');
    }
  }



  void _initMessageStream() {
    if (conversationId == null) return;

    final stream = supabase
        .from(ConstantStrings.messagesTable)
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId!)
        .order('created_at', ascending: true);

    _messageSubscription?.cancel();
    _messageSubscription = stream.listen(
          (data) => _messageStream.add(data.map((e) => Message.fromJson(e)).toList()),
      onError: (error) => _messageStream.addError(error),
    );
  }


  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || conversationId == null) return;

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      log("No user found");
      return;
    }

    try {
      await supabase.from(ConstantStrings.messagesTable).insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'text': text,
      });

      await supabase.from(ConstantStrings.conversationsTable).update({
        'last_message': text,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId!);

      final receiverId = conversationId!.split('_')[1] == currentUserId ? conversationId!.split('_')[0] : conversationId!.split('_')[1];

      await PushNotificationService.instance.trigger(receiverId: receiverId, title: "New Message", body: text);
      log('Message sent: $text');
      messageController.clear();

    } catch (e, t) {
      log('Error sending message: $e \n $t');
    }
  }



  @override
  void dispose() {
    _messageStream.close();
    _messageSubscription?.cancel();
    messageController.dispose();

  }
}
