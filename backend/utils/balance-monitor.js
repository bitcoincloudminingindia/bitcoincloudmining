const logger = require('./logger');
const { Wallet } = require('../models');
const { formatBTC } = require('./format');

/**
 * Balance Monitor Utility
 * Helps track and prevent unwanted balance resets
 */

// Store recent balance changes for monitoring
const balanceChangeHistory = new Map();

/**
 * Log balance changes for monitoring
 */
const logBalanceChange = (userId, operation, beforeBalance, afterBalance, metadata = {}) => {
  const change = {
    userId,
    operation,
    beforeBalance: formatBTC(beforeBalance || '0'),
    afterBalance: formatBTC(afterBalance || '0'),
    timestamp: new Date(),
    metadata
  };

  // Store in memory for recent tracking
  if (!balanceChangeHistory.has(userId)) {
    balanceChangeHistory.set(userId, []);
  }
  
  const userHistory = balanceChangeHistory.get(userId);
  userHistory.push(change);
  
  // Keep only last 10 changes per user
  if (userHistory.length > 10) {
    userHistory.shift();
  }

  // Log significant changes
  const beforeNum = parseFloat(beforeBalance || '0');
  const afterNum = parseFloat(afterBalance || '0');
  const difference = afterNum - beforeNum;

  logger.info('Balance Change Monitored:', {
    userId,
    operation,
    beforeBalance: change.beforeBalance,
    afterBalance: change.afterBalance,
    difference: formatBTC(difference.toString()),
    metadata,
    timestamp: change.timestamp
  });

  // Alert on suspicious changes
  if (beforeNum > 0 && afterNum === 0) {
    logger.error('⚠️ SUSPICIOUS: Balance reset to zero!', {
      userId,
      operation,
      beforeBalance: change.beforeBalance,
      afterBalance: change.afterBalance,
      metadata
    });
  }

  if (Math.abs(difference) > 1) { // Significant change (> 1 BTC)
    logger.warn('⚠️ Large balance change detected:', {
      userId,
      operation,
      difference: formatBTC(difference.toString()),
      beforeBalance: change.beforeBalance,
      afterBalance: change.afterBalance,
      metadata
    });
  }
};

/**
 * Get recent balance changes for a user
 */
const getRecentBalanceChanges = (userId) => {
  return balanceChangeHistory.get(userId) || [];
};

/**
 * Verify wallet balance consistency
 */
const verifyWalletConsistency = async (userId) => {
  try {
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      logger.warn('Wallet not found during consistency check', { userId });
      return false;
    }

    // Calculate balance from transactions
    let calculatedBalance = 0;
    if (wallet.transactions && wallet.transactions.length > 0) {
      for (const tx of wallet.transactions) {
        if (tx.status === 'completed') {
          const amount = parseFloat(tx.amount || '0');
          if (['deposit', 'reward', 'mining', 'earning', 'referral', 'claim', 'tap'].includes(tx.type)) {
            calculatedBalance += amount;
          } else if (['withdrawal', 'penalty'].includes(tx.type)) {
            calculatedBalance -= amount;
          }
        }
      }
    }

    const storedBalance = parseFloat(wallet.balance || '0');
    const difference = Math.abs(calculatedBalance - storedBalance);

    if (difference > 0.000000000000001) { // Allow tiny floating point differences
      logger.error('⚠️ Wallet balance inconsistency detected!', {
        userId,
        storedBalance: formatBTC(storedBalance.toString()),
        calculatedBalance: formatBTC(calculatedBalance.toString()),
        difference: formatBTC(difference.toString()),
        transactionCount: wallet.transactions?.length || 0
      });
      return false;
    }

    return true;
  } catch (error) {
    logger.error('Error during wallet consistency check:', {
      userId,
      error: error.message
    });
    return false;
  }
};

/**
 * Safe balance update with monitoring
 */
const safeUpdateBalance = async (wallet, newBalance, operation, metadata = {}) => {
  if (!wallet) {
    throw new Error('Wallet is required for safe balance update');
  }

  const oldBalance = wallet.balance || '0.000000000000000000';
  const userId = wallet.userId;

  // Log the change
  logBalanceChange(userId, operation, oldBalance, newBalance, metadata);

  // Update balance
  wallet.balance = formatBTC(newBalance);
  wallet.lastUpdated = new Date();

  return wallet;
};

/**
 * Backup current wallet state
 */
const backupWalletState = async (userId) => {
  try {
    const wallet = await Wallet.findOne({ userId });
    if (wallet) {
      logger.info('Wallet state backup:', {
        userId,
        balance: wallet.balance,
        transactionCount: wallet.transactions?.length || 0,
        lastUpdated: wallet.lastUpdated,
        timestamp: new Date()
      });
      return {
        userId,
        balance: wallet.balance,
        transactions: wallet.transactions,
        lastUpdated: wallet.lastUpdated,
        backupTime: new Date()
      };
    }
    return null;
  } catch (error) {
    logger.error('Error creating wallet backup:', { userId, error: error.message });
    return null;
  }
};

/**
 * Get balance monitoring stats
 */
const getMonitoringStats = () => {
  const totalUsers = balanceChangeHistory.size;
  let totalChanges = 0;
  let suspiciousResets = 0;

  for (const [userId, changes] of balanceChangeHistory.entries()) {
    totalChanges += changes.length;
    suspiciousResets += changes.filter(change => 
      parseFloat(change.beforeBalance) > 0 && 
      parseFloat(change.afterBalance) === 0
    ).length;
  }

  return {
    totalUsers,
    totalChanges,
    suspiciousResets,
    timestamp: new Date()
  };
};

module.exports = {
  logBalanceChange,
  getRecentBalanceChanges,
  verifyWalletConsistency,
  safeUpdateBalance,
  backupWalletState,
  getMonitoringStats
};