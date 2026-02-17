class ChatMessage {
  final String id;
  final String senderId;
  final String type; // 'text', 'image', 'document', 'contact'
  final String? content; // text content or caption
  final String? url; // file URL
  final String? caption; // for image/document
  final String? filename; // original file name
  final String? contactName;
  final String? contactPhone;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    this.content,
    this.url,
    this.caption,
    this.filename,
    this.contactName,
    this.contactPhone,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final payload = map['text'] as Map<String, dynamic>? ?? {};
    final type = payload['type'] ?? 'text';

    String? content;
    String? url;
    String? caption;
    String? filename;
    String? contactName;
    String? contactPhone;

    switch (type) {
      case 'text':
        content = payload['text']?.toString();
        break;

      case 'image':
        url = payload['url']?.toString();
        caption = payload['caption']?.toString();
        filename = payload['filename']?.toString();
        content = caption;
        break;

      case 'document':
        url = payload['url']?.toString();
        caption = payload['caption']?.toString();
        filename = payload['filename']?.toString();
        content = caption ?? filename;
        break;

      case 'audio':
        url = payload['url']?.toString();
        caption = payload['caption']?.toString();
        filename = payload['filename']?.toString();
        content = caption ?? filename;
        break;


      case 'contact':
        contactName = payload['name']?.toString();
        contactPhone = payload['phone']?.toString();
        break;

      default:
        content = payload['text']?.toString();
    }

    return ChatMessage(
      id: map['id'].toString(),
      senderId: map['sender_id'].toString(),
      type: type,
      content: content,
      url: url,
      caption: caption,
      filename: filename,
      contactName: contactName,
      contactPhone: contactPhone,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
