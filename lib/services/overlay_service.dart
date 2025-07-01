import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  static bool _isOverlayActive = false;

  // Show floating bubble
  static Future<void> showFloatingBubble() async {
    try {
      if (_isOverlayActive) return;

      final bool canDrawOverlays =
          await FlutterOverlayWindow.isPermissionGranted();

      if (!canDrawOverlays) {
        // Request permission if not granted
        await FlutterOverlayWindow.requestPermission();
        return;
      }

      await FlutterOverlayWindow.showOverlay(
        height: 100,
        width: 100,
        alignment: OverlayAlignment.centerLeft,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
        enableDrag: true,
        overlayTitle: 'Bitcoin Mining',
        overlayContent: 'Tap to open app',
      );

      _isOverlayActive = true;
      debugPrint('✅ Floating bubble shown successfully');
    } catch (e) {
      debugPrint('❌ Error showing floating bubble: $e');
    }
  }

  // Hide floating bubble
  static Future<void> hideFloatingBubble() async {
    try {
      if (!_isOverlayActive) return;

      await FlutterOverlayWindow.closeOverlay();
      _isOverlayActive = false;
      debugPrint('✅ Floating bubble hidden successfully');
    } catch (e) {
      debugPrint('❌ Error hiding floating bubble: $e');
    }
  }

  // Check if overlay is active
  static bool get isOverlayActive => _isOverlayActive;

  // Request overlay permission
  static Future<bool> requestPermission() async {
    try {
      final bool? granted = await FlutterOverlayWindow.requestPermission();
      debugPrint('Overlay permission granted: $granted');
      return granted ?? false;
    } catch (e) {
      debugPrint('❌ Error requesting overlay permission: $e');
      return false;
    }
  }

  // Check if permission is granted
  static Future<bool> isPermissionGranted() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      debugPrint('❌ Error checking overlay permission: $e');
      return false;
    }
  }
}
