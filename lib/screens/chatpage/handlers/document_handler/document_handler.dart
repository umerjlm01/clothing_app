import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../local_notifications/push_notification.dart';
import '../../chat_models.dart';

class DocumentHandler {
  final ValueNotifier<File?> _fileNotifier = ValueNotifier<File?>(null);
  ValueNotifier<File?> get fileNotifier => _fileNotifier;

  final SupabaseClient supabase;
  DocumentHandler({required this.supabase});

  /// Pick a document (UI-blind)
  Future<void> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        _fileNotifier.value = File(result.files.first.path!);
        log('DocumentHandler: Document selected -> ${_fileNotifier.value?.path}');
      } else {
        _fileNotifier.value = null;
        log('DocumentHandler: No document selected');
      }
    } catch (e, t) {
      log('DocumentHandler pickDocument error: $e \n $t');
    }
  }

  /// Download file and optionally trigger notification
  Future<void> downloadFile(ChatMessage msg, {
    String? currentUserId,
    String? conversationId,
  }) async {
    try {
      final storagePath = msg.filename;
      if (storagePath == null) return;
      currentUserId = supabase.auth.currentUser!.id;

      final bytes = await supabase.storage.from('chat-images').download(storagePath);
      final dir = await getApplicationDocumentsDirectory();
      final name = storagePath.split('/').last;
      final savePath = '${dir.path}/$name';
      final savedFile = File(savePath);
      await savedFile.writeAsBytes(bytes);
      log('DocumentHandler: File downloaded to $savePath');

      if (await savedFile.exists()) await openFile(savePath);

      // Trigger notification
      PushNotificationService.instance.trigger(
        receiverId: currentUserId,
        title: 'File Downloaded',
        body: 'Tap to open ${msg.filename}',
        conversationId: conversationId,
      );
    } catch (e, t) {
      log('DocumentHandler downloadFile error: $e \n $t');
    }
  }

  /// Open local file
  Future<void> openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await OpenFilex.open(filePath);
      } else {
        log("DocumentHandler: Cannot open file, does not exist -> $filePath");
      }
    } catch (e, t) {
      log('DocumentHandler openFile error: $e \n $t');
    }
  }

  /// Clear picked file after sending
  void clear() {
    _fileNotifier.value = null;
    log('DocumentHandler: cleared picked document');
  }
}
