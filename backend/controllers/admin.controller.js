// Models & Services
const { Withdrawal } = require('../models/withdrawal.model');
const { Wallet } = require('../models/wallet.model');
const User = require('../models/user.model');
const { Transaction } = require('../models/transaction.model');
const Referral = require('../models/referral.model');
const emailService = require('../services/email.service');
const logger = require('../utils/logger');
const jwt = require('jsonwebtoken');
const { Parser } = require('json2csv');
const Admin = require('../models/admin.model');
const { getExchangeRate } = require('../utils/exchange');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid'); // File ke top pe add karo (agar already nahi hai to)
const AppConfig = require('../models/appConfig.model');

// Admin Config
const ADMIN_EMAIL = process.env.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;
const ADMIN_USERID = process.env.ADMIN_USERID;
const ADMIN_NAME = process.env.ADMIN_NAME;
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';

// --- Withdrawals ---
const getPendingWithdrawals = async (req, res) => {
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
    res.status(500).json({ success: false, message: 'Failed to get pending withdrawals' });
  }
};

const approveWithdrawal = async (req, res) => {
  try {
    const { withdrawalId, adminNote } = req.body;
    if (!withdrawalId) return res.status(400).json({ success: false, message: 'Withdrawal ID is required' });
    const withdrawal = await Withdrawal.findOne({ withdrawalId });
    if (!withdrawal) return res.status(404).json({ success: false, message: 'Withdrawal request not found' });
    if (withdrawal.status !== 'pending') return res.status(400).json({ success: false, message: `Withdrawal is already ${withdrawal.status}` });
    const session = await Withdrawal.startSession();
    session.startTransaction();
    try {
      withdrawal.status = 'completed';
      withdrawal.adminNote = adminNote || 'Withdrawal approved';
      withdrawal.processedAt = new Date();
      await withdrawal.save({ session });
      const transaction = await Transaction.findOne({ transactionId: withdrawalId });
      if (transaction) {
        transaction.status = 'completed';
        transaction.adminNote = adminNote;
        await transaction.save({ session });
      }
      const wallet = await Wallet.findOne({ user: withdrawal.user });
      if (wallet) {
        const walletTransaction = wallet.transactions.find(tx => tx.withdrawalId === withdrawalId);
        if (walletTransaction) {
          walletTransaction.status = 'completed';
          walletTransaction.adminNote = adminNote;
        }
        await wallet.save({ session });
      }
      try {
        const user = await User.findById(withdrawal.user);
        if (user) {
          await emailService.sendWithdrawalCompletion(
            user.email,
            withdrawal.amount,
            withdrawalId,
            {
              method: withdrawal.paymentMethod,
              destination: withdrawal.destinationAddress,
              fees: withdrawal.fees
            }
          );
        }
      } catch (emailError) {
        logger.error('Error sending withdrawal completion email:', emailError);
      }
      await session.commitTransaction();
      session.endSession();
      res.json({ success: true, message: 'Withdrawal request approved successfully', data: { withdrawalId, status: 'completed', processedAt: withdrawal.processedAt } });
    } catch (error) {
      await session.abortTransaction();
      session.endSession();
      throw error;
    }
  } catch (error) {
    logger.error('Error approving withdrawal:', error);
    res.status(500).json({ success: false, message: 'Failed to approve withdrawal request' });
  }
};

