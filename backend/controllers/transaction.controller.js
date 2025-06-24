const mongoose = require('mongoose');
const { User, Wallet, Transaction } = require('../models');
const ClaimCheck = require('../models/claimCheck.model');
const ApiError = require('../utils/ApiError');
const { formatBTC, formatUSD, BigNumber, toBigNumber } = require('../utils/format');
const { sendEmail } = require('../utils/email');
const { calculateFees } = require('../utils/fees');
const { getExchangeRate, DEFAULT_BTC_RATE } = require('../utils/exchange');
const { generateTransactionId } = require('../utils/generators');
const { sendTransactionNotification } = require('../utils/email');
const { sendNotification } = require('../utils/notification');
const { getOrCreateWallet } = require('../utils/wallet');
const logger = require('../utils/logger');

// Create transaction with robust error handling
exports.createTransaction = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const userId = req.user.userId;
    const { type, amount, netAmount, status, description, currency = 'BTC', destination, details = {} } = req.body;

    // Validate required fields
    if (!type || !amount) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Type and amount are required'
      });
    }

    // Get or create wallet using the session
    const wallet = await getOrCreateWallet(userId, session);
    logger.info('Got wallet for transaction:', { userId, walletId: wallet._id });

    // Format amounts
    const formattedAmount = formatBTC(amount);
    const formattedNetAmount = formatBTC(netAmount || amount);

    // Get exchange rate with fallback
    let exchangeRate = DEFAULT_BTC_RATE;
    let localAmount = '0.00';
    try {
      exchangeRate = await getExchangeRate('BTC', 'USD');
      localAmount = formatUSD(new BigNumber(formattedAmount).times(exchangeRate));
    } catch (error) {
      logger.warn('Using default exchange rate:', { rate: exchangeRate, error: error.message });
    }

    // Calculate localized amount for withdrawals with 10 decimal precision
    let finalLocalAmount = localAmount;
    let finalExchangeRate = exchangeRate;

    if (type.includes('withdrawal')) {
      try {
        if (type.includes('paytm')) {
          // For Paytm, convert BTC to INR
          finalExchangeRate = await getExchangeRate('BTC', 'INR');
          finalLocalAmount = new BigNumber(formattedAmount).times(finalExchangeRate).toFixed(10);
          currency = 'INR';
        } else if (type.includes('paypal')) {
          // For PayPal, we already have USD rate from earlier
          finalLocalAmount = new BigNumber(formattedAmount).times(exchangeRate).toFixed(10);
          currency = 'USD';
        }
      } catch (error) {
        logger.warn('Error calculating local amount:', { error: error.message });
      }
    }

    // Create transaction
    const transactionData = {
      transactionId: generateTransactionId(),
      type,
      amount: formattedAmount,
      netAmount: formattedNetAmount,
      status: status || 'completed',
      description,
      currency,
      destination,
      exchangeRate: finalExchangeRate,
      localAmount: finalLocalAmount,
      details: {
        ...details,
        exchangeRate: finalExchangeRate,
        localAmount: finalLocalAmount,
        originalCurrency: currency
      }
    };

    try {
      // Add transaction to wallet with balance update
      await wallet.addTransaction(transactionData);

      // Log success
      logger.info('Transaction created successfully:', {
        transactionId: transactionData.transactionId,
        userId,
        type,
        amount: formattedAmount,
        newBalance: wallet.balance
      });

      // Send notification for rewards/referrals
      if (type === 'reward' || type === 'referral') {
        await sendNotification(userId, {
          title: 'New Earning!',
          message: `You earned ${formattedAmount} BTC from ${type}`,
          type: 'earning'
        }).catch(error => {
          logger.warn('Failed to send notification:', { error, userId });
        });
      }

      await session.commitTransaction();

      return res.status(201).json({
        success: true,
        data: {
          transaction: transactionData,
          wallet: {
            balance: wallet.balance,
            pendingBalance: wallet.pendingBalance
          }
        }
      });
    } catch (error) {
      throw error;
    }
  } catch (error) {
    await session.abortTransaction();
    logger.error('Error in createTransaction:', error);
    return res.status(500).json({
      success: false,
      message: 'Error creating transaction',
      error: error.message
    });
  } finally {
    session.endSession();
  }
};

