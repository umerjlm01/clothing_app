import 'dart:io';
import 'package:bubble/bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:clothing_app/reusable_widgets/icon_button.dart';
import 'package:clothing_app/utils/constant_variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'bottom_sheet.dart';
import 'chat_bloc.dart';
import 'chat_models.dart';
import 'handlers/audio_handler/audio_handler.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String currentUserId;
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatScreenBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ChatScreenBloc(
      context,
      this,
      conversationId: widget.conversationId,
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
    );
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }
  Widget _buildMessage(ChatMessage msg) {
    final isMe = msg.senderId == widget.currentUserId;

    Widget messageContent;

    switch (msg.type) {

      case 'image':
       messageContent= GestureDetector(

    child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: msg.url ?? '',
                width: deviceWidth * 0.55,
                height: deviceHeight * 0.35,
                fit: BoxFit.cover,
                placeholder: (context, url) => SizedBox(
                  height: 150,
                  child: Center(
                    child: SpinKitThreeBounce(
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: deviceWidth * 0.55,
                  height: deviceHeight * 0.35,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
            if (msg.caption != null && msg.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  msg.caption!,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: deviceHeight / 75,
                  ),
                ),
              ),
          ],
        ));
        break;

      case 'document':

        messageContent =  GestureDetector(
           onDoubleTap: () => _bloc.documentHandler.downloadFile(msg),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: deviceWidth * 0.55,
              minWidth: deviceWidth * 0.35,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue.shade400 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _getDocumentIcon(msg.url),
                  size: 36,
                  color: isMe ? Colors.white : Colors.blue,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getDocumentName(msg),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: deviceHeight / 75,
                      fontWeight: FontWeight.w500,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        break;
      case 'audio':
        messageContent = GestureDetector(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: deviceWidth * 0.55,
              minWidth: deviceWidth * 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue.shade400 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                ValueListenableBuilder<AudioState>(
                  valueListenable: _bloc.audioHandler.audioStateNotifier,
                  builder: (context, state, _) {
                    return AppIconButton(
                      onPressed: () => _bloc.audioHandler.playAudio(msg),
                      icon: Icon(
                        state.isPlaying && state.currentlyPlayingPath == msg.filename
                            ? Icons.pause
                            : Icons.play_arrow,
                        color: isMe ? Colors.white : Colors.blue,
                        size: 36,
                      ),
                    );
                  },
                ),

                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getDocumentName(msg),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: deviceHeight / 75,
                      fontWeight: FontWeight.w500,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

          )
        );
        break;

      case 'contact':
        messageContent = Container(
          constraints: BoxConstraints(
            maxWidth: deviceWidth * 0.55,
            minWidth: deviceWidth * 0.3,
            minHeight: 50,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue.shade400 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.contactName ?? 'Unknown',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: deviceHeight / 70,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                msg.contactPhone ?? '',
                style: TextStyle(
                  fontSize: deviceHeight / 75,
                  color: isMe ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        );
        break;

      default:
      // default is text
        messageContent = Text(
          msg.content ?? '',
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: deviceHeight / 70,
            height: 1.4,
          ),
        );
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: deviceHeight / 180,
        horizontal: deviceWidth / 50,
      ),
      child: Bubble(
        elevation: 0.5,
        radius: const Radius.circular(16),
        color: isMe ? Colors.blue.shade500 : Colors.white,
        alignment: isMe ? Alignment.topRight : Alignment.topLeft,
        nip: isMe ? BubbleNip.rightTop : BubbleNip.leftTop,
        child: messageContent,
      ),
    );
  }

  /// Helper: get file name for documents
  String _getDocumentName(ChatMessage msg) {
    if (msg.caption != null && msg.caption!.isNotEmpty) return msg.caption!;
    if (msg.url != null) return msg.url!.split('/').last.split('.').first;
    return 'Document';
  }

  /// Helper: get icon for document based on extension
  IconData _getDocumentIcon(String? url) {
    if (url == null) return Icons.insert_drive_file;

    final ext = url.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf;
    if (['doc', 'docx'].contains(ext)) return Icons.description;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart;
    return Icons.insert_drive_file;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          widget.receiverName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            /// Messages Area
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _bloc.messagesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        "Start the conversation ✨",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                    return ListView.builder(
                      controller: _bloc.scrollController,
                      reverse: true,
                      padding: EdgeInsets.symmetric(vertical: deviceHeight / 90),
                      itemCount:
                      _bloc.hasMore ? messages.length + 1 : messages.length,
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: _bloc.isLoading
                                ? const SpinKitThreeBounce(
                              color: Colors.blue,
                              size: 20,
                            )
                                : const SizedBox.shrink(),
                          );
                        }
                        final msg = messages[index];
                        return _buildMessage(msg);
                      },
                    );

                },
              ),
            ),

            /// Input Area
            /// Input Area
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<File?>(
                  valueListenable: _bloc.imageHandler.fileNotifier,
                  builder: (context, selectedFile, _) {
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: deviceWidth / 25,
                        vertical: deviceHeight / 90,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [

                          /// IMAGE PREVIEW ONLY
                          if (selectedFile != null)
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    selectedFile,
                                    width: deviceWidth * 0.25,
                                    height: deviceHeight * 0.15,
                                    fit: BoxFit.cover,
                                  ),
                                ),

                                /// Close button
                                Positioned(
                                  top: -6,
                                  right: -6,
                                  child: GestureDetector(
                                    onTap: () => _bloc.imageHandler.fileNotifier.value = null,
                                    child: const CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.red,
                                      child: Icon(Icons.close,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          if (selectedFile != null)
                            SizedBox(width: deviceWidth / 50),

                          /// TextField
                          Expanded(
                            child: TextField(
                              controller: _bloc.messageController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) =>
                                  _bloc.sendMessage(_bloc.imageHandler.fileNotifier.value),
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          SizedBox(width: deviceWidth / 50),

                          /// ATTACHMENT BUTTON
                          IconButton(
                            icon: const Icon(Icons.attach_file, color: Colors.black),
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              builder: (context) =>
                                  CustomBottomSheet(bloc: _bloc),

                            ),
                          ),

                          /// SEND BUTTON
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: () =>
                                _bloc.sendMessage(_bloc.imageHandler.fileNotifier.value),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}
