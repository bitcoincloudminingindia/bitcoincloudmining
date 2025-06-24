const mongoose = require('mongoose');
const { User, Wallet } = require('../models');
const { formatBTC, formatUSD, toBigNumber } = require('../utils/format');
const logger = require('../utils/logger');

const { getOrCreateWallet } = require('../utils/wallet');

/**
 * Get a user's wallet by userId
 */
exports.getWalletByUserId = async (userId) => {
  try {
    const wallet = await getOrCreateWallet(userId);

    // Ensure wallet balance is properly formatted
    if (!wallet.balance) {
      wallet.balance = '0.000000000000000000';
      await wallet.save();
    }

    // Format the wallet balance
    wallet.balance = formatBTC(wallet.balance);

    // Only format wallet.transactions for display, do not overwrite or merge with global transactions
    wallet.transactions = (wallet.transactions || []).map(tx => {
      if (!tx) return tx;
      if (typeof tx.toObject === 'function') tx = tx.toObject();
      if (tx.amount) tx.amount = formatBTC(tx.amount);
      if (tx.netAmount) tx.netAmount = formatBTC(tx.netAmount);
      return tx;
    });

    // Do NOT call await wallet.save() here unless you actually changed wallet data

    return wallet;
  } catch (error) {
    logger.error('Error getting wallet:', { error, userId });
    throw error;
  }
};

/**
 * Update wallet balance and add balance history
 */
exports.updateWalletBalance = async (wallet, newBalance, type = 'balance_sync') => {
  try {
    if (!wallet) {
      throw new Error('Wallet is required');
    }

    const oldBalance = toBigNumber(wallet.balance || '0');
    const updatedBalance = toBigNumber(newBalance || '0');
    const difference = updatedBalance.minus(oldBalance);

    // Only proceed if there's an actual change in balance
    if (difference.isZero() && type === 'balance_sync') {
      logger.debug('Skipping balance sync - no change in balance', {
        userId: wallet.userId,
        currentBalance: formatBTC(oldBalance.toString())
      });
      return wallet;
    }

    // Format the new balance
    wallet.balance = formatBTC(updatedBalance.toString());

    // Add to balance history if there's a change
    if (!difference.isZero()) {
      if (!wallet.balanceHistory) {
        wallet.balanceHistory = [];
      }

      // Check for recent similar entries to avoid duplicates
      const now = new Date();
      const recentEntry = wallet.balanceHistory
        .slice(-1)
        .find(entry => {
          const timeDiff = now - new Date(entry.timestamp);
          return timeDiff < 1000 && // Within last second
            entry.type === type &&
            entry.amount === formatBTC(difference.toString());
        });

      if (!recentEntry) {
        // Add new history entry
        const historyAmount = formatBTC(difference.toString());
        wallet.balanceHistory.push({
          amount: historyAmount,
          type,
          timestamp: now
        });

        logger.info('Adding balance history entry:', {
          userId: wallet.userId,
          amount: historyAmount,
          type,
          oldBalance: formatBTC(oldBalance.toString()),
          newBalance: formatBTC(updatedBalance.toString())
        });
      } else {
        logger.debug('Skipping duplicate balance history entry', {
          userId: wallet.userId,
          type,
          amount: formatBTC(difference.toString())
        });
      }
    }

    const savedWallet = await wallet.save();

    if (!difference.isZero()) {
      logger.info('Wallet balance updated successfully:', {
        userId: wallet.userId,
        oldBalance: formatBTC(oldBalance.toString()),
        newBalance: formatBTC(updatedBalance.toString()),
        difference: formatBTC(difference.toString()),
        type
      });
    }

    return savedWallet;
  } catch (error) {
    logger.error('Error updating wallet balance:', { error, userId: wallet?.userId });
    throw error;
  }
};

/**
 * Add transaction to wallet
 */
exports.addTransaction = async (wallet, transaction) => {
  try {
    if (!wallet) throw new Error('Wallet is required');
    if (!wallet.transactions) wallet.transactions = [];
    wallet.transactions.push(transaction);
    await wallet.save();

    logger.info('Transaction added to wallet:', {
      userId: wallet.userId,
      transactionId: transaction.transactionId || transaction._id,
      amount: transaction.amount,
      newBalance: wallet.balance
    });

    return wallet;
  } catch (error) {
    logger.error('Error adding transaction:', { error, userId: wallet?.userId });
    throw error;
  }
};

/**
 * Get wallet information for a user
 */
exports.getWalletInfo = async (userId) => {
  try {
    const wallet = await exports.getWalletByUserId(userId);

    // Format all amounts before returning
    const formattedWallet = {
      ...wallet.toObject(),
      balance: formatBTC(wallet.balance || '0'),
      transactions: (wallet.transactions || []).map(tx => ({
        ...tx,
        amount: formatBTC(tx.amount || '0'),
        netAmount: tx.netAmount ? formatBTC(tx.netAmount) : undefined
      })),
      balanceHistory: (wallet.balanceHistory || []).map(hist => ({
        ...hist,
        amount: formatBTC(hist.amount || '0')
      }))
    };

    return formattedWallet;
  } catch (error) {
    logger.error('Error getting wallet info:', { error, userId });
    throw error;
  }
};