// Get user transactions
exports.getUserTransactions = async (req, res) => {
  try {
    const wallet = await getOrCreateWallet(req.user.userId);

    const transactions = await Transaction.find({
      userId: req.user.userId
      // Remove or adjust status filter if you want to include pending
      // status: { $in: ['completed', 'pending'] }
    }).sort({ timestamp: -1 });

    // Format transactions for response
    const formattedTransactions = transactions.map(tx => {
      const txObj = tx.toObject();
      try {
        // Format amounts
        if (txObj.details?.originalAmount) {
          txObj.amount = formatBTC(txObj.details.originalAmount);
        } else {
          txObj.amount = formatBTC(txObj.amount || '0');
        }

        // Format net amount if present
        if (txObj.details?.originalNetAmount) {
          txObj.netAmount = formatBTC(txObj.details.originalNetAmount);
        } else if (txObj.netAmount) {
          txObj.netAmount = formatBTC(txObj.netAmount);
        } else {
          txObj.netAmount = txObj.amount;
        }

        // Format local amount for withdrawals with 10 decimal precision
        if (txObj.type.includes('withdrawal')) {
          // Get local amount and exchange rate from root level or details
          const localAmt = txObj.localAmount || txObj.details?.localAmount || '0';
          const rate = txObj.exchangeRate || txObj.details?.exchangeRate || '1';

          // Format local amount with 10 decimals and proper currency symbol
          if (txObj.type.includes('paytm')) {
            const formattedAmount = new BigNumber(localAmt).toFixed(10, BigNumber.ROUND_DOWN);
            txObj.localAmount = formattedAmount !== '0.0000000000' ? `₹${formattedAmount}` : null;
            txObj.localCurrency = 'INR';
          } else if (txObj.type.includes('paypal')) {
            const formattedAmount = new BigNumber(localAmt).toFixed(10, BigNumber.ROUND_DOWN);
            txObj.localAmount = formattedAmount !== '0.0000000000' ? `$${formattedAmount}` : null;
            txObj.localCurrency = 'USD';
          }

          // Format exchange rate with 10 decimals
          txObj.exchangeRate = new BigNumber(rate).toFixed(10, BigNumber.ROUND_DOWN);
        }

        // Format balance changes if present
        if (txObj.details) {
          if (txObj.details.balanceBefore) {
            txObj.details.balanceBefore = formatBTC(txObj.details.balanceBefore);
          }
          if (txObj.details.balanceAfter) {
            txObj.details.balanceAfter = formatBTC(txObj.details.balanceAfter);
          }
        }

        return txObj;
      } catch (err) {
        logger.error('Error formatting transaction:', {
          error: err,
          transactionId: txObj._id,
          amount: txObj.amount,
          netAmount: txObj.netAmount,
          details: txObj.details
        });
        return {
          ...txObj,
          amount: '0.000000000000000000',
          netAmount: '0.000000000000000000'
        };
      }
    });

    res.json({
      success: true,
      data: {
        transactions: formattedTransactions || []
      }
    });
  } catch (error) {
    logger.error('Error fetching user transactions:', { error, userId: req.user.userId });
    res.status(500).json({
      success: false,
      message: 'Error fetching transactions',
      data: {
        transactions: []
      }
    });
  }
};

// Get transaction by ID
exports.getTransactionById = async (req, res) => {
  try {
    const userId = req.user.id;
    const { transactionId } = req.params;

    const transaction = await Transaction.findOne({
      userId,
      transactionId
    });

    if (!transaction) {
      return res.status(404).json({
        success: false,
        message: 'Transaction not found'
      });
    }

    res.json({
      success: true,
      data: transaction
    });
  } catch (error) {
    logger.error('Error getting transaction:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting transaction'
    });
  }
};

// Get transaction statistics
exports.getTransactionStats = async (req, res) => {
  try {
    const userId = req.user.id;
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }

    const stats = {
      totalDeposits: '0.000000000000000000',
      totalWithdrawals: '0.000000000000000000',
      totalRewards: '0.000000000000000000',
      totalReferrals: '0.000000000000000000',
      totalMining: '0.000000000000000000'
    };

    wallet.transactions.forEach(transaction => {
      const amount = new BigNumber(transaction.amount);
      switch (transaction.type) {
        case 'deposit':
          stats.totalDeposits = formatBTC(new BigNumber(stats.totalDeposits).plus(amount));
          break;
        case 'withdrawal':
          stats.totalWithdrawals = formatBTC(new BigNumber(stats.totalWithdrawals).plus(amount));
          break;
        case 'reward':
          stats.totalRewards = formatBTC(new BigNumber(stats.totalRewards).plus(amount));
          break;
        case 'referral':
          stats.totalReferrals = formatBTC(new BigNumber(stats.totalReferrals).plus(amount));
          break;
        case 'mining':
          stats.totalMining = formatBTC(new BigNumber(stats.totalMining).plus(amount));
          break;
      }
    });

    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    logger.error('Error getting transaction stats:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting transaction stats'
    });
  }
};

