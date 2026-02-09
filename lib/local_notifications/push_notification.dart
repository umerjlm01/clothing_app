import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  final supabase = Supabase.instance.client;

  // Singleton pattern
  static final PushNotificationService _instance = PushNotificationService();
  static PushNotificationService get instance => _instance;

  /// Sends a push notification via Supabase function
  Future<void> trigger({
    required String receiverId,
    required String title,
    required String body,
    String? conversationId,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'push_notifications',
        body: {
          'token': supabase.auth.currentSession?.accessToken, // optional internal auth
          'receiver_id': receiverId,
          'title': title,
          'body': body,
          'conversation_id': conversationId ?? '',
        },
      );

      log('PushNotification sent successfully: $response');
    } catch (e, t) {
      log('PushNotificationService trigger catch: $e \n$t');
    }
  }
}
