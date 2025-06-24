const Referral = require('../models/referral.model');
const User = require('../models/user.model');
const Wallet = require('../models/wallet.model');
const logger = require('../utils/logger');

exports.validateReferralCode = async (req, res) => {
  try {
    const { code } = req.body;
    if (!code) {
      return res.status(400).json({
        success: false,
        message: 'Referral code is required'
      });
    }
    const user = await User.findOne({ referralCode: code });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'Invalid referral code'
      });
    }
    res.json({
      success: true,
      message: 'Valid referral code',
      data: {
        referrerId: user.userId,
        referrerName: user.userName
      }
    });
  } catch (error) {
    logger.error('Error validating referral code:', error);
    res.status(500).json({
      success: false,
      message: 'Error validating referral code'
    });
  }
};

exports.getReferrals = async (req, res) => {
  try {
    const referrals = await Referral.find({ referrerId: req.user.userId });
    const totalEarnings = referrals.reduce((sum, ref) => sum + (ref.earnings || 0), 0);
    const totalEarningsStr = Number(totalEarnings).toFixed(18);
    const user = await User.findOne({ userId: req.user.userId });
    // Find the most recent lastClaimDate among all referrals
    let lastClaimDate = null;
    referrals.forEach(ref => {
      if (ref.lastClaimDate && (!lastClaimDate || ref.lastClaimDate > lastClaimDate)) {
        lastClaimDate = ref.lastClaimDate;
      }
    });
    res.status(200).json({
      success: true,
      data: {
        referralCode: user.referralCode,
        totalEarnings: totalEarningsStr,
        totalReferrals: referrals.length,
        statistics: {
          totalEarnings: totalEarningsStr,
          lastClaimDate,
        },
        referrals: referrals.map(ref => ({
          id: ref.referredId,
          username: ref.referredUserDetails.username,
          email: ref.referredUserDetails.email,
          joinedAt: ref.referredUserDetails.joinedAt,
          earnings: ref.earnings != null ? Number(ref.earnings).toFixed(18) : '0.000000000000000000',
          pendingEarnings: ref.pendingEarnings != null ? Number(ref.pendingEarnings).toFixed(18) : '0.000000000000000000'
        }))
      }
    });
  } catch (error) {
    logger.error('Error getting referrals:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving referrals'
    });
  }
};

exports.getReferralEarnings = async (req, res) => {
  try {
    const referrals = await Referral.find({ referrerId: req.user.userId });
    const totalEarnings = referrals.reduce((sum, ref) => sum + (ref.earnings || 0), 0);

    // Fetch wallet balances for all referred users
    const referredIds = referrals.map(ref => ref.referredId);
    const wallets = await Wallet.find({ userId: { $in: referredIds } });
    const walletMap = {};
    wallets.forEach(w => {
      walletMap[w.userId] = w.balance;
    });

    res.status(200).json({
      success: true,
      data: {
        earnings: totalEarnings,
        totalReferrals: referrals.length,
        referrals: referrals.map(ref => ({
          id: ref.referredId,
          earnings: ref.earnings || 0,
          pendingEarnings: ref.pendingEarnings != null ? Number(ref.pendingEarnings).toFixed(18) : '0.000000000000000000',
          username: ref.referredUserDetails.username,
          joinedAt: ref.referredUserDetails.joinedAt,
          walletBalance: walletMap[ref.referredId] || '0.000000000000000000'
        }))
      }
    });
  } catch (error) {
    logger.error('Error getting referral earnings:', error);
    res.status(500).json({
      success: false,
      message: 'Error retrieving referral earnings'
    });
  }
};

exports.createReferral = async (req, res) => {
  try {
    const { referralCode } = req.body;
    const currentUser = req.user;

    if (!referralCode) {
      return res.status(400).json({
        success: false,
        message: 'Referral code is required'
      });
    }

    const referrer = await User.findOne({ referralCode });
    if (!referrer) {
      return res.status(400).json({
        success: false,
        message: 'Invalid referral code'
      });
    }

    if (referrer.userId === currentUser.userId) {
      return res.status(400).json({
        success: false,
        message: 'You cannot refer yourself'
      });
    }

    const existingReferral = await Referral.findOne({ referredId: currentUser.userId });
    if (existingReferral) {
      return res.status(400).json({
        success: false,
        message: 'You have already been referred'
      });
    }

    const referral = await Referral.create({
      referrerId: referrer.userId,
      referredId: currentUser.userId,
      referrerCode: referralCode,
      status: 'active',
      referredUserDetails: {
        username: currentUser.userName,
        email: currentUser.userEmail,
        joinedAt: new Date()
      }
    });

    res.status(201).json({
      success: true,
      data: { referral }
    });
  } catch (error) {
    logger.error('Error creating referral:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating referral'
    });
  }
};