// Claim rejected transaction
exports.claimRejectedTransaction = async (req, res) => {
  logger.info('Claim rejected transaction request received:', {
    body: req.body,
    path: req.path,
    method: req.method
  });

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { transactionId } = req.body;
    if (!transactionId) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'TransactionId is required'
      });
    }

    const userId = req.user.userId;
    logger.info('Looking for transaction:', { transactionId, userId });

    // Check if transaction was already claimed using ClaimCheck
    const existingClaim = await ClaimCheck.findOne({
      originalTransactionId: transactionId,
      userId: req.user._id,
      type: 'claim',
      status: 'completed'
    }).session(session);

    if (existingClaim) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'This transaction has already been claimed'
      });
    }

    // Find the wallet
    const wallet = await Wallet.findOne({ userId }).session(session);
    if (!wallet) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }

    // Find transaction in wallet's transactions array
    const walletTransaction = wallet.transactions.find(t =>
      t.transactionId === transactionId ||
      t._id?.toString() === transactionId ||
      t.id === transactionId
    );

    if (!walletTransaction) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Transaction not found in wallet'
      });
    }

    // Verify transaction is rejected/failed
    const isRejected = ['rejected', 'REJECTED', 'failed', 'FAILED'].includes(walletTransaction.status?.toUpperCase());
    if (!isRejected) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Transaction is not in rejected status'
      });
    }

    // Validate amount exists
    if (!walletTransaction.amount) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Invalid transaction amount'
      });
    }

    logger.info('Processing refund for transaction:', {
      id: walletTransaction.id,
      amount: walletTransaction.amount,
      type: walletTransaction.type,
      status: walletTransaction.status
    });

    // Calculate refund amount and new balance
    const refundAmount = toBigNumber(walletTransaction.amount);
    const currentBalance = toBigNumber(wallet.balance || '0');
    const newBalance = currentBalance.plus(refundAmount).toFixed(18);

    // Create claim transaction
    const claimTransaction = {
      transactionId: generateTransactionId(),
      userId,
      type: 'deposit',
      amount: walletTransaction.amount,
      netAmount: walletTransaction.amount,
      status: 'completed',
      timestamp: new Date(),
      description: 'Rejected transaction claimed',
      currency: 'BTC',
      details: {
        claimType: 'transaction_claim',
        originalTransactionId: walletTransaction.id,
        originalType: walletTransaction.type,
        originalAmount: walletTransaction.amount,
        reason: 'Claimed rejected transaction'
      }
    };

    // Create ClaimCheck record
    const claimCheck = new ClaimCheck({
      userId: req.user._id,
      transactionId: claimTransaction.transactionId,
      originalTransactionId: transactionId,
      amount: walletTransaction.amount,
      type: 'claim',
      status: 'completed',
      description: 'Rejected transaction claim',
      details: {
        originalType: walletTransaction.type,
        walletTransactionId: walletTransaction.id,
        claimTransactionId: claimTransaction.transactionId
      }
    });

    // Save ClaimCheck
    await claimCheck.save({ session });

    // Update wallet balance and add claim transaction
    await Wallet.updateOne(
      { userId },
      {
        $set: { balance: newBalance },
        $push: { transactions: claimTransaction }
      },
      { session }
    );

    // Update user balance
    await User.updateOne(
      { userId },
      {
        $set: {
          balance: newBalance,
          lastBalanceUpdate: new Date()
        }
      },
      { session }
    );

    // Add claim transaction to Transaction collection
    await Transaction.create([claimTransaction], { session });

    // Update original transaction status
    await Wallet.updateOne(
      {
        userId,
        'transactions.id': walletTransaction.id
      },
      {
        $set: {
          'transactions.$.status': 'claimed',
          'transactions.$.claimedAt': new Date()
        }
      },
      { session }
    );

    // Commit the transaction
    await session.commitTransaction();

    logger.info('Transaction claimed successfully:', {
      userId,
      transactionId,
      newBalance,
      claimCheckId: claimCheck._id
    });

    res.status(200).json({
      success: true,
      message: 'Transaction claimed successfully',
      data: {
        newBalance,
        transaction: claimTransaction,
        claimCheck: {
          id: claimCheck._id,
          status: claimCheck.status
        }
      }
    });

  } catch (error) {
    await session.abortTransaction();
    logger.error('Error claiming transaction:', error);
    res.status(500).json({
      success: false,
      message: 'Error claiming transaction',
      error: error.message
    });
  } finally {
    session.endSession();
  }
};

module.exports = {
  createTransaction: exports.createTransaction,
  getUserTransactions: exports.getUserTransactions,
  getTransactionById: exports.getTransactionById,
  getTransactionStats: exports.getTransactionStats,
  claimRejectedTransaction: exports.claimRejectedTransaction
};