const crypto = require('crypto');
const User = require('../models/user.model');

/**
 * Generate a unique 8-character referral code for a user
 * @param {string} userId - The user's ID
 * @returns {string} The generated referral code
 */
const generateReferralCode = (userId) => {
  try {
    // Create a hash of the user ID
    const hash = crypto.createHash('sha256').update(userId).digest('hex');
    
    // Take first 8 characters and convert to uppercase
    const code = hash.substring(0, 8).toUpperCase();
    
    return code;
  } catch (error) {
    console.error('Error generating referral code:', error);
    throw error;
  }
};

/**
 * Validate a referral code
 * @param {string} code - The referral code to validate
 * @returns {boolean} Whether the code is valid
 */
const validateReferralCode = (code) => {
  // Check if code is 8 characters long and contains only alphanumeric characters
  return /^[A-Z0-9]{8}$/.test(code);
};

module.exports = {
  generateReferralCode,
  validateReferralCode
}; 