/**
 * Initialize a new wallet for a user
 */
exports.initializeWallet = async (userId) => {
  try {
    // Check if wallet already exists for this user
    let wallet = await Wallet.findOne({ userId });
    if (wallet) {
      logger.info('Wallet already exists for user:', { userId });
      return wallet;
    }

    // Create initial transaction
    const initialTransaction = {
      transactionId: 'INIT-' + Date.now(),
      type: 'initial',
      amount: '0.000000000000000000',
      netAmount: '0.000000000000000000',
      status: 'completed',
      currency: 'BTC',
      description: 'Wallet initialized',
      timestamp: new Date(),
      details: {}
    };

    wallet = await Wallet.create({
      userId: userId,
      balance: formatBTC('0'),
      currency: 'BTC',
      transactions: [initialTransaction],
      balanceHistory: [{
        balance: '0.000000000000000000',
        timestamp: new Date(),
        type: 'initial',
        amount: '0.000000000000000000',
        transactionId: initialTransaction.transactionId,
        oldBalance: '0.000000000000000000'
      }]
    });

    logger.info('Initialized new wallet:', { userId });
    return wallet;
  } catch (error) {
    logger.error('Error initializing wallet:', { error, userId });
    throw error;
  }
};

/**
 * Sync wallet balance
 */
exports.syncWalletBalance = async (userId, newBalance) => {
  try {
    if (!userId || newBalance === undefined || newBalance === null) {
      throw new Error('UserId and balance are required');
    }

    // Get or create wallet
    const wallet = await getOrCreateWallet(userId);

    // Format the new balance
    const formattedNewBalance = formatBTC(newBalance);

    // Update wallet
    wallet.balance = formattedNewBalance;
    wallet.lastUpdated = new Date();

    // Add to balance history
    if (!wallet.balanceHistory) {
      wallet.balanceHistory = [];
    }

    wallet.balanceHistory.push({
      balance: formattedNewBalance,
      timestamp: new Date(),
      type: 'sync'
    });

    // Save wallet
    await wallet.save();

    return {
      balance: formattedNewBalance,
      updatedAt: wallet.lastUpdated
    };
  } catch (error) {
    logger.error('Error syncing wallet balance:', { error, userId });
    throw error;
  }
};

/**
 * Initialize wallet controller
 */
exports.initializeWalletController = async (req, res) => {
  try {
    const wallet = await getOrInitializeWallet(req.user.userId);

    return res.status(200).json({
      success: true,
      data: {
        walletId: wallet.walletId,
        balance: wallet.balance,
        pendingBalance: wallet.pendingBalance,
        lockedBalance: wallet.lockedBalance,
        verifiedBalance: wallet.verifiedBalance,
        currency: wallet.currency,
        exchangeRate: wallet.exchangeRate
      }
    });
  } catch (error) {
    console.error('❌ Error initializing wallet:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to initialize wallet'
    });
  }
};

/**
 * Get or initialize wallet for a user
 */
const getOrInitializeWallet = async (userId) => {
  try {
    // Try to find existing wallet
    let wallet = await Wallet.findOne({ userId });

    if (!wallet) {
      const user = await User.findOne({ userId });
      if (!user) {
        throw new Error('User not found');
      }

      // Create new wallet with proper formatting
      wallet = new Wallet({
        userId: userId, // FIX: use userId directly, not userId.userId
        walletId: 'WAL' + crypto.randomBytes(8).toString('hex').toUpperCase(),
        balance: '0.000000000000000000',
        pendingBalance: '0.000000000000000000',
        lockedBalance: '0.000000000000000000',
        verifiedBalance: '0.000000000000000000',
        exchangeRate: '1.0000000000',
        currency: 'BTC',
        transactions: [],
        balanceHistory: [{
          amount: '0.000000000000000000',
          timestamp: new Date(),
          type: 'initial'
        }]
      });

      await wallet.save();
      console.log('✅ New wallet initialized:', wallet.walletId);
    }

    // Ensure all required fields have proper format
    const updates = {};
    if (!wallet.pendingBalance) updates.pendingBalance = '0.000000000000000000';
    if (!wallet.lockedBalance) updates.lockedBalance = '0.000000000000000000';
    if (!wallet.verifiedBalance) updates.verifiedBalance = '0.000000000000000000';
    if (!wallet.exchangeRate) updates.exchangeRate = '1.0000000000';
    if (!wallet.balance) updates.balance = '0.000000000000000000';

    if (Object.keys(updates).length > 0) {
      await Wallet.updateOne({ _id: wallet._id }, { $set: updates });
      wallet = await Wallet.findOne({ _id: wallet._id });
    }

    return wallet;
  } catch (error) {
    console.error('❌ Error in getOrInitializeWallet:', error);
    throw error;
  }
};

module.exports = exports;