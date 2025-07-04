const mongoose = require('mongoose');
const { User, Wallet, Withdrawal } = require('../models');
const { sendEmail } = require('../services/email.service');
const { getBTCPrice } = require('../services/price.service');
const logger = require('../utils/logger');
const { generateWithdrawalId } = require('../utils/helpers');
const { validateWithdrawal } = require('../utils/withdrawal.validation');
const { formatBTC } = require('../utils/format');
const BigNumber = require('bignumber.js');
const { v4: uuidv4 } = require('uuid');

// Create a new withdrawal
exports.createWithdrawal = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { amount, currency, method, destination, btcAmount } = req.body;
    const userId = req.user.userId;

    // Validate withdrawal data
    const validationError = validateWithdrawal(req.body);
    if (validationError) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: validationError
      });
    }

    // Format and validate amount
    const formattedAmount = formatBTC(btcAmount || amount);
    if (new BigNumber(formattedAmount).isLessThanOrEqualTo(0)) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Invalid withdrawal amount'
      });
    }

    // Get user's wallet with session
    const wallet = await Wallet.findOne({ userId }, null, { session });
    if (!wallet) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }

    // Calculate withdrawal amount in BTC
    const withdrawalAmount = new BigNumber(btcAmount || amount);
    const minAmount = new BigNumber('0.00005'); // 0.00005 BTC

    // Validate minimum amount
    if (withdrawalAmount.lt(minAmount)) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Minimum withdrawal amount is 0.00005 BTC'
      });
    }

    // Check if user has sufficient balance
    const currentBalance = new BigNumber(wallet.balance);
    if (currentBalance.lt(withdrawalAmount)) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Insufficient balance'
      });
    }

    // Calculate fees (0.5% of withdrawal amount)
    const fees = withdrawalAmount.times(0.005).toFixed(18);
    const netAmount = withdrawalAmount.minus(fees).toFixed(18);

    try {
      // First get the user's ObjectId
      const user = await User.findOne({ userId: req.user.userId }, null, { session });
      if (!user) {
        throw new Error('User not found');
      }

      // Calculate local amount and exchange rate once for both withdrawal and transaction
      let localCurrency = 'USD';
      let withdrawalLocalAmount = '0.00';
      let finalExchangeRate = '1';
      try {
        // Fetch market rates from controller (internal API call)
        let btcPriceUSD = 0;
        let marketRates = {};
        try {
          const response = await axios.get('http://localhost:5000/api/market/rates');
          if (response.data && response.data.success) {
            btcPriceUSD = response.data.data.btcPrice;
            marketRates = response.data.data.rates;
          }
        } catch (e) {
          logger.warn('Failed to fetch market rates from API, using fallback:', e.message);
          btcPriceUSD = await getBTCPrice();
          marketRates = { USD: 1, INR: 83 };
        }

        let usdToInrRate = marketRates.INR || 83;

        if (method === 'Paypal') {
          // BTC to USD for Paypal
          localCurrency = 'USD';
          finalExchangeRate = btcPriceUSD.toString();
          withdrawalLocalAmount = new BigNumber(netAmount)
            .times(btcPriceUSD)
            .toFixed(10, BigNumber.ROUND_DOWN); // 10 decimals for USD
        } else if (method === 'Paytm') {
          // BTC to USD to INR for Paytm
          localCurrency = 'INR';
          const btcToInr = new BigNumber(btcPriceUSD).times(usdToInrRate);
          finalExchangeRate = btcToInr.toFixed(4, BigNumber.ROUND_DOWN); // 4 decimals for INR rate
          withdrawalLocalAmount = new BigNumber(netAmount)
            .times(btcToInr)
            .toFixed(10, BigNumber.ROUND_DOWN); // 10 decimals for INR
        } else {
          // Default: BTC to USD
          localCurrency = 'USD';
          finalExchangeRate = btcPriceUSD.toString();
          withdrawalLocalAmount = new BigNumber(netAmount)
            .times(btcPriceUSD)
            .toFixed(10, BigNumber.ROUND_DOWN); // 10 decimals for USD
        }

        logger.info('Withdrawal calculation:', {
          btcAmount: withdrawalAmount.toString(),
          localAmount: withdrawalLocalAmount,
          exchangeRate: finalExchangeRate,
          currency: localCurrency
        });
      } catch (error) {
        logger.warn('Error calculating local amount:', error);
      }

      // Create withdrawal record with session
      const withdrawal = new Withdrawal({
        withdrawalId: generateWithdrawalId(),
        transactionId: uuidv4(),
        user: user._id,
        amount: withdrawalAmount.toFixed(18),
        netAmount,
        fees,
        currency: 'BTC',
        originalAmount: amount,
        destinationAddress: destination,
        destinationType: method,
        status: 'pending',
        localAmount: withdrawalLocalAmount,
        exchangeRate: finalExchangeRate.toString(),
        originalCurrency: currency
      });

      await withdrawal.save({ session });

      // Create transaction using the same local amount and exchange rate
      const transaction = {
        userId: req.user.userId,
        transactionId: uuidv4(),
        type: `withdrawal_${method.toLowerCase()}`,
        amount: withdrawalAmount.toFixed(18),
        netAmount,
        status: 'pending',
        timestamp: new Date(),
        description: `Withdrawal request to ${method}`,
        currency: 'BTC',
        localAmount: withdrawalLocalAmount,
        exchangeRate: finalExchangeRate,
        details: {
          withdrawalId: withdrawal.withdrawalId,
          method,
          destination,
          fees,
          localAmount: withdrawalLocalAmount,
          exchangeRate: finalExchangeRate,
          localCurrency,
          btcAmount: withdrawalAmount.toFixed(18)
        }
      };

      // Calculate new balance after withdrawal
      const newBalance = currentBalance.minus(withdrawalAmount).toFixed(18);

      // Update wallet using atomic operation
      await Wallet.updateOne(
        { userId: req.user.userId },
        {
          $set: { balance: newBalance },
          $push: { transactions: transaction }
        },
        { session }
      );

      // Update user balance in embedded wallet (if exists) and top-level balance
      await User.updateOne(
        { userId: req.user.userId },
        {
          $set: {
            balance: newBalance,
            lastBalanceUpdate: new Date(),
            ...(user.wallet ? { 'wallet.balance': newBalance } : {})
          }
        },
        { session }
      );

      // Add the transaction to the Transaction collection
      await mongoose.model('Transaction').create([transaction], { session });

      // Commit the transaction
      await session.commitTransaction();

      logger.info('Withdrawal request created:', {
        userId,
        withdrawalId: withdrawal.withdrawalId,
        amount: withdrawal.amount
      });

      return res.status(201).json({
        success: true,
        data: {
          withdrawal,
          wallet
        }
      });

    } catch (error) {
      await session.abortTransaction();
      logger.error('Error creating withdrawal records:', error);
      return res.status(500).json({
        success: false,
        message: 'Failed to create withdrawal records',
        error: error.message
      });
    }
  } catch (error) {
    await session.abortTransaction();
    logger.error('Error creating withdrawal:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to create withdrawal request',
      error: error.message
    });
  }
};

