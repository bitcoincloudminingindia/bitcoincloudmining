const crypto = require('crypto');

/**
 * Generates a unique withdrawal ID
 * Format: WD + random 16 hex characters
 * Example: WD1234567890ABCDEF
 */
const generateWithdrawalId = () => {
  const random = crypto.randomBytes(8).toString('hex').toUpperCase();
  return `WD${random}`;
};

/**
 * Generates a unique transaction ID
 * Format: TX + random 16 hex characters
 * Example: TX1234567890ABCDEF
 */
const generateTransactionId = () => {
  const random = crypto.randomBytes(8).toString('hex').toUpperCase();
  return `TX${random}`;
};

/**
 * Generates a unique referral code
 * Format: REF + random 8 hex characters
 * Example: REF12345678
 */
const generateReferralCode = () => {
  const random = crypto.randomBytes(4).toString('hex').toUpperCase();
  return `REF${random}`;
};

/**
 * Generates a unique wallet ID
 * Format: WL + timestamp + random 4 digits
 * Example: WL1234567890123456789
 */
const generateWalletId = () => {
  const timestamp = Date.now().toString();
  const random = crypto.randomBytes(2).toString('hex');
  return `WL${timestamp}${random}`;
};

module.exports = {
  generateWithdrawalId,
  generateTransactionId,
  generateReferralCode,
  generateWalletId
}; 