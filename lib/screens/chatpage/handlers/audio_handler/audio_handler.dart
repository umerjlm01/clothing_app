import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../chat_models.dart';

class AudioHandler {
  final ValueNotifier<File?> _fileNotifier = ValueNotifier<File?>(null);
  ValueNotifier<File?> get fileNotifier => _fileNotifier;

  final SupabaseClient supabase;
  AudioHandler({required this.supabase});

  /// Pick an audio file
  Future<void> pickAudio() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        _fileNotifier.value = File(result.files.first.path!);
        log('AudioHandler: Audio selected -> ${_fileNotifier.value!.path}');
      } else {
        _fileNotifier.value = null;
        log('AudioHandler: No audio selected');
      }
    } catch (e, t) {
      log('AudioHandler pickAudio error: $e \n $t');
    }
  }

  /// Clear picked audio after sending
  void clear() {
    _fileNotifier.value = null;
    log('AudioHandler: cleared picked audio');
  }

  /// Play an audio message
  final AudioPlayer audioPlayer = AudioPlayer();
  final ValueNotifier<AudioState> audioStateNotifier =
  ValueNotifier(AudioState(isPlaying: false, currentlyPlayingPath: null));

  Future<void> playAudio(ChatMessage msg) async {
    try {
      final filename = msg.filename;
      if (filename == null) return;

      final url = supabase.storage.from('chat-images').getPublicUrl(filename);
      final currentState = audioStateNotifier.value;

      if (currentState.isPlaying && currentState.currentlyPlayingPath == filename) {
        await audioPlayer.pause();
        audioStateNotifier.value = AudioState(isPlaying: false, currentlyPlayingPath: null);
      } else {
        await audioPlayer.play(UrlSource(url));
        audioStateNotifier.value = AudioState(isPlaying: true, currentlyPlayingPath: filename);
      }
    } catch (e, t) {
      log('AudioHandler playAudio error: $e \n $t');
    }
  }
}

class AudioState {
  final bool isPlaying;
  final String? currentlyPlayingPath;

  AudioState({required this.isPlaying, this.currentlyPlayingPath});
}