// Get all withdrawals for a user
exports.getUserWithdrawals = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const status = req.query.status;

    const query = { user: req.user._id };
    if (status) query.status = status;

    const withdrawals = await Withdrawal.Withdrawal.find(query)
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);

    const total = await Withdrawal.Withdrawal.countDocuments(query);
    const totalPages = Math.ceil(total / limit);

    res.json({
      success: true,
      data: {
        withdrawals,
        currentPage: page,
        total,
        totalPages
      }
    });
  } catch (error) {
    logger.error('Error fetching withdrawals:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching withdrawals',
      error: error.message
    });
  }
};

// Get a specific withdrawal
exports.getWithdrawalById = async (req, res) => {
  try {
    const withdrawal = await Withdrawal.Withwithdrawal.findOne({
      withdrawalId: req.params.id,
      user: req.user._id
    });

    if (!withdrawal) {
      return res.status(404).json({
        success: false,
        message: 'Withdrawal not found'
      });
    }

    res.json({
      success: true,
      data: {
        withdrawal
      }
    });
  } catch (error) {
    logger.error('Error fetching withdrawal:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching withdrawal details',
      error: error.message
    });
  }
};

// Cancel a withdrawal
exports.cancelWithdrawal = async (req, res) => {
  try {
    const withdrawal = await Withdrawal.Withdrawal.findOne({
      withdrawalId: req.params.id,
      user: req.user._id,
      status: 'pending'
    });

    if (!withdrawal) {
      return res.status(404).json({
        success: false,
        message: 'Withdrawal not found or cannot be cancelled'
      });
    }

    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      // Update withdrawal status within the session
      withdrawal.status = 'cancelled';
      withdrawal.rejectionReason = 'Cancelled by user';
      await withdrawal.save({ session });

      // Get wallet with session
      const wallet = await Wallet.findOne({ userId: req.user.userId }).session(session);
      if (wallet) {
        const refundAmount = new BigNumber(withdrawal.amount);
        const currentBalance = new BigNumber(wallet.balance);
        const newBalance = currentBalance.plus(refundAmount).toFixed(18);

        // Create refund transaction
        const refundTransaction = {
          transactionId: uuidv4(),
          userId: req.user.userId,
          type: 'refund',
          amount: withdrawal.amount,
          netAmount: withdrawal.amount,
          status: 'completed',
          timestamp: new Date(),
          description: 'Withdrawal cancelled - refund',
          currency: 'BTC',
          details: {
            withdrawalId: withdrawal.withdrawalId,
            reason: 'Cancelled by user'
          }
        };

        // Update wallet balance and add transaction atomically
        await Wallet.updateOne(
          { userId: req.user.userId },
          {
            $set: { balance: newBalance },
            $push: { transactions: refundTransaction }
          },
          { session }
        );

        // Update user balance atomically
        await User.updateOne(
          { userId: req.user.userId },
          {
            $set: {
              balance: newBalance,
              lastBalanceUpdate: new Date()
            }
          },
          { session }
        );

        // Add refund transaction to Transaction collection
        await mongoose.model('Transaction').create([refundTransaction], { session });

        // Commit the transaction
        await session.commitTransaction();
      }
    } catch (error) {
      // Rollback the transaction if any error occurs
      await session.abortTransaction();
      throw error;
    } finally {
      // End the session
      session.endSession();
      const refundTransaction = {
        transactionId: uuidv4(),
        userId: req.user.userId,  // Add required userId field
        type: 'refund',
        amount: withdrawal.amount,
        netAmount: withdrawal.amount,  // Add required netAmount field
        status: 'completed',
        timestamp: new Date(),
        description: 'Withdrawal cancelled - refund',
        currency: 'BTC',
        details: {
          withdrawalId: withdrawal.withdrawalId,
          reason: 'Cancelled by user'
        }
      };

      await Wallet.findOneAndUpdate(
        { _id: wallet._id },
        {
          $push: { transactions: refundTransaction }
        }
      );
    }

    res.json({
      success: true,
      data: {
        withdrawal,
        message: 'Withdrawal cancelled and amount refunded'
      }
    });
  } catch (error) {
    logger.error('Error cancelling withdrawal:', error);
    res.status(500).json({
      success: false,
      message: 'Error cancelling withdrawal',
      error: error.message
    });
  }
};