const rejectWithdrawal = async (req, res) => {
  try {
    const { withdrawalId, adminNote } = req.body;
    if (!withdrawalId) return res.status(400).json({ success: false, message: 'Withdrawal ID is required' });
    const withdrawal = await Withdrawal.findOne({ withdrawalId });
    if (!withdrawal) return res.status(404).json({ success: false, message: 'Withdrawal request not found' });
    if (withdrawal.status !== 'pending') return res.status(400).json({ success: false, message: `Withdrawal is already ${withdrawal.status}` });
    const session = await Withdrawal.startSession();
    session.startTransaction();
    try {
      withdrawal.status = 'rejected';
      withdrawal.adminNote = adminNote || 'Withdrawal rejected';
      withdrawal.processedAt = new Date();
      await withdrawal.save({ session });
      const transaction = await Transaction.findOne({ transactionId: withdrawalId });
      if (transaction) {
        transaction.status = 'rejected';
        transaction.adminNote = adminNote;
        await transaction.save({ session });
      }
      const wallet = await Wallet.findOne({ user: withdrawal.user });
      if (wallet) {
        const refundAmount = parseFloat(withdrawal.amount) + parseFloat(withdrawal.fees);
        wallet.balance = (parseFloat(wallet.balance) + refundAmount).toFixed(18);
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
        await User.findByIdAndUpdate(withdrawal.user, { 'wallet.balance': wallet.balance }, { session });
      }
      try {
        const user = await User.findById(withdrawal.user);
        if (user) {
          await emailService.sendRefundNotification(user.email, withdrawal.amount, withdrawalId, adminNote);
        }
      } catch (emailError) {
        logger.error('Error sending refund notification email:', emailError);
      }
      await session.commitTransaction();
      session.endSession();
      res.json({ success: true, message: 'Withdrawal request rejected successfully', data: { withdrawalId, status: 'rejected', processedAt: withdrawal.processedAt, refundAmount: withdrawal.amount } });
    } catch (error) {
      await session.abortTransaction();
      session.endSession();
      throw error;
    }
  } catch (error) {
    logger.error('Error rejecting withdrawal:', error);
    res.status(500).json({ success: false, message: 'Failed to reject withdrawal request' });
  }
};

const getWithdrawalStats = async (req, res) => {
  try {
    const { startDate, endDate } = req.query;
    const matchStage = {};
    if (startDate && endDate) {
      matchStage.createdAt = { $gte: new Date(startDate), $lte: new Date(endDate) };
    }
    // Withdrawal stats aggregation
    const stats = await Withdrawal.aggregate([
      { $match: matchStage },
      { $group: { _id: '$status', count: { $sum: 1 }, totalAmount: { $sum: { $toDouble: '$btcAmount' } }, averageAmount: { $avg: { $toDouble: '$btcAmount' } } } },
      { $project: { status: '$_id', count: 1, totalAmount: { $round: ['$totalAmount', 8] }, averageAmount: { $round: ['$averageAmount', 8] }, _id: 0 } }
    ]);
    // Map approvedWithdrawals to completedWithdrawals
    const statsMap = {};
    stats.forEach(s => {
      if (s.status === 'completed') {
        statsMap['completedWithdrawals'] = s.count;
      } else if (s.status === 'pending') {
        statsMap['pendingWithdrawals'] = s.count;
      } else if (s.status === 'rejected') {
        statsMap['rejectedWithdrawals'] = s.count;
      }
    });
    const totalStats = await Withdrawal.aggregate([
      { $match: matchStage },
      { $group: { _id: null, totalWithdrawals: { $sum: 1 }, totalAmount: { $sum: { $toDouble: '$btcAmount' } }, averageAmount: { $avg: { $toDouble: '$btcAmount' } } } },
      { $project: { _id: 0, totalWithdrawals: 1, totalAmount: { $round: ['$totalAmount', 8] }, averageAmount: { $round: ['$averageAmount', 8] } } }
    ]);
    res.json({ success: true, data: { stats, total: totalStats[0] || { totalWithdrawals: 0, totalAmount: 0, averageAmount: 0 }, withdrawals: totalStats[0] ? Number(totalStats[0].totalWithdrawals) : 0, ...statsMap } });
  } catch (error) {
    logger.error('Error getting withdrawal stats:', error);
    res.status(500).json({ success: false, message: 'Failed to get withdrawal statistics' });
  }
};

