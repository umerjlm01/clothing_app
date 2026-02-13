import 'package:clothing_app/utils/constant_variables.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'chat_bloc.dart';
import 'chat_models.dart';

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
    if(mounted){
    super.initState();
    _bloc = ChatScreenBloc(
      context,
      this,
      conversationId: widget.conversationId,
      currentUserId: widget.currentUserId,
      receiverId: widget.receiverId,
    );
  }}

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  Widget _buildMessage(ChatMessage msg) {
    final isMe = msg.senderId == widget.currentUserId;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: deviceHeight / 150, horizontal: deviceWidth / 60),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: deviceHeight / 100, horizontal: deviceWidth / 30),
          constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[300],
            borderRadius: BorderRadius.circular(deviceHeight / 70),
          ),
          child: Text(
            msg.text,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: deviceHeight / 65,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        centerTitle: true,
        elevation: 1,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _bloc.messagesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  if (messages.isEmpty) {
                    return const Center(child: Text("No messages yet"));
                  }

                  return ListView.builder(
                    controller: _bloc.scrollController,
                    reverse: true, // newest at bottom
                    padding: EdgeInsets.symmetric(vertical: deviceHeight / 100),
                    itemCount: _bloc.hasMore ? messages.length + 1 : messages.length,
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        // Loader at top
                        return Padding(
                          padding: EdgeInsets.all(10),
                          child: _bloc.isLoading ? SpinKitThreeBounce(color: Colors.blue,) : const SizedBox.shrink(),
                        );
                      }

                      final msg = messages[index];
                      return _buildMessage(msg);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: deviceWidth / 30, vertical: deviceHeight / 100),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bloc.messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _bloc.sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: deviceWidth / 30, vertical: deviceHeight / 100),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ),
                  SizedBox(width: deviceWidth / 100),
                  CircleAvatar(
                    radius: deviceHeight / 40,
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _bloc.sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