// Claim a rejected transaction
exports.claimRejectedTransaction = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { transactionId } = req.body;
    const userId = req.user.userId;

    // Find the withdrawal with the associated transaction
    const withdrawal = await Withdrawal.findOne({
      transactionId,
      user: req.user._id,
      status: 'rejected'
    }).session(session);

    if (!withdrawal) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Rejected withdrawal not found'
      });
    }

    // Calculate refund amount (original amount)
    const refundAmount = new BigNumber(withdrawal.amount);

    // Get user's wallet
    const wallet = await Wallet.findOne({ userId }).session(session);
    if (!wallet) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Wallet not found'
      });
    }

    const currentBalance = new BigNumber(wallet.balance);
    const newBalance = currentBalance.plus(refundAmount).toFixed(18);

    // Create refund transaction
    const refundTransaction = {
      transactionId: uuidv4(),
      userId: req.user.userId,
      type: 'refund',
      amount: withdrawal.amount,
      netAmount: withdrawal.amount,
      status: 'completed',
      timestamp: new Date(),
      description: 'Rejected withdrawal claim - refund',
      currency: 'BTC',
      details: {
        withdrawalId: withdrawal.withdrawalId,
        originalTransactionId: transactionId,
        reason: 'Rejected withdrawal claimed'
      }
    };

    // Update wallet balance and add transaction atomically
    await Wallet.updateOne(
      { userId },
      {
        $set: { balance: newBalance },
        $push: { transactions: refundTransaction }
      },
      { session }
    );

    // Update user balance atomically
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

    // Add refund transaction to Transaction collection
    await mongoose.model('Transaction').create([refundTransaction], { session });

    // Update withdrawal status to claimed
    withdrawal.status = 'claimed';
    withdrawal.claimedAt = new Date();
    await withdrawal.save({ session });

    // Commit the transaction
    await session.commitTransaction();

    res.status(200).json({
      success: true,
      message: 'Rejected withdrawal claimed successfully',
      data: {
        newBalance,
        transaction: refundTransaction
      }
    });

  } catch (error) {
    await session.abortTransaction();
    logger.error('Error claiming rejected withdrawal:', error);
    res.status(500).json({
      success: false,
      message: 'Error claiming rejected withdrawal',
      error: error.message
    });
  } finally {
    session.endSession();
  }
};

// When processing/approving/rejecting the withdrawal elsewhere in your code:
// Example for approval:
// await Transaction.updateOne(
//  { transactionId: withdrawal.transactionId },
//  { $set: { status: 'completed' } }
// );

// Example for rejection:
// await Transaction.updateOne(
//  { transactionId: withdrawal.transactionId },
//  { $set: { status: 'rejected' } }
// );