// Get latest withdrawals (for dashboard)
const getLatestWithdrawals = async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 5;
    const withdrawals = await Withdrawal.find({})
      .sort({ createdAt: -1 })
      .limit(limit)
      .populate('userId', 'username email');
    res.json({ success: true, data: withdrawals });
  } catch (error) {
    logger.error('Error getting latest withdrawals:', error);
    res.status(500).json({ success: false, message: 'Failed to get latest withdrawals' });
  }
};

// --- Admin Auth ---
const adminLogin = async (req, res) => {
  const { email, password } = req.body;
  if (email === ADMIN_EMAIL && password === ADMIN_PASSWORD) {
    const token = jwt.sign(
      { userId: ADMIN_USERID, email, role: 'admin' },
      JWT_SECRET,
      { expiresIn: '12h' }
    );
    return res.json({ token, admin: { email, name: ADMIN_NAME } });
  }
  return res.status(401).json({ error: 'Invalid credentials' });
};

// --- User Management ---
const getUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const skip = (page - 1) * limit;
    const [users, total] = await Promise.all([
      User.find({}, '-password')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      User.countDocuments()
    ]);
    res.json({
      success: true,
      data: {
        users,
        pagination: {
          total,
          page,
          limit,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    logger.error('Error getting users:', error);
    res.status(500).json({ success: false, message: 'Failed to get users' });
  }
};

const getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id, '-password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, data: user });
  } catch (error) {
    logger.error('Error getting user by id:', error);
    res.status(500).json({ success: false, message: 'Failed to get user' });
  }
};

const blockUser = async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, { status: 'blocked' }, { new: true });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, message: 'User blocked successfully', data: user });
  } catch (error) {
    logger.error('Error blocking user:', error);
    res.status(500).json({ success: false, message: 'Failed to block user' });
  }
};

const unblockUser = async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, { status: 'active' }, { new: true });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.json({ success: true, message: 'User unblocked successfully', data: user });
  } catch (error) {
    logger.error('Error unblocking user:', error);
    res.status(500).json({ success: false, message: 'Failed to unblock user' });
  }
};

const exportUsers = async (req, res) => {
  try {
    const users = await User.find({}, '-password');
    const fields = ['_id', 'username', 'email', 'status', 'createdAt', 'referralCode'];
    const parser = new Parser({ fields });
    const csv = parser.parse(users);
    res.header('Content-Type', 'text/csv');
    res.attachment('users.csv');
    return res.send(csv);
  } catch (error) {
    logger.error('Error exporting users:', error);
    res.status(500).json({ success: false, message: 'Failed to export users' });
  }
};

// --- Wallet Management ---
const getUserWallet = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ userId: req.params.id });
    if (!wallet) return res.status(404).json({ success: false, message: 'Wallet not found' });
    res.json({ success: true, data: wallet });
  } catch (error) {
    logger.error('Error getting user wallet:', error);
    res.status(500).json({ success: false, message: 'Failed to get user wallet' });
  }
};

