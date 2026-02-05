import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._();
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playAlert() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/gadiwala.mp3'));
    } catch (error, stackTrace) {
      debugPrint('SoundService.playAlert failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
