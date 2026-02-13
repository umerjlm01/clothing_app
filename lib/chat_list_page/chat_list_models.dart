class ChatListItem {
  final String conversationId;
  final String receiverId;
  final String receiverName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;


  ChatListItem({
    required this.conversationId,
    required this.receiverId,
    required this.receiverName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ChatListItem.fromMap(
      Map<String, dynamic> map,
      String currentUserId,
      ) {
    // Determine who is the receiver
    final bool isCurrentUserSender = map['sender_id'] == currentUserId;

    return ChatListItem(
      conversationId: map['id'] as String,
      receiverId: isCurrentUserSender
          ? map['receiver_id'] as String
          : map['sender_id'] as String,
      receiverName: map['receiver_name'] as String,
      lastMessage: map['last_message'],
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'])
          : null,
    );
  }
}
