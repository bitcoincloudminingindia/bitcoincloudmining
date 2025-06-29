import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// 🔥 Track app open event
  static Future<void> trackAppOpen() async {
    try {
      await _analytics.logAppOpen();
      debugPrint('📊 Analytics: App open tracked');
    } catch (e) {
      debugPrint('❌ Analytics: Failed to track app open: $e');
    }
  }

  /// 🎯 Track login event
  static Future<void> trackLogin({String? method}) async {
    try {
      await _analytics.logLogin(loginMethod: method ?? 'email');
      debugPrint('📊 Analytics: Login tracked with method: $method');
    } catch (e) {
      debugPrint('❌ Analytics: Failed to track login: $e');
    }
  }

  /// 💰 Track wallet transaction
  static Future<void> trackTransaction({
    required String type,
    required double amount,
    required String currency,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'wallet_transaction',
        parameters: {
          'transaction_type': type,
          'amount': amount,
          'currency': currency,
        },
      );
      debugPrint(
          '📊 Analytics: Transaction tracked: $type - $amount $currency');
    } catch (e) {
      debugPrint('❌ Analytics: Failed to track transaction: $e');
    }
  }

  /// 🎮 Track game played
  static Future<void> trackGamePlayed({
    required String gameName,
    required int duration,
    required double earnings,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'game_played',
        parameters: {
          'game_name': gameName,
          'duration_seconds': duration,
          'earnings': earnings,
        },
      );
      debugPrint('📊 Analytics: Game tracked: $gameName - $duration seconds');
    } catch (e) {
      debugPrint('❌ Analytics: Failed to track game: $e');
    }
  }

  /// 🎁 Track reward claimed
  static Future<void> trackRewardClaimed({
    required String rewardType,
    required double amount,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'reward_claimed',
        parameters: {
          'reward_type': rewardType,
          'amount': amount,
        },
      );
      debugPrint('📊 Analytics: Reward tracked: $rewardType - $amount');
    } catch (e) {
      debugPrint('❌ Analytics: Failed to track reward: $e');
    }
  }

  /// 👥 Track referral event
  static Future<void> trackReferral({
    required String action,
    String? referralCode,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'referral_action',
        parameters: {
          'action': action,
          if (referralCode != null) 'referral_code': referralCode,
        },
      );
      debugPrint('📊 Analytics: Referral tracked: $action');
    } catch (e) {
      debugPrint('❌ Analytics: Failed to track referral: $e');
    }
  }

  /// 📱 Track notification interaction
  static Future<void> trackNotificationInteraction({
    required String notificationType,
    required String action,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'notification_interaction',
        parameters: {
          'notification_type': notificationType,
          'action': action,
        },
      );
      debugPrint(
          '📊 Analytics: Notification tracked: $notificationType - $action');
    } catch (e) {
      debugPrint('❌ Analytics: Failed to track notification: $e');
    }
  }

  /// 🎯 Track custom event
  static Future<void> trackCustomEvent({
    required String eventName,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: eventName,
        parameters: parameters,
      );
      debugPrint('📊 Analytics: Custom event tracked: $eventName');
    } catch (e) {
      debugPrint('❌ Analytics: Failed to track custom event: $e');
    }
  }

  /// 👤 Set user properties
  static Future<void> setUserProperties({
    String? userId,
    String? userType,
    String? registrationDate,
  }) async {
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }
      if (userType != null) {
        await _analytics.setUserProperty(name: 'user_type', value: userType);
      }
      if (registrationDate != null) {
        await _analytics.setUserProperty(
            name: 'registration_date', value: registrationDate);
      }
      debugPrint('📊 Analytics: User properties set');
    } catch (e) {
      debugPrint('❌ Analytics: Failed to set user properties: $e');
    }
  }

  /// 🔄 Enable/disable analytics collection
  static Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
      debugPrint(
          '📊 Analytics: Collection ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('❌ Analytics: Failed to set collection enabled: $e');
    }
  }
}
