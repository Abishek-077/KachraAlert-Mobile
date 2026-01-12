import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playAlert() async {
    await _player.stop();
    await _player.play(AssetSource('sounds/gadiwala.mp3'));
  }
}
