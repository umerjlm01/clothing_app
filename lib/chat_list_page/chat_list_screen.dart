import 'package:clothing_app/chat_list_page/chat_list_bloc.dart';
import 'package:clothing_app/chat_list_page/chat_list_models.dart';
import 'package:clothing_app/screens/chatpage/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../reusable_widgets/app_bar.dart';
import '../utils/constant_variables.dart';



class ChatListScreen extends StatefulWidget {

  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ChatListBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ChatListBloc(context, this);
  }

  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return DateFormat.Hm().format(time); // 14:30
    } else if (now.difference(time).inDays < 7) {
      return DateFormat.E().format(time); // Mon, Tue
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(preferredSize: Size.fromHeight(deviceHeight / 15), child: CustomAppBar(
        icon: const Icon(Icons.menu),
        title: Text("Chats", style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        elevation: 0,
      ),),
      body: StreamBuilder<List<ChatListItem>>(
        stream: _bloc.chatListStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatList = snapshot.data!;
          final navigator = Navigator.of(context);

          if (chatList.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          return ListView.builder(
            itemCount: chatList.length,
            itemBuilder: (context, index) {
              final chat = chatList[index];
              return Column(
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      child: Text(chat.receiverName[0].toUpperCase()),
                    ),
                    title: Text(chat.receiverName),
                    subtitle: Text(
                      chat.lastMessage ?? 'No chat yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontStyle: chat.lastMessage == null
                              ? FontStyle.italic
                              : FontStyle.normal),
                    ),
                    trailing: SizedBox(
                      width: deviceWidth / 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (chat.lastMessageAt != null)
                          Text(_formatTime(chat.lastMessageAt), style: TextStyle(
                            fontSize: deviceHeight / 85,
                            color: chat.unreadCount > 0
                              ? Color(0xFF25D366) : Colors.grey,
                            fontWeight: chat.unreadCount > 0
                              ? FontWeight.bold : FontWeight.normal,
                          ),),
                          SizedBox(height: deviceHeight / 100,),
                          if (chat.unreadCount > 0)
                            Container(
                              padding: EdgeInsets.all(deviceWidth / 170),
                              decoration: BoxDecoration(
                                color: Color(0xFF25D366),
                                borderRadius: BorderRadius.circular(deviceWidth / 2),
                                border: Border.all(color: Colors.white, width: 2),

                            ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: deviceHeight / 80,
                                ),
                              ),
                            ),

                      ]
                      )
                    ),

                    onTap: () async {
                      // Start conversation if not exists
                      if (chat.conversationId.isEmpty) {
                        await _bloc.createConversation(
                            receiverId: chat.receiverId,
                            receiverName: chat.receiverName);
                      }

                      // Navigate to chat page (replace with your chat page)

                       navigator.push (MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            conversationId: chat.conversationId,
                            receiverId: chat.receiverId,
                            receiverName: chat.receiverName,
                            currentUserId: _bloc.supabase.auth.currentUser!.id,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 2,),
                ],
              );
            },

          );
        },
      ),
    );
  }
}



