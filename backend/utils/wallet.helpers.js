const Wallet = require('../models/wallet.model');
const User = require('../models/user.model');
const logger = require('./logger');
const BigNumber = require('bignumber.js');

// बैलेंस फॉर्मेटिंग के लिए हेल्पर फंक्शन्स
const formatBTCAmount = (amount) => {
  const num = parseFloat(amount);
  if (isNaN(num)) return '0.000000000000000000';
  return num.toFixed(18);
};

const formatPayPalAmount = (amount) => {
  return parseFloat(amount).toFixed(10);
};

const formatAmount = (amount, method) => {
  if (method === 'Paypal') {
    return formatPayPalAmount(amount);
  }
  return formatBTCAmount(amount);
};

// बैलेंस अपडेट के लिए हेल्पर फंक्शन
const updateWalletAndUserBalance = async (userId, amount, type = 'add', session = null) => {
  try {
    const wallet = await Wallet.findOne({ userId }).session(session);
    const user = await User.findOne({ userId }).session(session);

    if (!wallet || !user) {
      throw new Error('Wallet or user not found');
    }

    // Update wallet balance
    const currentBalance = new BigNumber(wallet.balance);
    const transactionAmount = new BigNumber(amount);

    if (type === 'add') {
      wallet.balance = currentBalance.plus(transactionAmount).toFixed(18);
    } else if (type === 'subtract') {
      if (currentBalance.isLessThan(transactionAmount)) {
        throw new Error('Insufficient balance');
      }
      wallet.balance = currentBalance.minus(transactionAmount).toFixed(18);
    }

    // Update user balance
    user.wallet.balance = wallet.balance;
    user.wallet.lastUpdated = new Date();

    await wallet.save({ session });
    await user.save({ session });

    return { wallet, user };
  } catch (error) {
    throw error;
  }
};

// बैलेंस वेरिफिकेशन के लिए हेल्पर फंक्शन
const verifyAndFixBalance = async (userId, session) => {
  try {
    console.log('Verifying balance for user:', userId);
    
    // Get wallet and user data
    const wallet = await Wallet.findOne({ userId }).session(session);
    const user = await User.findById(userId).session(session);

    if (!wallet || !user) {
      throw new Error('Wallet or user not found');
    }

    // Format balances to 18 decimal places
    const walletBalance = formatAmount(wallet.balance);
    const userBalance = formatAmount(user.wallet.balance);
    const verifiedBalance = formatAmount(wallet.verifiedBalance || wallet.balance);

    console.log('Current balances:', {
      walletBalance,
      userBalance,
      verifiedBalance
    });

    // Check if balances match
    if (walletBalance !== userBalance || walletBalance !== verifiedBalance) {
      console.log('Balance mismatch detected, updating balances...');
      
      // Use the highest non-zero balance
      let highestBalance = '0.000000000000000000';
      if (parseFloat(walletBalance) > 0) highestBalance = walletBalance;
      if (parseFloat(userBalance) > 0 && parseFloat(userBalance) > parseFloat(highestBalance)) {
        highestBalance = userBalance;
      }
      if (parseFloat(verifiedBalance) > 0 && parseFloat(verifiedBalance) > parseFloat(highestBalance)) {
        highestBalance = verifiedBalance;
      }

      console.log('Using highest balance:', highestBalance);
      
      // Update wallet balance
      wallet.balance = highestBalance;
      wallet.verifiedBalance = highestBalance;
      await wallet.save({ session });

      // Update user balance
      user.wallet.balance = highestBalance;
      await user.save({ session });

      console.log('Balances updated successfully');
    }

    return { wallet, user };
  } catch (error) {
    console.error('Error verifying balance:', error);
    throw error;
  }
};

// एरर हैंडलिंग के लिए हेल्पर फंक्शन
const handleError = (res, error, message) => {
  logger.error(`${message}:`, error);
  res.status(500).json({
    success: false,
    message: message,
    error: error.message
  });
};