const adjustWallet = async (req, res) => {
  try {
    const { amount, type, note } = req.body; // type: 'credit' or 'debit'
    const userId = req.params.id;
    console.log('AdjustWallet API called:', { userId, amount, type, note });

    if (!amount || !type) {
      console.log('AdjustWallet error: Amount or type missing', { userId, amount, type });
      return res.status(400).json({ success: false, message: 'Amount and type are required' });
    }

    // 1. User exist check (userId ya _id dono se)
    let user;
    try {
      const mongoose = require('mongoose');
      if (mongoose.Types.ObjectId.isValid(userId)) {
        user = await User.findOne({ $or: [{ userId }, { _id: userId }] });
      } else {
        user = await User.findOne({ userId });
      }
      console.log('Debug - Finding user with query:', mongoose.Types.ObjectId.isValid(userId) ? { $or: [{ userId }, { _id: userId }] } : { userId });
      console.log('Debug - User find result:', user ? 'User found' : 'No user found');
    } catch (e) {
      console.log('Debug - User find error:', e);
    }
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // 2. Wallet exist check, do NOT create if not found
    let wallet = await Wallet.findOne({ $or: [{ userId }, { userId: user._id }] });
    if (!wallet) {
      console.log('AdjustWallet error: Wallet not found', { userId });
      return res.status(404).json({ success: false, message: 'Wallet not found' });
    }

    // 3. Amount add/subtract
    let newBalance = parseFloat(wallet.balance);
    if (type === 'credit') newBalance += parseFloat(amount);
    else if (type === 'debit') newBalance -= parseFloat(amount);
    else {
      console.log('AdjustWallet error: Invalid type', { userId, type });
      return res.status(400).json({ success: false, message: 'Invalid type' });
    }
    wallet.balance = newBalance.toFixed(18);

    // 4. Transaction add
    wallet.transactions.push({
      transactionId: uuidv4(), // unique id
      type: type === 'credit' ? 'deposit' : 'withdrawal', // allowed enum value
      amount: parseFloat(amount).toFixed(18), // 18 decimal places
      status: 'completed',
      timestamp: new Date(),
      details: { note: note || '' }
    });

    await wallet.save();

    // 5. User embedded wallet bhi update karo (agar hai)
    if (user.wallet) {
      user.wallet.balance = wallet.balance;
      user.wallet.lastUpdated = new Date();
      await user.save();
    }

    console.log('AdjustWallet success:', { userId, newBalance: wallet.balance });
    res.json({ success: true, message: 'Wallet adjusted successfully', data: wallet });
  } catch (error) {
    console.log('AdjustWallet exception:', error);
    logger.error('Error adjusting wallet:', error);
    res.status(500).json({ success: false, message: 'Failed to adjust wallet' });
  }
};

const getWalletTransactions = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ userId: req.params.id });
    if (!wallet) return res.status(404).json({ success: false, message: 'Wallet not found' });
    res.json({ success: true, data: wallet.transactions });
  } catch (error) {
    logger.error('Error getting wallet transactions:', error);
    res.status(500).json({ success: false, message: 'Failed to get wallet transactions' });
  }
};

const exportWallets = async (req, res) => {
  try {
    const wallets = await Wallet.find().populate('userId', 'username email');
    const data = wallets.map(w => ({
      userId: w.userId ? w.userId._id : '',
      username: w.userId ? w.userId.username : '',
      email: w.userId ? w.userId.email : '',
      balance: w.balance,
      createdAt: w.createdAt
    }));
    const fields = ['userId', 'username', 'email', 'balance', 'createdAt'];
    const parser = new Parser({ fields });
    const csv = parser.parse(data);
    res.header('Content-Type', 'text/csv');
    res.attachment('wallets.csv');
    return res.send(csv);
  } catch (error) {
    logger.error('Error exporting wallets:', error);
    res.status(500).json({ success: false, message: 'Failed to export wallets' });
  }
};

// Get all wallets
const getAllWallets = async (req, res) => {
  try {
    const wallets = await Wallet.find({});
    res.json({ success: true, data: { wallets } });
  } catch (error) {
    logger.error('Error getting all wallets:', error);
    res.status(500).json({ success: false, message: 'Failed to get wallets' });
  }
};

// Get all wallet transactions (aggregate from all wallets, latest first)
const getAllWalletTransactions = async (req, res) => {
  try {
    const wallets = await Wallet.find({});
    let allTransactions = [];
    wallets.forEach(wallet => {
      if (Array.isArray(wallet.transactions)) {
        allTransactions.push(
          ...wallet.transactions.map(tx => ({
            ...(tx.toObject?.() || tx),
            userEmail: wallet.userEmail || (wallet.user && wallet.user.email) || '',
            walletId: wallet._id
          }))
        );
      }
    });
    // Sort by timestamp (descending)
    allTransactions.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
    res.json({ success: true, data: { transactions: allTransactions } });
  } catch (error) {
    logger.error('Error getting all wallet transactions:', error);
    res.status(500).json({ success: false, message: 'Failed to get wallet transactions' });
  }
};

