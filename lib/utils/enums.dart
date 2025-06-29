// Notification categories
enum NotificationCategory {
  game,
  wallet,
  system,
  info,
  success,
  warning,
  error
}

// Transaction status
enum TransactionStatus { pending, completed, failed, cancelled }

// Transaction types
enum TransactionType {
  mining,
  withdrawal,
  deposit,
  tap,
  referral,
  penalty,
  dailyReward,
  gamingReward,
  game,
  streakReward,
  youtubeReward,
  twitterReward,
  telegramReward,
  instagramReward,
  facebookReward,
  tiktokReward,
  socialReward,
  adReward,
  withdrawalBitcoin,
  withdrawalPaypal,
  withdrawalPaytm
}

// Get string value for transaction type
extension TransactionTypeExtension on TransactionType {
  String get value {
    switch (this) {
      case TransactionType.mining:
        return 'mining';
      case TransactionType.withdrawal:
        return 'withdrawal';
      case TransactionType.deposit:
        return 'deposit';
      case TransactionType.tap:
        return 'tap';
      case TransactionType.referral:
        return 'referral';
      case TransactionType.penalty:
        return 'penalty';
      case TransactionType.dailyReward:
        return 'daily_reward';
      case TransactionType.gamingReward:
        return 'gaming_reward';
      case TransactionType.game:
        return 'game';
      case TransactionType.streakReward:
        return 'streak_reward';
      case TransactionType.youtubeReward:
        return 'youtube_reward';
      case TransactionType.twitterReward:
        return 'twitter_reward';
      case TransactionType.telegramReward:
        return 'telegram_reward';
      case TransactionType.instagramReward:
        return 'instagram_reward';
      case TransactionType.facebookReward:
        return 'facebook_reward';
      case TransactionType.tiktokReward:
        return 'tiktok_reward';
      case TransactionType.socialReward:
        return 'social_reward';
      case TransactionType.adReward:
        return 'ad_reward';
      case TransactionType.withdrawalBitcoin:
        return 'withdrawal_bitcoin';
      case TransactionType.withdrawalPaypal:
        return 'withdrawal_paypal';
      case TransactionType.withdrawalPaytm:
        return 'withdrawal_paytm';
    }
  }
}

// Get string value for transaction status
extension TransactionStatusExtension on TransactionStatus {
  String get value {
    switch (this) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Payment methods
enum PaymentMethod { bitcoin, paytm, paypal }

// Mining status
enum MiningStatus { active, inactive, paused }

// User roles
enum UserRole { user, admin, moderator }

// OTP purpose
enum OtpPurpose { registration, signup, login, resetPassword }