exports.claimReferralRewards = async (req, res) => {
  try {
    const user = req.user;
    // Find all referrals where the user is the referrer
    const referrals = await Referral.find({
      referrerId: user.userId,
      status: 'active'
    });

    if (!referrals || referrals.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'No unclaimed referral rewards found'
      });
    }

    // Check claim cooldown (all referrals must be eligible)
    const now = new Date();
    let canClaim = false;
    for (const referral of referrals) {
      // Allow claim if lastClaimDate is null (reset at 1 AM)
      if (!referral.lastClaimDate) {
        canClaim = true;
        break;
      }
      const hoursSinceLastClaim = (now - new Date(referral.lastClaimDate)) / (1000 * 60 * 60);
      if (hoursSinceLastClaim >= 24) {
        canClaim = true;
        break;
      }
    }
    if (!canClaim) {
      return res.status(400).json({
        success: false,
        message: 'You can only claim referral rewards once every 24 hours. Next claim available after 1 AM or 24 hours from your last claim.'
      });
    }

    let totalEarnings = 0;
    for (const referral of referrals) {
      if ((referral.pendingEarnings || 0) > 0) {
        // Ensure both are numbers
        const earningsNum = typeof referral.earnings === 'number' ? referral.earnings : parseFloat(referral.earnings || '0');
        const pendingNum = typeof referral.pendingEarnings === 'number' ? referral.pendingEarnings : parseFloat(referral.pendingEarnings || '0');
        totalEarnings += pendingNum;
        referral.earnings = parseFloat((earningsNum + pendingNum).toFixed(18));
        referral.pendingEarnings = 0;
        referral.lastClaimDate = now;
        await referral.save();
      }
    }

    if (totalEarnings === 0) {
      return res.status(400).json({
        success: false,
        message: 'No rewards available to claim at this time'
      });
    }

    // Update user's wallet balance (not User model)
    const Wallet = require('../models/wallet.model');
    const userWallet = await Wallet.findOne({ userId: user.userId });
    const txnId = 'TXN-' + Date.now(); // Generate a unique transactionId
    if (userWallet) {
      await userWallet.addTransaction({
        transactionId: txnId,
        type: 'referral',
        amount: totalEarnings.toFixed(18),
        status: 'completed',
        description: 'Referral earnings claimed',
      });
    } else {
      // If wallet does not exist, create one and add transaction
      const newWallet = await Wallet.create({ userId: user.userId, balance: totalEarnings.toFixed(18) });
      await newWallet.addTransaction({
        transactionId: txnId,
        type: 'referral',
        amount: totalEarnings.toFixed(18),
        status: 'completed',
        description: 'Referral earnings claimed',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Referral rewards claimed successfully',
      data: {
        claimedAmount: totalEarnings
      }
    });
  } catch (error) {
    logger.error('Error claiming referral rewards:', error);
    res.status(500).json({
      success: false,
      message: 'Error processing referral rewards claim'
    });
  }
};

// Helper function to check if enough time has passed since last claim
function isClaimable(lastClaimDate) {
  const CLAIM_COOLDOWN_HOURS = 24;
  const hoursSinceLastClaim = (new Date() - new Date(lastClaimDate)) / (1000 * 60 * 60);
  return hoursSinceLastClaim >= CLAIM_COOLDOWN_HOURS;
}

// Helper function to calculate referral rewards
function calculateReferralRewards(referral) {
  // Calculate 1% of referred user's wallet balance
  const referredId = referral.referredId;
  // This function will be called inside an async context, so we need to handle the async call where it's used
  // Here, just return a placeholder and update the usage in the claim logic
  return { referredId };
}

module.exports = exports;