// वैलिडेशन के लिए हेल्पर फंक्शन
const validateTransaction = (amount, type, withdrawalId) => {
  // Convert scientific notation to decimal
  const num = parseFloat(amount);
  if (isNaN(num)) {
    throw new Error('Invalid amount');
  }
  
  if (type.startsWith('Withdrawal') && !withdrawalId) {
    throw new Error('Withdrawal ID is required for withdrawal transactions');
  }

  // Validate transaction type
  const validTypes = [
    'mining',
    'withdrawal',
    'deposit',
    'tap',
    'referral',
    'penalty',
    'daily_reward',
    'gaming_reward',
    'game',
    'streak_reward',
    'youtube_reward',
    'twitter_reward',
    'telegram_reward',
    'instagram_reward',
    'facebook_reward',
    'tiktok_reward',
    'social_reward',
    'ad_reward',
    'withdrawal_bitcoin',
    'withdrawal_paypal',
    'withdrawal_paytm',
    'Withdrawal - Bitcoin',
    'Withdrawal - Paypal',
    'Withdrawal - Paytm',
    'Withdrawal - BTC',
    'claim',
    'earning'
  ];

  if (!validTypes.includes(type)) {
    throw new Error(`Invalid transaction type: ${type}`);
  }
};

// फॉर्मेटिंग के लिए हेल्पर फंक्शन
const formatTransactionAmount = (amount, type) => {
  const num = parseFloat(amount);
  if (isNaN(num)) return '0.000000000000000000';
  return type.startsWith('Withdrawal') ? 
    (-num).toFixed(18) : 
    num.toFixed(18);
};

// ट्रांजैक्शन क्रिएशन के लिए हेल्पर फंक्शन
const createTransactionObject = (userId, type, amount, status, timestamp, description, currency, transactionId, withdrawalId, details) => {
  // Format amount based on currency
  let formattedAmount;
  if (currency === 'BTC') {
    formattedAmount = formatBTCAmount(amount);
  } else if (currency === 'INR') {
    formattedAmount = formatAmount(amount);
  } else {
    formattedAmount = amount.toString();
  }

  // Validate transaction type
  const validTypes = [
    'mining',
    'withdrawal',
    'deposit',
    'tap',
    'referral',
    'penalty',
    'daily_reward',
    'gaming_reward',
    'game',
    'streak_reward',
    'youtube_reward',
    'twitter_reward',
    'telegram_reward',
    'instagram_reward',
    'facebook_reward',
    'tiktok_reward',
    'social_reward',
    'ad_reward',
    'withdrawal_bitcoin',
    'withdrawal_paypal',
    'withdrawal_paytm',
    'Withdrawal - Bitcoin',
    'Withdrawal - Paypal',
    'Withdrawal - Paytm',
    'Withdrawal - BTC',
    'claim',
    'earning'
  ];

  if (!validTypes.includes(type)) {
    throw new Error(`Invalid transaction type: ${type}`);
  }

  return {
    userId,
    type,
    amount: formattedAmount,
    status: status || 'completed',
    timestamp: timestamp || new Date(),
    description: description || '',
    currency: currency || 'BTC',
    transactionId,
    withdrawalId,
    details: {
      ...details,
      currency: currency || 'BTC'
    }
  };
};

// वॉलेट और यूजर चेक के लिए हेल्पर फंक्शन
const checkWalletAndUser = async (userId) => {
  try {
    const wallet = await Wallet.findOne({ userId });
    const user = await User.findOne({ userId });

    if (!wallet || !user) {
      throw new Error('Wallet or user not found');
    }

    return { wallet, user };
  } catch (error) {
    throw error;
  }
};

const addVerifiedBalanceToExistingWallets = async () => {
  try {
    console.log('🔄 Adding verifiedBalance to existing wallets...');
    
    const wallets = await Wallet.find({});
    let updatedCount = 0;

    for (const wallet of wallets) {
      if (!wallet.verifiedBalance || wallet.verifiedBalance === '0.000000000000000000') {
        wallet.verifiedBalance = wallet.balance;
        await wallet.save();
        updatedCount++;
      }
    }

    console.log(`✅ Updated ${updatedCount} wallets with verifiedBalance`);
    return updatedCount;
  } catch (error) {
    console.error('❌ Error adding verifiedBalance:', error);
    throw error;
  }
};

module.exports = {
  formatBTCAmount,
  formatPayPalAmount,
  formatAmount,
  updateWalletAndUserBalance,
  verifyAndFixBalance,
  handleError,
  validateTransaction,
  formatTransactionAmount,
  createTransactionObject,
  checkWalletAndUser,
  addVerifiedBalanceToExistingWallets
}; 