
import 'dart:async';
import 'dart:developer';

import 'package:clothing_app/bloc/bloc.dart';
import 'package:clothing_app/local_notifications/push_notification.dart';
import 'package:clothing_app/screens/chatpage/chat_models.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreenBloc extends Bloc{

  final State<StatefulWidget> state;
  final BuildContext context;
  ChatScreenBloc(this.context, this.state, {required this.conversationId,required this.currentUserId,required this.receiverId}){
    initStream();
    scrollController.addListener(scrollListener);
  }

  final BehaviorSubject<List<ChatMessage>> _messagesStream = BehaviorSubject<List<ChatMessage>>.seeded([]);
  Stream<List<ChatMessage>> get messagesStream => _messagesStream.stream;
  final List<ChatMessage> _messages = [];
  StreamSubscription<List<Map<String,dynamic>>>? _messagesSub;
  final String conversationId;
  final String currentUserId;
  final String receiverId;
  final TextEditingController _messageController = TextEditingController();
  TextEditingController get messageController => _messageController;
  final ScrollController _scrollController = ScrollController();
  ScrollController get scrollController => _scrollController;
  
  final supabase = Supabase.instance.client;
  bool isLoading = false;
  bool hasMore = true;
  final int pageSize = 20;

  void initStream() async{
    try{
      await loadMoreMessages(isInitial: true);

      final response = supabase.from(ConstantStrings.messagesTable)
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1);
      _messagesSub = response.listen((rows) {
        for (var row in rows) {
          final newMessage = ChatMessage.fromMap(row);

          // Prevent showing the same message twice (if pagination just fetched it)
          final alreadyExists = _messages.any((m) => m.id == newMessage.id);

          if (!alreadyExists) {
            // insert(0, ...) puts it at the bottom of your reversed ListView
            _messages.insert(0, newMessage);
            _messagesStream.add(List.from(_messages));
          }
        }
      });
      markMessagesAsRead();

    }
    catch(e,t){
      log('ChatBloc initStream error: $e\n$t');
    
    }
  }

  Future<void> sendMessage()async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    try{
    await supabase.from(ConstantStrings.messagesTable)
        .insert({
      'conversation_id': conversationId,
      'sender_id': currentUserId,
      'created_at': DateTime.now().toIso8601String(),
      'is_read': false,
      'text': text,});

    _messageController.clear();
    scrollToBottom();

    await supabase.from(ConstantStrings.conversationsTable).update({
      'last_message': text.trim(),
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', conversationId);

   log('Message sent successfully');

     await PushNotificationService.instance.trigger(receiverId: receiverId,
         title: 'New Message',
         body: text,
         conversationId: conversationId);
    }
    catch(e,t){
      log('ChatBloc _sendMessage error: $e\n$t');

    }

  }
  Future<void> markMessagesAsRead() async {
    try {
      await supabase.from(ConstantStrings.messagesTable).
      update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
    }
  catch(e,t){
      log('ChatBloc markMessagesAsRead error: $e\n$t');

  }
  }


  /// Pagination

  Future<void> loadMoreMessages({bool isInitial = false}) async{
    if(isLoading || (!hasMore && !isInitial)) return;
    isLoading = true;
    try{
      var loadMessages = supabase.from(ConstantStrings.messagesTable).select()
          .eq('conversation_id', conversationId);

      if(!isInitial && _messages.isNotEmpty){
        final oldestTimestamp = _messages.last.createdAt; // Use the timestamp from your model
        log('DEBUG: Fetching older than $oldestTimestamp');
        loadMessages = loadMessages.lt('created_at', oldestTimestamp.toString());
      }

      final response = await loadMessages.order('created_at', ascending: false).limit(pageSize);
      log('response: ${response.length}');

      if(response.isEmpty) {
        log('No more messages to fetch');
        hasMore = false;
        return;
      }
      final newMessages = response.map((e) => ChatMessage.fromMap(e)).toList();

// Filter out any messages that are already in the list
      final uniqueNewMessages = newMessages.where((newMsg) =>
      !_messages.any((existingMsg) => existingMsg.id == newMsg.id)
      ).toList();

      if (uniqueNewMessages.isEmpty) {
        // If we got data but it's all duplicates, we should stop trying to load more
        hasMore = false;
      } else{
        _messages.addAll(uniqueNewMessages);
        if(newMessages.length < pageSize) hasMore = false;
      }

    }
    catch (e,t){
      log('ChatBloc loadMoreMessages error: $e\n$t');
    }
    finally{
      isLoading = false;
      _messagesStream.add(List.from(_messages));

    }
  }
  void scrollListener() {
    try{
      if(isLoading || !hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      log('Scroll listener is fetching more');
      loadMoreMessages();
  }}
  catch(e){
      log('ChatBloc scrollListener error: $e');
  }
  }
  
  void scrollToBottom(){
    if(_scrollController.hasClients) {
      scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }







  @override
  void dispose() {
    _messagesSub?.cancel();
    _messagesStream.close();
    _messageController.dispose();
    _scrollController.dispose();
    // TODO: implement dispose
  }

}