// User stats for admin dashboard
const getUserCount = async (req, res) => {
  try {
    const count = await User.countDocuments();
    res.json({ success: true, data: { count } });
  } catch (error) {
    logger.error('Error getting user count:', error);
    res.status(500).json({ success: false, message: 'Failed to get user count' });
  }
};

const getActiveUserCount = async (req, res) => {
  try {
    const count = await User.countDocuments({ status: 'active' });
    res.json({ success: true, data: { count } });
  } catch (error) {
    logger.error('Error getting active user count:', error);
    res.status(500).json({ success: false, message: 'Failed to get active user count' });
  }
};

const getUserActiveHours = async (req, res) => {
  try {
    // Example: Count users by lastLogin hour (0-23)
    const users = await User.find({ lastLogin: { $ne: null } }, 'lastLogin');
    const hours = Array(24).fill(0);
    users.forEach(u => {
      const h = new Date(u.lastLogin).getHours();
      hours[h]++;
    });
    res.json({ success: true, data: hours });
  } catch (error) {
    logger.error('Error getting user active hours:', error);
    res.status(500).json({ success: false, message: 'Failed to get user active hours' });
  }
};

// Market rates for wallet conversion
const getWalletMarketRates = async (req, res) => {
  try {
    // BTC to USD
    const btcUsd = await getExchangeRate('BTC', 'USD');
    // BTC to INR (agar support ho)
    let btcInr = null;
    try {
      // Pehle USD rate lo, fir INR rate (agar implemented ho)
      const usdInr = await getExchangeRate('USD', 'INR');
      btcInr = btcUsd * usdInr;
    } catch (e) {
      btcInr = null;
    }
    res.json({
      success: true,
      data: {
        BTC: 1,
        USD: btcUsd,
        INR: btcInr
      }
    });
  } catch (error) {
    logger.error('Error getting wallet market rates:', error);
    res.status(500).json({ success: false, message: 'Failed to get market rates' });
  }
};

// Referral Analytics
const getReferralStats = async (req, res) => {
  try {
    // Get real referral statistics
    const totalReferrals = await Referral.countDocuments();
    const activeReferrals = await Referral.countDocuments({ status: 'active' });

    // Calculate total earnings from all referrals
    const totalEarningsResult = await Referral.aggregate([
      { $group: { _id: null, totalEarnings: { $sum: '$earnings' } } }
    ]);
    const totalEarnings = totalEarningsResult.length > 0 ? Number(totalEarningsResult[0].totalEarnings) : 0.0;

    // Calculate pending rewards
    const pendingRewardsResult = await Referral.aggregate([
      { $group: { _id: null, pendingRewards: { $sum: '$pendingEarnings' } } }
    ]);
    const pendingRewards = pendingRewardsResult.length > 0 ? Number(pendingRewardsResult[0].pendingRewards) : 0.0;

    // Get unique referrers count
    // const uniqueReferrers = await Referral.distinct('referrerId');
    // const activeReferrers = uniqueReferrers.length;
    const uniqueReferrersAgg = await Referral.aggregate([
      { $group: { _id: "$referrerId" } },
      { $count: "count" }
    ]);
    const activeReferrers = uniqueReferrersAgg.length > 0 ? uniqueReferrersAgg[0].count : 0;

    // Calculate conversion rate (referrals with earnings / total referrals)
    const referralsWithEarnings = await Referral.countDocuments({ earnings: { $gt: 0 } });
    const conversionRate = totalReferrals > 0 ? (referralsWithEarnings / totalReferrals) * 100 : 0;

    // Calculate weekly and monthly growth
    const oneWeekAgo = new Date();
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);
    const oneMonthAgo = new Date();
    oneMonthAgo.setMonth(oneMonthAgo.getMonth() - 1);

    const weeklyReferrals = await Referral.countDocuments({ createdAt: { $gte: oneWeekAgo } });
    const monthlyReferrals = await Referral.countDocuments({ createdAt: { $gte: oneMonthAgo } });

    const weeklyGrowth = totalReferrals > 0 ? (weeklyReferrals / totalReferrals) * 100 : 0;
    const monthlyGrowth = totalReferrals > 0 ? (monthlyReferrals / totalReferrals) * 100 : 0;

    const referralStats = {
      totalReferrals,
      totalRewards: totalEarnings.toFixed(18),
      activeReferrers,
      conversionRate: parseFloat(conversionRate.toFixed(1)),
      weeklyGrowth: parseFloat(weeklyGrowth.toFixed(1)),
      monthlyGrowth: parseFloat(monthlyGrowth.toFixed(1)),
      totalEarnings: totalEarnings.toFixed(18),
      pendingRewards: pendingRewards.toFixed(18),
      referralGrowth: parseFloat(weeklyGrowth.toFixed(1))
    };

    res.json({ success: true, data: referralStats });
  } catch (error) {
    console.error('Error getting referral stats:', error);
    logger.error('Error getting referral stats:', error);
    // Fallback: return zeroed stats
    res.json({
      success: true, data: {
        totalReferrals: 0,
        totalRewards: '0.000000000000000000',
        activeReferrers: 0,
        conversionRate: 0,
        weeklyGrowth: 0,
        monthlyGrowth: 0,
        totalEarnings: '0.000000000000000000',
        pendingRewards: '0.000000000000000000',
        referralGrowth: 0
      }
    });
  }
};

