const crypto = require('crypto');

/**
 * Generate a unique withdrawal ID
 * @returns {string} Unique withdrawal ID
 */
const generateWithdrawalId = () => {
  return `WD${crypto.randomBytes(8).toString('hex').toUpperCase()}`;
};

/**
 * Generate a unique transaction ID
 * @returns {string} Unique transaction ID
 */
const generateTransactionId = () => {
  return `TX${crypto.randomBytes(8).toString('hex').toUpperCase()}`;
};

/**
 * Generate a unique referral code
 * @returns {string} Unique referral code
 */
const generateReferralCode = () => {
  return `REF${crypto.randomBytes(4).toString('hex').toUpperCase()}`;
};

/**
 * Format amount to specified decimal places
 * @param {number} amount - Amount to format
 * @param {number} decimals - Number of decimal places
 * @returns {number} Formatted amount
 */
const formatAmount = (amount, decimals = 8) => {
  return Number(amount.toFixed(decimals));
};

/**
 * Calculate fee for a given amount and fee percentage
 * @param {number} amount - Base amount
 * @param {number} feePercentage - Fee percentage
 * @returns {number} Calculated fee
 */
const calculateFee = (amount, feePercentage) => {
  return formatAmount(amount * (feePercentage / 100));
};

/**
 * Calculate net amount after fee
 * @param {number} amount - Base amount
 * @param {number} feePercentage - Fee percentage
 * @returns {number} Net amount after fee
 */
const calculateNetAmount = (amount, feePercentage) => {
  const fee = calculateFee(amount, feePercentage);
  return formatAmount(amount - fee);
};

module.exports = {
  generateWithdrawalId,
  generateTransactionId,
  generateReferralCode,
  formatAmount,
  calculateFee,
  calculateNetAmount
};