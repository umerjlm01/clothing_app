import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:clothing_app/bloc/bloc.dart';
import 'package:clothing_app/local_notifications/push_notification.dart';
import 'package:clothing_app/screens/chatpage/chat_models.dart';
import 'package:clothing_app/utils/constant_strings.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'handlers/audio_handler/audio_handler.dart';
import 'handlers/contact_handlers/contact_handler.dart';
import 'handlers/document_handler/document_handler.dart';
import 'handlers/image_handlers/image_handler.dart';
import 'handlers/maps_handler/maps_handler.dart';
import 'handlers/maps_handler/maps_screen.dart';

class ChatScreenBloc extends Bloc {
  final State<StatefulWidget> state;
  final BuildContext context;

  ChatScreenBloc(this.context, this.state,
      {required this.conversationId,
        required this.currentUserId,
        required this.receiverId}) {
    initStream();
    scrollController.addListener(scrollListener);
    documentHandler.fileNotifier.addListener(() {
      final file = documentHandler.fileNotifier.value;
      if (file != null) {
        sendMessage(file); // auto-send document
        documentHandler.clear();
      }
    });
    audioHandler.fileNotifier.addListener((){
      final file = audioHandler.fileNotifier.value;
      if (file != null) {
        sendMessage(file);
        audioHandler.clear();
    }});
    contactHandler.contactNotifier.addListener((){
      final file = contactHandler.contactNotifier.value;
      if (file != null) {
        sendMessage(null); // auto-send contact
        contactHandler.clear();
    }});

  }

  // ---------------- Streams ----------------
  final BehaviorSubject<List<ChatMessage>> _messagesStream =
  BehaviorSubject<List<ChatMessage>>.seeded([]);
  Stream<List<ChatMessage>> get messagesStream => _messagesStream.stream;
  final List<ChatMessage> _messages = [];
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;

  // ---------------- Controllers ----------------
  final TextEditingController _messageController = TextEditingController();
  TextEditingController get messageController => _messageController;
  final ScrollController _scrollController = ScrollController();
  ScrollController get scrollController => _scrollController;

  // ---------------- Bloc State ----------------
  final String conversationId;
  final String currentUserId;
  final String receiverId;
  final supabase = Supabase.instance.client;

  bool isLoading = false;
  bool hasMore = true;
  final int pageSize = 20;

  // ---------------- Handlers ----------------
  late final ImageHandler imageHandler = ImageHandler();
  late final DocumentHandler documentHandler =
  DocumentHandler(supabase: supabase);
  late final ContactHandler contactHandler = ContactHandler();
  late final AudioHandler audioHandler = AudioHandler(supabase: supabase);
  late final MapsHandler mapsHandler = MapsHandler();