const getReferrals = async (req, res) => {
  try {
    // Get pagination parameters
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    // Get referrals with referrer details
    const referrals = await Referral.aggregate([
      {
        $lookup: {
          from: 'users',
          localField: 'referrerId',
          foreignField: 'userId',
          as: 'referrer'
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: 'referredId',
          foreignField: 'userId',
          as: 'referred'
        }
      },
      { $unwind: { path: '$referrer', preserveNullAndEmptyArrays: true } },
      { $unwind: { path: '$referred', preserveNullAndEmptyArrays: true } },
      {
        $group: {
          _id: '$referrerId',
          referrer: { $first: '$referrer' },
          totalReferrals: { $sum: 1 },
          totalEarnings: { $sum: '$earnings' },
          pendingEarnings: { $sum: '$pendingEarnings' },
          lastReferral: { $max: '$createdAt' },
          status: { $first: '$status' }
        }
      },
      {
        $project: {
          id: '$_id',
          name: '$referrer.username',
          email: '$referrer.email',
          referrals: '$totalReferrals',
          earnings: { $toString: '$totalEarnings' },
          pendingEarnings: { $toString: '$pendingEarnings' },
          status: '$status',
          lastReferral: '$lastReferral'
        }
      },
      { $sort: { totalEarnings: -1 } },
      { $skip: skip },
      { $limit: limit }
    ]);

    // Get total count for pagination
    // const totalReferrers = await Referral.distinct('referrerId');
    // const totalCount = totalReferrers.length;
    const totalReferrersAgg = await Referral.aggregate([
      { $group: { _id: "$referrerId" } },
      { $count: "count" }
    ]);
    const totalCount = totalReferrersAgg.length > 0 ? totalReferrersAgg[0].count : 0;

    res.json({
      success: true,
      data: referrals,
      pagination: {
        total: totalCount,
        page,
        limit,
        pages: Math.ceil(totalCount / limit)
      }
    });
  } catch (error) {
    logger.error('Error getting referrals:', error);
    // Fallback: return empty data
    res.json({
      success: true,
      data: [],
      pagination: {
        total: 0,
        page: 1,
        limit: 10,
        pages: 0
      }
    });
  }
};

