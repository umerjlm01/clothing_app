import 'dart:async';
import 'dart:developer';

import 'package:clothing_app/screens/chat_list_page/chat_list_models.dart';
import 'package:clothing_app/screens/chat_list_page/profile_models.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bloc/bloc.dart';



class ChatListBloc extends Bloc {
  static ChatListBloc? instance;
  final BuildContext context;
  final State<StatefulWidget> state;

  ChatListBloc(this.context, this.state) {
    initStreams();
    instance = this;
  }

  final SupabaseClient supabase = Supabase.instance.client;

  final BehaviorSubject<List<ChatListItem>> _chatListSubject =
  BehaviorSubject<List<ChatListItem>>.seeded([]);

  Stream<List<ChatListItem>> get chatListStream => _chatListSubject.stream;
  Stream<int> get totalUnreadStream =>
      _chatListSubject.stream.map((list) => list.fold(0, (sum, chat) => sum + chat.unreadCount));



  StreamSubscription<List<Map<String, dynamic>>>? _profilesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _conversationsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  Map<String, int> _unreadCounts = {};


  // Stream<List<Map<String, dynamic>>>

  List<Profile> _profiles = [];
  List<Map<String, dynamic>> _conversations = [];

  void initStreams() {
    try {
      final currentUserId = supabase.auth.currentUser!.id;

      // 1️⃣ Stream all users except current
      final profilesStream = supabase
          .from(ConstantStrings.profileTable)
          .stream(primaryKey: ['id'])
          .neq('id', currentUserId);

      _profilesSub = profilesStream.listen(
            (rows) {
          _profiles = rows.map((e) => Profile.fromMap(e)).toList();
          _mergeProfilesAndConversations(currentUserId);
        },
        onError: (e, t) {
          log('Profiles stream error: $e\n$t');
          _chatListSubject.addError(e);
        },
      );

      _messagesSub = supabase
          .from(ConstantStrings.messagesTable)
          .stream(primaryKey: ['id'])
          .listen((rows) {

        final Map<String, int> counts = {};

        for (var row in rows) {
          final isUnread = row['is_read'] == false;
          final isNotMine = row['sender_id'] != currentUserId;

          if (isUnread && isNotMine) {
            final convId = row['conversation_id'];
            counts[convId] = (counts[convId] ?? 0) + 1;
          }
        }

        _unreadCounts = counts;

        _mergeProfilesAndConversations(currentUserId);
      });







      final conversationsStream = supabase
          .from(ConstantStrings.conversationsTable)
          .stream(primaryKey: ['id'])
          .order('last_message_at', ascending: false);

      _conversationsSub = conversationsStream.listen(
            (rows) {
          // Keep only conversations involving current user
          _conversations = rows
              .where((c) =>
          c['sender_id'] == currentUserId ||
              c['receiver_id'] == currentUserId)
              .toList();
          _mergeProfilesAndConversations(currentUserId);
        },
        onError: (e, t) {
          log('Conversations stream error: $e\n$t');
          _chatListSubject.addError(e);
        },
      );
    } catch (e, t) {
      log('ChatListBloc initStreams error: $e\n$t');
      _chatListSubject.addError(e);
    }
  }


  void _mergeProfilesAndConversations(String currentUserId) {
    final items = _profiles.map((profile) {
      // Find conversation with this user if exists
      final conversation = _conversations.firstWhere(
            (c) =>
        (c['sender_id'] == profile.id ||
            c['receiver_id'] == profile.id),
        orElse: () => {},
      );

      return ChatListItem(
        conversationId: conversation['id'] ?? '',
        receiverId: profile.id,
        receiverName: profile.name,
        lastMessage: conversation['last_message'],
        lastMessageAt: conversation['last_message_at'] != null
            ? DateTime.tryParse(conversation['last_message_at'])
            : null,
        unreadCount: _unreadCounts[conversation['id']] ?? 0,
      );
    }).toList();

    // Sort by lastMessageAt descending;
    items.sort((a, b) {
      final aTime = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    _chatListSubject.add(items);
  }


  Future<void> createConversation({
    required String receiverId,
    required String receiverName,
  }) async {
    try {
      final currentUserId = supabase.auth.currentUser!.id;
      if (currentUserId == receiverId) return;


      final ids = [currentUserId, receiverId]..sort();
      final senderId = ids[0];
      final receiversId = ids[1];

      final conversationId = '${senderId}_$receiversId';
      if(currentUserId != receiverId){
      final existing = await supabase
          .from(ConstantStrings.conversationsTable)
          .select('id')
          .eq('id', conversationId)
          .maybeSingle();

      if (existing != null) return;

      await supabase.from(ConstantStrings.conversationsTable).insert({
        'sender_id': senderId,
        'receiver_id': receiversId,
        'receiver_name': receiverName,
        'last_message': '',
        'last_message_at': null,
        'created_at': DateTime.now().toIso8601String(),
      }).single().maybeSingle();
    }} catch (e, t) {
      log('createConversation error: $e \n $t');
    }
  }


  @override
  void dispose() {
    _profilesSub?.cancel();
    _messagesSub?.cancel();
    _conversationsSub?.cancel();
    _chatListSubject.close();

  }
}