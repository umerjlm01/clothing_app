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
          'token': supabase.auth.currentSession?.accessToken,
          'receiver_id': receiverId,
          'title': title,
          'body': body,
          'conversation_id': conversationId ?? '',
        },
      );

      log('PushNotification sent successfully: ${response.status}');
    } on FunctionException catch (e, t) {
      log('PushNotificationService trigger error: ${e.details} \n $t');

      if (e.details is Map<String, dynamic>) {
        final details = e.details as Map<String, dynamic>;

        if (details['error']?['errorCode'] == 'UNREGISTERED') {
          log('FCM token invalid, removed from DB: $receiverId');
        }
      }
    } catch (e, t) {
      log('PushNotificationService unexpected error: $e \n$t');
    }
  }

}