// Dashboard Analytics
const getDashboardAnalytics = async (req, res) => {
  try {
    // Get real data from database
    const totalUsers = await User.countDocuments();
    const activeUsers = await User.countDocuments({ status: 'active' });

    // Calculate growth percentages (mock for now)
    const userGrowth = 12.5;
    const activeUserGrowth = 8.3;
    const earningsGrowth = 18.7;
    const miningGrowth = 22.3;

    // Mock revenue and mining data
    const revenueData = [
      { x: 0, y: 3 }, { x: 2.6, y: 2 }, { x: 4.9, y: 5 },
      { x: 6.8, y: 3.1 }, { x: 8, y: 4 }, { x: 9.5, y: 3 }, { x: 11, y: 4 }
    ];

    const miningData = [
      { x: 0, y: 1.5 }, { x: 2, y: 2.1 }, { x: 4, y: 1.8 },
      { x: 6, y: 3.2 }, { x: 8, y: 2.9 }, { x: 10, y: 4.1 },
      { x: 12, y: 3.8 }, { x: 14, y: 4.5 }, { x: 16, y: 3.9 },
      { x: 18, y: 4.8 }, { x: 20, y: 4.2 }, { x: 22, y: 3.5 }, { x: 23, y: 2.8 }
    ];

    const dashboardAnalytics = {
      totalUsers,
      activeUsers,
      totalEarnings: 0.045,
      dailyMining: 0.0023,
      userGrowth,
      activeUserGrowth,
      earningsGrowth,
      miningGrowth,
      systemHealth: 98.5,
      revenueData,
      miningData
    };

    res.json({ success: true, data: dashboardAnalytics });
  } catch (error) {
    logger.error('Error getting dashboard analytics:', error);
    res.status(500).json({ success: false, message: 'Failed to get dashboard analytics' });
  }
};

