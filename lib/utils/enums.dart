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
  daily_reward,
  gaming_reward,
  game,
  streak_reward,
  youtube_reward,
  twitter_reward,
  telegram_reward,
  instagram_reward,
  facebook_reward,
  tiktok_reward,
  social_reward,
  ad_reward,
  withdrawal_bitcoin,
  withdrawal_paypal,
  withdrawal_paytm
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
      case TransactionType.daily_reward:
        return 'daily_reward';
      case TransactionType.gaming_reward:
        return 'gaming_reward';
      case TransactionType.game:
        return 'game';
      case TransactionType.streak_reward:
        return 'streak_reward';
      case TransactionType.youtube_reward:
        return 'youtube_reward';
      case TransactionType.twitter_reward:
        return 'twitter_reward';
      case TransactionType.telegram_reward:
        return 'telegram_reward';
      case TransactionType.instagram_reward:
        return 'instagram_reward';
      case TransactionType.facebook_reward:
        return 'facebook_reward';
      case TransactionType.tiktok_reward:
        return 'tiktok_reward';
      case TransactionType.social_reward:
        return 'social_reward';
      case TransactionType.ad_reward:
        return 'ad_reward';
      case TransactionType.withdrawal_bitcoin:
        return 'withdrawal_bitcoin';
      case TransactionType.withdrawal_paypal:
        return 'withdrawal_paypal';
      case TransactionType.withdrawal_paytm:
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
