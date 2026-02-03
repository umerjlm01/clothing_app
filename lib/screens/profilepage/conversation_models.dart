class Conversation {
  final String id; // concatenated user IDs
  final String senderId;
  final String receiverId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
  });

  // Convert JSON from Supabase to Conversation object
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Convert Conversation object to JSON for insert/update
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
