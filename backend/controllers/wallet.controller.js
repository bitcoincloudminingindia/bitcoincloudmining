const mongoose = require('mongoose');
const Wallet = require('../models/wallet.model');
const { ProcessedTransaction } = require('../models/wallet.model');
const User = require('../models/user.model');
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
    const formattedBalance = formatBTC(wallet.balance);
    wallet.balance = formattedBalance;

    // Get all transactions for this wallet
    const Transaction = require('../models/transaction.model');
    const transactions = await Transaction.find({
      userId,
      status: 'completed'
    }).sort({ timestamp: -1 });

    // Format all transaction amounts to proper decimal format
    const formattedTransactions = transactions.map(tx => {
      const doc = tx.toObject();
      try {
        // Safely format amounts, falling back to 0 if invalid
        if (doc.amount) {
          const amt = typeof doc.amount === 'object' ? doc.amount.toString() : doc.amount;
          doc.amount = formatBTC(amt);
        }
        if (doc.netAmount) {
          const netAmt = typeof doc.netAmount === 'object' ? doc.netAmount.toString() : doc.netAmount;
          doc.netAmount = formatBTC(netAmt);
        } else if (doc.amount) {
          doc.netAmount = doc.amount;
        }

        if (doc.details) {
          if (doc.details.balanceBefore) {
            const before = typeof doc.details.balanceBefore === 'object' ?
              doc.details.balanceBefore.toString() : doc.details.balanceBefore;
            doc.details.balanceBefore = formatBTC(before);
          }
          if (doc.details.balanceAfter) {
            const after = typeof doc.details.balanceAfter === 'object' ?
              doc.details.balanceAfter.toString() : doc.details.balanceAfter;
            doc.details.balanceAfter = formatBTC(after);
          }
          if (doc.details.originalAmount) {
            const origAmt = typeof doc.details.originalAmount === 'object' ?
              doc.details.originalAmount.toString() : doc.details.originalAmount;
            doc.details.originalAmount = formatBTC(origAmt);
          }
          if (doc.details.originalNetAmount) {
            const origNetAmt = typeof doc.details.originalNetAmount === 'object' ?
              doc.details.originalNetAmount.toString() : doc.details.originalNetAmount;
            doc.details.originalNetAmount = formatBTC(origNetAmt);
          }
        }
      } catch (err) {
        logger.error('Error formatting transaction amounts:', {
          error: err,
          transactionId: doc._id,
          amount: doc.amount,
          netAmount: doc.netAmount
        });
      }
      return doc;
    });

    // Calculate the actual balance from completed transactions
    const balance = formattedTransactions.reduce((acc, tx) => {
      try {
        // Start with the most precise amount available
        let amount;

        if (tx.details) {
          if (tx.details.originalAmount) {
            amount = new BigNumber(tx.details.originalAmount);
          } else if (tx.details.originalNetAmount) {
            // Handle scientific notation like '1e-15'
            const netAmount = tx.details.originalNetAmount.toString();
            if (netAmount.includes('e')) {
              amount = new BigNumber(fromScientific(netAmount));
            } else {
              amount = new BigNumber(netAmount);
            }
          }
        }

        // Fallback to other amounts if needed
        if (!amount || amount.isNaN()) {
          amount = new BigNumber(tx.netAmount || tx.amount || '0');
        }

        // Log the amount being processed
        logger.debug('Processing transaction:', {
          transactionId: tx.transactionId,
          type: tx.type,
          originalAmount: tx.details?.originalAmount,
          originalNetAmount: tx.details?.originalNetAmount,
          processedAmount: amount.toFixed(18)
        });

        // Add or subtract based on transaction type
        return tx.type === 'withdrawal' ? acc.minus(amount) : acc.plus(amount);
      } catch (err) {
        logger.error('Error processing transaction for balance:', {
          error: err,
          transactionId: tx._id,
          details: tx.details,
          amount: tx.amount,
          netAmount: tx.netAmount
        });
        return acc;  // Skip invalid transactions
      }
    }, toBigNumber(0));

    // Update wallet with correct balance and formatted transactions
    wallet.balance = formatBTC(balance);
    wallet.transactions = formattedTransactions;
    await wallet.save();

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
    if (!wallet) {
      throw new Error('Wallet is required');
    }

    // Ensure transactions array exists
    if (!wallet.transactions) {
      wallet.transactions = [];
    }

    // Format transaction amounts
    transaction.amount = formatBTC(transaction.amount || '0');
    if (transaction.netAmount !== undefined) {
      transaction.netAmount = formatBTC(transaction.netAmount);
    }

    // Add transaction
    wallet.transactions.push(transaction);

    // Update balance
    const amount = toBigNumber(transaction.amount || '0');
    const currentBalance = toBigNumber(wallet.balance || '0');
    const newBalance = currentBalance.plus(amount);

    // Format and save new balance
    wallet.balance = formatBTC(newBalance.toString());

    await wallet.save();

    logger.info('Transaction added to wallet:', {
      userId: wallet.userId,
      transactionId: transaction._id,
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
    const wallet = await Wallet.create({
      userId,
      balance: formatBTC('0'),
      currency: 'BTC',
      transactions: [],
      balanceHistory: []
    });

    logger.info('Initialized new wallet:', { userId });
    return wallet;
  } catch (error) {
    logger.error('Error initializing wallet:', { error, userId });
    throw error;
  }
};

module.exports = exports;