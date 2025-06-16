const Withdrawal = require('../models/withdrawal.model');
const Wallet = require('../models/wallet.model');
const User = require('../models/user.model');
const Transaction = require('../models/transaction.model');
const emailService = require('../services/email.service');
const logger = require('../utils/logger');

// Get all pending withdrawal requests with pagination
exports.getPendingWithdrawals = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const [pendingWithdrawals, total] = await Promise.all([
      Withdrawal.find({ status: 'pending' })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('userId', 'username email'),
      Withdrawal.countDocuments({ status: 'pending' })
    ]);

    res.json({
      success: true,
      data: {
        withdrawals: pendingWithdrawals,
        pagination: {
          total,
          page,
          limit,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    logger.error('Error getting pending withdrawals:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get pending withdrawals'
    });
  }
};

// Approve withdrawal request
exports.approveWithdrawal = async (req, res) => {
  try {
    const { withdrawalId, adminNote } = req.body;

    if (!withdrawalId) {
      return res.status(400).json({
        success: false,
        message: 'Withdrawal ID is required'
      });
    }

    // Find withdrawal request
    const withdrawal = await Withdrawal.findOne({ withdrawalId });
    if (!withdrawal) {
      return res.status(404).json({
        success: false,
        message: 'Withdrawal request not found'
      });
    }

    if (withdrawal.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Withdrawal is already ${withdrawal.status}`
      });
    }

    // Start a session for transaction
    const session = await Withdrawal.startSession();
    session.startTransaction();

    try {
      // Update withdrawal status
      withdrawal.status = 'completed';
      withdrawal.adminNote = adminNote || 'Withdrawal approved';
      withdrawal.processedAt = new Date();
      await withdrawal.save({ session });

      // Update transaction status
      const transaction = await Transaction.findOne({ transactionId: withdrawalId });
      if (transaction) {
        transaction.status = 'completed';
        transaction.adminNote = adminNote;
        await transaction.save({ session });
      }

      // Get user's wallet
      const wallet = await Wallet.findOne({ userId: withdrawal.userId });
      if (wallet) {
        // Update existing transaction in wallet
        const walletTransaction = wallet.transactions.find(tx => tx.withdrawalId === withdrawalId);
        if (walletTransaction) {
          walletTransaction.status = 'completed';
          walletTransaction.adminNote = adminNote;
        }
        await wallet.save({ session });
      }

      // Send email notification
      try {
        const user = await User.findById(withdrawal.userId);
        if (user) {
          await emailService.sendWithdrawalCompletion(
            user.email,
            withdrawal.amount,
            withdrawalId,
            {
              method: withdrawal.paymentMethod,
              destination: withdrawal.destination,
              fees: withdrawal.feeAmount
            }
          );
        }
      } catch (emailError) {
        logger.error('Error sending withdrawal completion email:', emailError);
      }

      await session.commitTransaction();
      session.endSession();

      res.json({
        success: true,
        message: 'Withdrawal request approved successfully',
        data: {
          withdrawalId,
          status: 'completed',
          processedAt: withdrawal.processedAt
        }
      });
    } catch (error) {
      await session.abortTransaction();
      session.endSession();
      throw error;
    }
  } catch (error) {
    logger.error('Error approving withdrawal:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to approve withdrawal request'
    });
  }
};

// Reject withdrawal request
exports.rejectWithdrawal = async (req, res) => {
  try {
    const { withdrawalId, adminNote } = req.body;

    if (!withdrawalId) {
      return res.status(400).json({
        success: false,
        message: 'Withdrawal ID is required'
      });
    }

    // Find withdrawal request
    const withdrawal = await Withdrawal.findOne({ withdrawalId });
    if (!withdrawal) {
      return res.status(404).json({
        success: false,
        message: 'Withdrawal request not found'
      });
    }

    if (withdrawal.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Withdrawal is already ${withdrawal.status}`
      });
    }

    // Start a session for transaction
    const session = await Withdrawal.startSession();
    session.startTransaction();

    try {
      // Update withdrawal status
      withdrawal.status = 'rejected';
      withdrawal.adminNote = adminNote || 'Withdrawal rejected';
      withdrawal.processedAt = new Date();
      await withdrawal.save({ session });

      // Update transaction status
      const transaction = await Transaction.findOne({ transactionId: withdrawalId });
      if (transaction) {
        transaction.status = 'rejected';
        transaction.adminNote = adminNote;
        await transaction.save({ session });
      }

      // Get user's wallet
      const wallet = await Wallet.findOne({ userId: withdrawal.userId });
      if (wallet) {
        // Refund the amount
        const refundAmount = parseFloat(withdrawal.btcAmount) + parseFloat(withdrawal.feeAmount);
        wallet.balance = (parseFloat(wallet.balance) + refundAmount).toFixed(18);
        
        // Add refund transaction
        wallet.transactions.push({
          type: 'Refund',
          amount: refundAmount,
          status: 'completed',
          withdrawalId: withdrawalId,
          timestamp: new Date(),
          details: {
            method: withdrawal.paymentMethod,
            reason: 'Withdrawal rejected',
            adminNote: adminNote
          }
        });
        await wallet.save({ session });

        // Update user's wallet balance
        await User.findByIdAndUpdate(
          withdrawal.userId,
          { 'wallet.balance': wallet.balance },
          { session }
        );
      }

      // Send email notification
      try {
        const user = await User.findById(withdrawal.userId);
        if (user) {
          await emailService.sendRefundNotification(
            user.email,
            withdrawal.amount,
            withdrawalId,
            adminNote
          );
        }
      } catch (emailError) {
        logger.error('Error sending refund notification email:', emailError);
      }

      await session.commitTransaction();
      session.endSession();

      res.json({
        success: true,
        message: 'Withdrawal request rejected successfully',
        data: {
          withdrawalId,
          status: 'rejected',
          processedAt: withdrawal.processedAt,
          refundAmount: withdrawal.btcAmount
        }
      });
    } catch (error) {
      await session.abortTransaction();
      session.endSession();
      throw error;
    }
  } catch (error) {
    logger.error('Error rejecting withdrawal:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to reject withdrawal request'
    });
  }
};

// Get withdrawal statistics with date range
exports.getWithdrawalStats = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const matchStage = {};

    if (startDate && endDate) {
      matchStage.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    const stats = await Withdrawal.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: '$status',
          count: { $sum: 1 },
          totalAmount: { $sum: { $toDouble: '$btcAmount' } },
          averageAmount: { $avg: { $toDouble: '$btcAmount' } }
        }
      },
      {
        $project: {
          status: '$_id',
          count: 1,
          totalAmount: { $round: ['$totalAmount', 8] },
          averageAmount: { $round: ['$averageAmount', 8] },
          _id: 0
        }
      }
    ]);

    // Get total stats
    const totalStats = await Withdrawal.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: null,
          totalWithdrawals: { $sum: 1 },
          totalAmount: { $sum: { $toDouble: '$btcAmount' } },
          averageAmount: { $avg: { $toDouble: '$btcAmount' } }
        }
      },
      {
        $project: {
          _id: 0,
          totalWithdrawals: 1,
          totalAmount: { $round: ['$totalAmount', 8] },
          averageAmount: { $round: ['$averageAmount', 8] }
        }
      }
    ]);

    res.json({
      success: true,
      data: {
        stats,
        total: totalStats[0] || {
          totalWithdrawals: 0,
          totalAmount: 0,
          averageAmount: 0
        }
      }
    });
  } catch (error) {
    logger.error('Error getting withdrawal stats:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get withdrawal statistics'
    });
  }
}; 