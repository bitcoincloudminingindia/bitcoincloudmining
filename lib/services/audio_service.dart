import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isInitialized = false;

  /// Initialize audio service
  static Future<void> initialize() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _isInitialized = true;
      debugPrint('✅ Audio service initialized successfully');
    } catch (e) {
      debugPrint('❌ Audio service initialization failed: $e');
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
      debugPrint('🔊 Playing notification sound');
    } catch (e) {
      debugPrint('❌ Failed to play notification sound: $e');
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
      debugPrint('🎵 Playing reward sound');
    } catch (e) {
      debugPrint('❌ Failed to play reward sound: $e');
    }
  }

  /// Play coin collection sound
  static Future<void> playCoinSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _audioPlayer.play(AssetSource('audio/coin_sound.mp3'));
      debugPrint('🪙 Playing coin sound');
    } catch (e) {
      debugPrint('❌ Failed to play coin sound: $e');
    }
  }

  /// Play error sound
  static Future<void> playErrorSound() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _audioPlayer.play(AssetSource('audio/error_sound.mp3'));
      debugPrint('⚠️ Playing error sound');
    } catch (e) {
      debugPrint('❌ Failed to play error sound: $e');
    }
  }

  /// Stop all sounds
  static Future<void> stopSound() async {
    try {
      await _audioPlayer.stop();
      debugPrint('🔇 Sound stopped');
    } catch (e) {
      debugPrint('❌ Failed to stop sound: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  static Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
      debugPrint('🔊 Volume set to: $volume');
    } catch (e) {
      debugPrint('❌ Failed to set volume: $e');
    }
  }

  /// Dispose audio player
  static Future<void> dispose() async {
    try {
      await _audioPlayer.dispose();
      _isInitialized = false;
      debugPrint('🧹 Audio service disposed');
    } catch (e) {
      debugPrint('❌ Failed to dispose audio service: $e');
    }
  }
}
