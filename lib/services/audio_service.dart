import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isMuted = false;

  static Future<void> initAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }

  static Future<void> playSound(String soundName) async {
    if (_isMuted) return;

    try {
      final source = AssetSource(soundName);
      await _audioPlayer.play(source);
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  static Future<void> playCoinSound() async {
    await playSound('coin_sound.mp3');
  }

  static Future<void> playRewardSound() async {
    await playSound('reward_sound.mp3');
  }

  static Future<void> playErrorSound() async {
    await playSound('error_sound.mp3');
  }

  static void setMuted(bool muted) {
    _isMuted = muted;
    if (muted) {
      _audioPlayer.stop();
    }
  }

  static bool get isMuted => _isMuted;

  static void dispose() {
    _audioPlayer.dispose();
  }
}
