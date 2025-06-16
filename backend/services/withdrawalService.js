const User = require('../models/user.model');
const Wallet = require('../models/wallet.model');
const BigNumber = require('bignumber.js');
const crypto = require('crypto');
const logger = require('../utils/logger');

// Create withdrawal request
const createWithdrawalRequest = async (userId, amount, address) => {
  try {
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      throw new Error('Wallet not found');
    }

    // Generate transaction ID
    const transactionId = crypto.randomBytes(16).toString('hex');

    // Create new transaction
    const transaction = {
      type: 'withdrawal',
      amount: new BigNumber(amount).toFixed(18),
      netAmount: new BigNumber(amount).toFixed(18),
      currency: 'BTC',
      localAmount: new BigNumber(amount).times(wallet.exchangeRate).toFixed(2),
      exchangeRate: wallet.exchangeRate,
      status: 'pending',
      transactionId,
      timestamp: new Date(),
      description: 'Withdrawal request',
      address,
      completedAt: null
    };

    // Add transaction to wallet
    wallet.transactions.unshift(transaction);

    // Update balance
    await wallet.updateBalance(amount, 'subtract');

    // Update user's wallet balance
    await User.findOneAndUpdate(
      { _id: userId },
      {
        $set: {
          'wallet.balance': wallet.balance,
          'wallet.lastUpdated': new Date()
        }
      }
    );

    // Save wallet
    await wallet.save();

    return transaction;
  } catch (error) {
    logger.error('Error creating withdrawal request:', error);
    throw error;
  }
};

// Update withdrawal status
const updateWithdrawalStatus = async (transactionId, status) => {
  try {
    const wallet = await Wallet.findOne({
      'transactions.transactionId': transactionId
    });

    if (!wallet) {
      throw new Error('Transaction not found');
    }

    const transaction = wallet.transactions.find(
      t => t.transactionId === transactionId
    );

    if (!transaction) {
      throw new Error('Transaction not found');
    }

    transaction.status = status;
    if (status === 'completed') {
      transaction.completedAt = new Date();
    }

    await wallet.save();
    return transaction;
  } catch (error) {
    logger.error('Error updating withdrawal status:', error);
    throw error;
  }
};

module.exports = {
  createWithdrawalRequest,
  updateWithdrawalStatus
}; 