const Wallet = require('../models/wallet.model');
const logger = require('../utils/logger');

// Get user transactions
const getUserTransactions = async (userId, page = 1, limit = 10) => {
  try {
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      throw new Error('Wallet not found');
    }

    const startIndex = (page - 1) * limit;
    const endIndex = page * limit;
    const transactions = wallet.transactions.slice(startIndex, endIndex);

    return {
      transactions,
      total: wallet.transactions.length,
      page,
      limit,
      totalPages: Math.ceil(wallet.transactions.length / limit)
    };
  } catch (error) {
    logger.error('Error getting user transactions:', error);
    throw error;
  }
};

// Get transaction by ID
const getTransactionById = async (userId, transactionId) => {
  try {
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      throw new Error('Wallet not found');
    }

    const transaction = wallet.transactions.find(
      t => t.transactionId === transactionId
    );

    if (!transaction) {
      throw new Error('Transaction not found');
    }

    return transaction;
  } catch (error) {
    logger.error('Error getting transaction by ID:', error);
    throw error;
  }
};

// Get transaction statistics
const getTransactionStats = async (userId) => {
  try {
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      throw new Error('Wallet not found');
    }

    const stats = {
      totalDeposits: 0,
      totalWithdrawals: 0,
      totalRewards: 0,
      totalReferrals: 0,
      totalDailyRewards: 0
    };

    wallet.transactions.forEach(transaction => {
      const amount = parseFloat(transaction.amount);
      switch (transaction.type) {
        case 'deposit':
          stats.totalDeposits += amount;
          break;
        case 'withdrawal':
          stats.totalWithdrawals += amount;
          break;
        case 'reward':
          stats.totalRewards += amount;
          break;
        case 'referral':
          stats.totalReferrals += amount;
          break;
        case 'daily_reward':
          stats.totalDailyRewards += amount;
          break;
      }
    });

    return stats;
  } catch (error) {
    logger.error('Error getting transaction stats:', error);
    throw error;
  }
};

module.exports = {
  getUserTransactions,
  getTransactionById,
  getTransactionStats
}; 