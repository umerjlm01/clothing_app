class ChatMessage {
  final String id;
  final String senderId;
  final String type; // 'text', 'image', 'document', 'contact'
  final String? content; // text content or caption
  final String? url; // file URL
  final String? caption; // for image/document
  final String? filename; // original file name
  final String? contactName;
  final double? longitude;
  final double? latitude;
  final String? contactPhone;
  final String? location;
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
    this.longitude,
    this.latitude,
    this.contactPhone,
    this.location,
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
    double? latitude;
    double? longitude;

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
      case 'audio':
        url = payload['url']?.toString();
        caption = payload['caption']?.toString();
        filename = payload['filename']?.toString();
        content = caption ?? filename;
        break;

      case 'location':
        final latValue = payload['latitude'];
        final longValue = payload['longitude'];

        if (latValue is double) {
          latitude = latValue;
        } else if (latValue is String) {
          latitude = double.tryParse(latValue);
        }

        if (longValue is double) {
          longitude = longValue;
        } else if (longValue is String) {
          longitude = double.tryParse(longValue);
        }

        content = 'Shared Location';
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
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}