// Get referral settings
const getReferralSettings = async (req, res) => {
  try {
    let config = await AppConfig.findOne();
    if (!config) {
      config = await AppConfig.create({});
    }
    res.json({
      success: true, data: {
        referralDailyPercent: config.referralDailyPercent,
        referralEarningDays: config.referralEarningDays
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch referral settings' });
  }
};

// Update referral settings
const updateReferralSettings = async (req, res) => {
  try {
    const { referralDailyPercent, referralEarningDays } = req.body;
    let config = await AppConfig.findOne();
    if (!config) {
      config = await AppConfig.create({});
    }
    if (referralDailyPercent !== undefined) config.referralDailyPercent = referralDailyPercent;
    if (referralEarningDays !== undefined) config.referralEarningDays = referralEarningDays;
    config.updatedAt = new Date();
    await config.save();
    res.json({
      success: true, data: {
        referralDailyPercent: config.referralDailyPercent,
        referralEarningDays: config.referralEarningDays
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to update referral settings' });
  }
};

// User hourly activity (platform-wide)
const getUserHourlyActivity = async (req, res) => {
  try {
    // पिछले 7 दिन के लिए (या जितना चाहें)
    const since = new Date();
    since.setDate(since.getDate() - 7);

    // सिर्फ completed transactions गिनें (optional)
    const transactions = await Transaction.find({
      timestamp: { $gte: since },
      status: 'completed'
    });

    console.log('Total transactions found:', transactions.length);

    const hourlyActivity = Array(24).fill(0);
    transactions.forEach((tx, idx) => {
      if (!tx.timestamp) {
        console.log(`TX missing timestamp:`, tx, `idx:`, idx);
        return;
      }
      const date = new Date(tx.timestamp);
      if (isNaN(date.getTime())) {
        console.log(`TX invalid timestamp:`, tx.timestamp, `idx:`, idx);
        return;
      }
      const hour = date.getHours();
      hourlyActivity[hour]++;
      // Debug
      console.log(`TX [#${idx}]: type=${tx.type}, ts=${tx.timestamp}, hour=${hour}`);
    });

    console.log('Hourly activity array:', hourlyActivity);
    res.json({ success: true, data: hourlyActivity });
  } catch (error) {
    logger.error('Error getting user hourly activity:', error);
    res.status(500).json({ success: false, message: 'Failed to get user hourly activity' });
  }
};

const updateTransactionStatus = async (req, res) => {
  try {
    const userId = req.params.id;
    const txId = req.params.txId;
    const { status } = req.body;

    // Transaction status allowed values
    const allowed = ['pending', 'completed', 'failed', 'cancelled', 'rejected'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    // Find wallet by userId
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) return res.status(404).json({ success: false, message: 'Wallet not found' });

    // Debug: print all transactionIds
    console.log('Wallet.transactions:', wallet.transactions.map(t => ({
      transactionId: t.transactionId,
      _id: t._id ? t._id.toString() : undefined,
      status: t.status,
      type: t.type,
      amount: t.amount
    })));
    console.log('Looking for txId:', txId);

    // Find transaction in wallet.transactions array (loose equality)
    const tx = wallet.transactions.find(
      t => t.transactionId == txId || (t._id && t._id.toString() == txId)
    );
    if (!tx) {
      console.error('Transaction not found! txId:', txId, 'All:', wallet.transactions.map(t => t.transactionId));
      return res.status(404).json({ success: false, message: 'Transaction not found' });
    }

    // Logic for amount update
    const addTypes = ['deposit', 'reward', 'mining', 'earning', 'referral', 'claim', 'tap', 'game'];
    if (addTypes.includes(tx.type)) {
      if (status === 'pending' || status === 'rejected') {
        // Amount negative, 18 decimals
        let absAmount = tx.amount.replace(/^-|\+/, '');
        tx.amount = formatBTC('-' + absAmount);
      } else if (status === 'completed') {
        // Amount positive, 18 decimals
        let absAmount = tx.amount.replace(/^-|\+/, '');
        tx.amount = formatBTC(absAmount);
      }
      // Debug
      console.log(`Updated amount for add-type tx:`, tx.amount, 'status:', status);
      console.log('Final formatted amount:', tx.amount, 'length:', tx.amount.length);
    } else if (tx.type === 'withdrawal') {
      // Withdrawal: only status update, amount untouched
      console.log('Withdrawal tx: only status updated');
    } else {
      // Other types: only status update
      console.log('Other tx type:', tx.type, 'only status updated');
    }

    tx.status = status;
    await wallet.save();

    res.json({ success: true, message: 'Transaction status updated', status, amount: tx.amount });
  } catch (error) {
    console.error('Update Transaction Status Error:', error);
    res.status(500).json({ success: false, message: 'Failed to update status', error: error.message });
  }
};

// Helper function to format BTC with exactly 18 decimal places (handles minus/plus, strict)
function formatBTC(val) {
  let num = val.toString().replace(/^\+/, '').trim();
  let negative = false;
  if (num.startsWith('-')) {
    negative = true;
    num = num.slice(1);
  }
  // Remove all non-digit except dot
  num = num.replace(/[^0-9.]/g, '');
  let [intPart, decPart = ''] = num.split('.');
  intPart = intPart || '0';
  decPart = (decPart + '000000000000000000').slice(0, 18);
  let formatted = intPart + '.' + decPart;
  if (negative) formatted = '-' + formatted;
  return formatted;
}

module.exports = {
  getPendingWithdrawals,
  approveWithdrawal,
  rejectWithdrawal,
  getWithdrawalStats,
  adminLogin,
  getUsers,
  getUserById,
  blockUser,
  unblockUser,
  exportUsers,
  getUserWallet,
  adjustWallet,
  getWalletTransactions,
  exportWallets,
  getLatestWithdrawals,
  getUserCount,
  getActiveUserCount,
  getUserActiveHours,
  getAllWallets,
  getAllWalletTransactions,
  getWalletMarketRates,
  getReferralStats,
  getReferrals,
  getDashboardAnalytics,
  getReferralSettings,
  updateReferralSettings,
  getUserHourlyActivity,
  updateTransactionStatus
};

console.log('admin.controller.js loaded', Object.keys(module.exports)); 