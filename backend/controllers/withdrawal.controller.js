const Withdrawal = require('../models/withdrawal.model');
const Wallet = require('../models/wallet.model');
const User = require('../models/user.model');
const { sendEmail } = require('../services/email.service');
const { getBTCPrice } = require('../services/price.service');
const logger = require('../utils/logger');
const { generateWithdrawalId } = require('../utils/helpers');
const catchAsync = require('../utils/catchAsync');
const { AppError } = require('../utils/appError');
const { validateWithdrawal } = require('../utils/withdrawal.validation');
const BigNumber = require('bignumber.js');
const { v4: uuidv4 } = require('uuid');

// Get all withdrawals for a user
exports.getUserWithdrawals = catchAsync(async (req, res, next) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const status = req.query.status;

  const query = { user: req.user._id };
  if (status) query.status = status;

  const withdrawals = await Withdrawal.find(query)
    .sort({ createdAt: -1 })
    .skip((page - 1) * limit)
    .limit(limit);

  const total = await Withdrawal.countDocuments(query);
  const totalPages = Math.ceil(total / limit);

  res.status(200).json({
    status: 'success',
    data: {
      withdrawals,
      currentPage: page,
      total,
      totalPages
    }
  });
});

// Get a specific withdrawal
exports.getWithdrawal = catchAsync(async (req, res, next) => {
  const withdrawal = await Withdrawal.findOne({
    _id: req.params.id,
    user: req.user._id
  });

  if (!withdrawal) {
    return next(new AppError('Withdrawal not found', 404));
  }

  res.status(200).json({
    status: 'success',
    data: {
      withdrawal
    }
  });
});

// Create a new withdrawal
exports.createWithdrawal = catchAsync(async (req, res, next) => {
  const { amount, currency, method, destination, btcAmount } = req.body;

  // Validate withdrawal data
  const validationError = validateWithdrawal(req.body);
  if (validationError) {
    return next(new AppError(validationError, 400));
  }

  // Get user's wallet
  const wallet = await Wallet.findOne({ user: req.user._id });
  if (!wallet) {
    return next(new AppError('Wallet not found', 404));
  }

  // Calculate withdrawal amount in BTC
  const withdrawalAmount = new BigNumber(btcAmount || amount);
  const minAmount = new BigNumber('0.000000000000000001'); // 1 satoshi

  // Validate minimum amount
  if (withdrawalAmount.lt(minAmount)) {
    return next(new AppError('Minimum withdrawal amount is 0.000000000000000001 BTC (1 satoshi)', 400));
  }

  // Check if user has sufficient balance
  const currentBalance = new BigNumber(wallet.balance);
  if (currentBalance.lt(withdrawalAmount)) {
    return next(new AppError('Insufficient balance', 400));
  }

  // Calculate fees (0.5% of withdrawal amount)
  const fees = withdrawalAmount.times(0.005).toFixed(18);
  const netAmount = withdrawalAmount.minus(fees).toFixed(18);

  // Create withdrawal
  const withdrawal = await Withdrawal.create({
    user: req.user._id,
    amount: withdrawalAmount.toFixed(18),
    netAmount,
    fees,
    currency: 'BTC',
    method,
    destination,
    status: 'pending',
    originalAmount: amount,
    originalCurrency: currency
  });

  // Create transaction record
  const transaction = {
    type: 'withdrawal',
    amount: withdrawalAmount.toFixed(18),
    netAmount,
    status: 'pending',
    transactionId: uuidv4(),
    timestamp: new Date(),
    description: `Withdrawal request to ${method}`,
    currency: 'BTC',
    localAmount: withdrawalAmount.times(wallet.exchangeRate).toFixed(2),
    exchangeRate: wallet.exchangeRate,
    isClaimed: false,
    details: {
      withdrawalId: withdrawal.withdrawalId,
      method,
      destination,
      fees,
      originalAmount: amount,
      originalCurrency: currency
    }
  };

  // Update wallet with new transaction
  const updatedWallet = await Wallet.findOneAndUpdate(
    { user: req.user._id },
    {
      $push: { transactions: transaction },
      $set: {
        balance: currentBalance.minus(withdrawalAmount).toFixed(18),
        localBalance: currentBalance.minus(withdrawalAmount).times(wallet.exchangeRate).toFixed(2)
      }
    },
    { new: true, runValidators: true }
  );

  res.status(201).json({
    status: 'success',
    data: {
      withdrawal,
      wallet: updatedWallet
    }
  });
});

