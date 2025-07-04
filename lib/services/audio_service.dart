import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;

  /// Initialize audio service
  static Future<void> initialize() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _isInitialized = true;
    } catch (e) {
    }
  }

  /// Play notification sound
  static Future<void> playNotificationSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Play custom notification sound
      await _audioPlayer.play(AssetSource('sounds/notification_sound.mp3'));
    } catch (e) {
      // Fallback to default system sound
      await _audioPlayer.play(AssetSource('audio/coin_sound.mp3'));
    }
  }

  /// Play reward sound
  static Future<void> playRewardSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _audioPlayer.play(AssetSource('audio/reward_sound.mp3'));
    } catch (e) {
    }
  }

  /// Play coin collection sound
  static Future<void> playCoinSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _audioPlayer.play(AssetSource('audio/coin_sound.mp3'));
    } catch (e) {
    }
  }

  /// Play error sound
  static Future<void> playErrorSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _audioPlayer.play(AssetSource('audio/error_sound.mp3'));
    } catch (e) {
    }
  }

  /// Stop all sounds
  static Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
    }
  }

  /// Set volume (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
    }
  }

  /// Dispose audio player
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
    } catch (e) {
    }
  }
}
