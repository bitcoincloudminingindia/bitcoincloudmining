const User = require('../models/user.model');
const Transaction = require('../models/transaction.model');
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
  try {
    const userId = req.user.userId;
    const { type, amount, netAmount, status, description, currency = 'BTC', destination, details = {} } = req.body;

    // Validate required fields
    if (!type || !amount) {
      throw new ApiError(400, 'Type and amount are required');
    }

    // Get or create wallet
    const wallet = await getOrCreateWallet(userId);
    logger.info('Got wallet for transaction:', { userId, walletId: wallet._id });

    // Validate wallet state
    if (!wallet || typeof wallet.balance !== 'string') {
      throw new ApiError(500, 'Invalid wallet state');
    }

    // Ensure wallet has a balance
    if (!wallet.balance) {
      wallet.balance = '0.000000000000000000';
      await wallet.save();
    }

    // Calculate balances with BigNumber for precision
    const currentBalance = toBigNumber(wallet.balance);
    const transactionAmount = toBigNumber(netAmount || amount);

    // Format the current balance and transaction amount
    const formattedCurrentBalance = formatBTC(currentBalance);
    const formattedTransactionAmount = formatBTC(transactionAmount);

    // Calculate new balance based on transaction type
    let newBalance;
    if (type === 'withdrawal') {
      if (currentBalance.isLessThan(transactionAmount)) {
        throw new ApiError(400, 'Insufficient balance');
      }
      newBalance = currentBalance.minus(transactionAmount);
    } else {
      newBalance = currentBalance.plus(transactionAmount);
    }

    // Format all amounts for consistency
    const formattedAmount = formatBTC(amount);
    const formattedNetAmount = formatBTC(netAmount || amount);
    const formattedBalanceBefore = formatBTC(currentBalance);
    const formattedBalanceAfter = formatBTC(newBalance);

    // Get exchange rate with fallback
    let exchangeRate = DEFAULT_BTC_RATE;
    let localAmount = '0.00';
    try {
      exchangeRate = await getExchangeRate('BTC', 'USD');
      localAmount = formatUSD(new BigNumber(formattedAmount).times(exchangeRate));
    } catch (error) {
      logger.warn('Using default exchange rate:', { rate: exchangeRate, error: error.message });
    }

    // Generate transaction ID
    const transactionId = generateTransactionId();

    // Create transaction with full details
    const transaction = await Transaction.create({
      transactionId,
      userId,
      type,
      amount: formattedAmount,
      netAmount: formattedNetAmount,
      status: status || 'completed',
      description,
      currency,
      destination,
      exchangeRate,
      localAmount,
      details: {
        ...details,
        balanceBefore: formattedBalanceBefore,
        balanceAfter: formattedBalanceAfter,
        exchangeRate,
        localAmount,
        originalAmount: formattedAmount,
        originalNetAmount: formattedNetAmount
      },
      timestamp: new Date()
    });

    // Update wallet balance and add transaction
    wallet.balance = formattedBalanceAfter;

    // Initialize transactions array if needed
    if (!wallet.transactions) {
      wallet.transactions = [];
    }

    // Add transaction to wallet's history
    wallet.transactions.push(transaction);

    // Save wallet with retry mechanism
    let retries = 3;
    while (retries > 0) {
      try {
        await wallet.save();
        break;
      } catch (error) {
        retries--;
        if (retries === 0) {
          logger.error('Failed to save wallet after retries:', { error, userId });
          await Transaction.findByIdAndDelete(transaction._id);
          throw new ApiError(500, 'Failed to save wallet after retries');
        }
        await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1s between retries
      }
    }

    // Log success
    logger.info('Transaction created successfully:', {
      transactionId,
      userId,
      type,
      amount: formattedAmount,
      newBalance: formattedBalanceAfter
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

    res.status(201).json({
      success: true,
      data: transaction
    });

  } catch (error) {
    logger.error('Error in createTransaction:', error);
    res.status(error.status || 500).json({
      success: false,
      message: error.message || 'Error creating transaction'
    });
  }
};

// Get user transactions
exports.getUserTransactions = async (req, res) => {
  try {
    const wallet = await getOrCreateWallet(req.user.userId);

    // Format transactions for response
    const transactions = wallet.transactions.map(tx => {
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
        transactions: transactions || []
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

module.exports = {
  createTransaction: exports.createTransaction,
  getUserTransactions: exports.getUserTransactions,
  getTransactionById: exports.getTransactionById,
  getTransactionStats: exports.getTransactionStats
};