// Update withdrawal status
exports.updateWithdrawalStatus = catchAsync(async (req, res, next) => {
  const { status, rejectionReason } = req.body;

  if (!['completed', 'rejected'].includes(status)) {
    return next(new AppError('Invalid status', 400));
  }

  const withdrawal = await Withdrawal.findById(req.params.id);
  if (!withdrawal) {
    return next(new AppError('Withdrawal not found', 404));
  }

  if (withdrawal.status !== 'pending') {
    return next(new AppError('Withdrawal cannot be updated', 400));
  }

  // Update withdrawal status
  withdrawal.status = status;
  if (status === 'rejected') {
    withdrawal.rejectionReason = rejectionReason || 'Rejected by admin';
    
    // Refund amount to wallet
    const wallet = await Wallet.findOne({
      user: withdrawal.user,
      currency: withdrawal.currency
    });

    if (wallet) {
      wallet.balance += withdrawal.amount;
      await wallet.save();
    }
  }

  await withdrawal.save();

  res.status(200).json({
    status: 'success',
    data: {
      withdrawal
    }
  });
});

// Cancel a withdrawal request
exports.cancelWithdrawal = catchAsync(async (req, res, next) => {
  const withdrawal = await Withdrawal.findOne({
    _id: req.params.id,
    user: req.user._id,
    status: 'pending'
  });

  if (!withdrawal) {
    return next(new AppError('Withdrawal not found or cannot be cancelled', 404));
  }

  // Update withdrawal status
  withdrawal.status = 'rejected';
  withdrawal.rejectionReason = 'Cancelled by user';
  await withdrawal.save();

  // Refund amount to wallet
  const wallet = await Wallet.findOne({
    user: req.user._id,
    currency: withdrawal.currency
  });

  if (wallet) {
    wallet.balance += withdrawal.amount;
    await wallet.save();
  }

  res.status(200).json({
    status: 'success',
    data: {
      withdrawal
    }
  });
});

// Get withdrawal statistics
exports.getWithdrawalStats = async (req, res) => {
  try {
    const stats = await Withdrawal.aggregate([
      { $match: { user: req.user.id } },
      {
        $group: {
          _id: null,
          totalWithdrawals: { $sum: 1 },
          totalAmount: { $sum: { $toDouble: '$amount' } },
          pendingWithdrawals: {
            $sum: { $cond: [{ $eq: ['$status', 'pending'] }, 1, 0] }
          },
          pendingAmount: {
            $sum: {
              $cond: [
                { $eq: ['$status', 'pending'] },
                { $toDouble: '$amount' },
                0
              ]
            }
          }
        }
      }
    ]);
    
    res.json(stats[0] || {
      totalWithdrawals: 0,
      totalAmount: 0,
      pendingWithdrawals: 0,
      pendingAmount: 0
    });
  } catch (error) {
    logger.error('Error getting withdrawal stats:', error);
    res.status(500).json({ message: 'Error getting withdrawal statistics' });
  }
};

// Get withdrawal by ID
exports.getWithdrawalById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const withdrawal = await Withdrawal.findOne({ _id: id, user: userId });
    if (!withdrawal) {
      return res.status(404).json({ message: 'Withdrawal not found' });
    }

    res.status(200).json(withdrawal);
  } catch (error) {
    logger.error('Get withdrawal error:', error);
    res.status(500).json({ message: 'Error fetching withdrawal details' });
  }
};

// Admin: Get all withdrawals
exports.getAllWithdrawals = catchAsync(async (req, res, next) => {
  const withdrawals = await Withdrawal.find()
    .populate('user', 'username email')
    .sort({ createdAt: -1 });

  res.status(200).json({
    status: 'success',
    results: withdrawals.length,
    data: {
      withdrawals
    }
  });
});

// Admin: Process withdrawal
exports.processWithdrawal = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, transactionId, rejectionReason } = req.body;

    const withdrawal = await Withdrawal.findById(id);
    if (!withdrawal) {
      return res.status(404).json({ message: 'Withdrawal not found' });
    }

    if (withdrawal.status !== 'pending') {
      return res.status(400).json({ message: 'Can only process pending withdrawals' });
    }

    // Update withdrawal status
    withdrawal.status = status;
    if (status === 'completed') {
      withdrawal.transactionId = transactionId;
      withdrawal.processedAt = new Date();
    } else if (status === 'rejected') {
      withdrawal.rejectionReason = rejectionReason;
      withdrawal.processedAt = new Date();

      // Refund amount to wallet
      const wallet = await Wallet.findOne({ user: withdrawal.user });
      if (wallet) {
        wallet.balance += withdrawal.amount;
        await wallet.save();
      }
    }

    await withdrawal.save();

    // Send email notification
    const user = await User.findById(withdrawal.user);
    await sendEmail({
      to: user.email,
      subject: `Withdrawal ${status}`,
      text: `Your withdrawal request of ${withdrawal.amount} ${withdrawal.currency} has been ${status}.`
    });

    res.status(200).json({
      message: `Withdrawal ${status} successfully`,
      withdrawal
    });
  } catch (error) {
    logger.error('Process withdrawal error:', error);
    res.status(500).json({ message: 'Error processing withdrawal' });
  }
}; 