  // ---------------- Initialization ----------------
  void initStream() async {
    try {
      await loadMoreMessages(isInitial: true);

      final response = supabase
          .from(ConstantStrings.messagesTable)
          .stream(primaryKey: ['id'])
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1);

      _messagesSub = response.listen((rows) {
        for (var row in rows) {
          final newMessage = ChatMessage.fromMap(row);
          if (!_messages.any((m) => m.id == newMessage.id)) {
            _messages.insert(0, newMessage);
            _messagesStream.add(List.from(_messages));
          }
        }
      });

      markMessagesAsRead();
    } catch (e, t) {
      log('ChatBloc initStream error: $e\n$t');
    }
  }

  // ---------------- Message Sending ----------------
  Future<void> sendMessage([File? file, LatLng? location, bool isLive = false]) async {
    final text = _messageController.text.trim();

    final selectedContact = contactHandler.contactNotifier.value;
    File? sendingFile = file ?? documentHandler.fileNotifier.value ?? audioHandler.fileNotifier.value;

    if (text.isEmpty && sendingFile == null && selectedContact == null && location == null) return;

    try {
      Map<String, dynamic> messagePayload;

      // 1️⃣ Contact
      if (selectedContact != null) {
        messagePayload = {
          'type': 'contact',
          'name': selectedContact.fullName,
          'phone': selectedContact.phoneNumbers
              .toString()
              .replaceAll('[', '')
              .replaceAll(']', '')
        };
      }
      else if (location != null) {

        messagePayload = {
          'type': 'location',
          'latitude': location.latitude,
          'longitude': location.longitude,
          'filename': 'Location',
          'live': isLive

        };
      }
      // 2️⃣ File/Image/Document/Audio
      else if (sendingFile != null) {
        final ext = sendingFile.path.split('.').last.toLowerCase();
        final filename =
            '$currentUserId/${DateTime.now().millisecondsSinceEpoch}_${sendingFile.path.split('/').last}';

        // Upload file to Supabase storage
        await supabase.storage
            .from('chat-images')
            .uploadBinary(filename, await sendingFile.readAsBytes());
        final url = supabase.storage.from('chat-images').getPublicUrl(filename);

        if (['png', 'jpg', 'jpeg', 'gif', 'heic', 'webp'].contains(ext)) {
          messagePayload = {
            'type': 'image',
            'url': url,
            'caption': text.isEmpty ? null : text,
            'filename': filename,
          };
        } else if (['pdf', 'doc', 'docx', 'xls', 'xlsx'].contains(ext)) {
          messagePayload = {
            'type': 'document',
            'url': url,
            'caption': text.isEmpty ? null : text,
            'filename': filename,
          };
        } else {
          messagePayload = {
            'type': 'audio',
            'url': url,
            'caption': text.isEmpty ? null : text,
            'filename': filename,
          };
        }
      }
      // 3️⃣ Text only
      else {
        messagePayload = {'type': 'text', 'text': text};
      }

      // Insert message
      await supabase.from(ConstantStrings.messagesTable).insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'text': messagePayload,
      });

      // Clear inputs
      _messageController.clear();
      imageHandler.clear();
      documentHandler.clear();
      contactHandler.clear();
      audioHandler.clear();
      scrollToBottom();

      // Determine last message for conversation
      String lastMessage;
      if (selectedContact != null) {
        lastMessage =
        '${selectedContact.fullName} - ${selectedContact.phoneNumbers.toString().replaceAll('[', '').replaceAll(']', '')}';
      } else if (sendingFile != null) {
        final ext = sendingFile.path.split('.').last.toLowerCase();
        lastMessage = ['png', 'jpg', 'jpeg', 'gif', 'heic', 'webp']
            .contains(ext)
            ? 'Image sent'
            : ['pdf', 'doc', 'docx', 'xls', 'xlsx'].contains(ext)
            ? 'Document sent'
            : 'Audio sent';
      } else if(location != null){
        lastMessage = 'Location sent';
      }

      else {
        lastMessage = text.trim();
      }

      // Update conversation
      await supabase.from(ConstantStrings.conversationsTable).update({
        'last_message': lastMessage,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      // Trigger push notification
      await PushNotificationService.instance.trigger(
        receiverId: receiverId,
        title: 'New Message',
        body: lastMessage,
        conversationId: conversationId,
      );

      log('Message sent successfully');
    } catch (e, t) {
      log('ChatBloc sendMessage error: $e\n$t');
    }
  }

  // ---------------- Pagination ----------------
  Future<void> loadMoreMessages({bool isInitial = false}) async {
    if (isLoading || (!hasMore && !isInitial)) return;
    isLoading = true;
    try {
      var loadMessages = supabase
          .from(ConstantStrings.messagesTable)
          .select()
          .eq('conversation_id', conversationId);

      if (!isInitial && _messages.isNotEmpty) {
        final oldestTimestamp = _messages.last.createdAt;
        loadMessages = loadMessages.lt('created_at', oldestTimestamp.toString());
      }

      final response =
      await loadMessages.order('created_at', ascending: false).limit(pageSize);

      if (response.isEmpty) {
        hasMore = false;
        return;
      }

      final newMessages = response.map((e) => ChatMessage.fromMap(e)).toList();

      final uniqueNewMessages = newMessages
          .where((newMsg) => !_messages.any((existingMsg) => existingMsg.id == newMsg.id))
          .toList();

      if (uniqueNewMessages.isEmpty) hasMore = false;
      _messages.addAll(uniqueNewMessages);
    } catch (e, t) {
      log('ChatBloc loadMoreMessages error: $e\n$t');
    } finally {
      isLoading = false;
      _messagesStream.add(List.from(_messages));
    }
  }

  void scrollListener() {
    if (isLoading || !hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      loadMoreMessages();
    }
  }

  void scrollToBottom() {
    if (_scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ---------------- Mark messages as read ----------------
  Future<void> markMessagesAsRead() async {
    try {
      if (currentUserId == receiverId) return;
      await supabase
          .from(ConstantStrings.messagesTable)
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
    } catch (e, t) {
      log('ChatBloc markMessagesAsRead error: $e\n$t');
    }
  }

  void openMaps(ChatMessage msg) {
    final lat = msg.latitude;
    final long = msg.longitude;
    if (lat == null || long == null) return;

    final destination = LatLng(lat, long);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapsScreen(
          bloc: this,
          destination: destination,
          isLive: msg.isLive,
        ),
      ),
    );
  }

  String zegoUserID(String originalID) {
    // SHA256 hash, take first 32 characters
    final bytes = utf8.encode(originalID);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32);
  }

  Future<void> makeCall(String receiverId, String receiverName, {bool isVideo = true}) async{
    try{

      final currentUser = supabase.auth.currentUser;
      if(currentUserId == receiverId) return;
      if(currentUserId.isEmpty) return;
      final receiverZegoId = zegoUserID(receiverId);
      final callID = 'call_${currentUserId}_${receiverId}_${DateTime.now().millisecondsSinceEpoch}';
      PermissionStatus micStatus = await Permission.microphone.status;
      if(!micStatus.isGranted){
        await Permission.microphone.request();
        log("MicroPhone Permission Granted");
      }
      if(isVideo) {
        PermissionStatus cameraStatus = await Permission.camera.status;
        if (!cameraStatus.isGranted) {
        await Permission.camera.request();
      }}
      ZegoUIKitPrebuiltCallInvitationService().send(
        callID: callID,
        isVideoCall: isVideo,
        notificationTitle: "Incoming Call",
        resourceID: 'clothing_app_push',
        notificationMessage: "Call From ${currentUser!.email}",
        invitees: [
          ZegoCallUser(receiverZegoId, receiverName),
        ],
        timeoutSeconds: 60,


      );

      await supabase.from(ConstantStrings.messagesTable).insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'text': {
          'type': 'call',
          'content': isVideo ? 'Video Call' : 'Audio Call',}
      });

      await supabase.from(ConstantStrings.conversationsTable).update({
        'last_message': isVideo ? 'Video Call' : 'Audio Call',
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', conversationId);

      await PushNotificationService.instance.trigger(
        receiverId: receiverId,
        title: 'Incoming Call',
        body: 'Call From ${currentUser.email}',
        conversationId: callID,
        isCall: 'true',
        callId: callID,
        callType: isVideo ? 'video' : 'audio',
      );

    }
    catch(e,t){
      log("ChatScreenBloc makeCall catch $e \n $t");
    }

  }




  @override
  void dispose() {
    _messagesSub?.cancel();
    _messagesStream.close();
    _messageController.dispose();
    _scrollController.dispose();
  }
}
