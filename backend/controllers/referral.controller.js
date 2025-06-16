const Referral = require('../models/referral.model');
const User = require('../models/user.model');
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
    const user = await User.findOne({ userId: req.user.userId });

    res.status(200).json({
      success: true,
      data: {
        referralCode: user.referralCode,
        totalEarnings,
        totalReferrals: referrals.length,
        referrals: referrals.map(ref => ({
          id: ref.referredId,
          username: ref.referredUserDetails.username,
          email: ref.referredUserDetails.email,
          joinedAt: ref.referredUserDetails.joinedAt,
          earnings: ref.earnings || 0
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

    res.status(200).json({
      success: true,
      data: {
        earnings: totalEarnings,
        totalReferrals: referrals.length,
        referrals: referrals.map(ref => ({
          id: ref.referredId,
          earnings: ref.earnings || 0,
          username: ref.referredUserDetails.username,
          joinedAt: ref.referredUserDetails.joinedAt
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

    let totalEarnings = 0;

    // Calculate and update earnings for each referral
    for (const referral of referrals) {
      if (!referral.lastClaimDate || isClaimable(referral.lastClaimDate)) {
        const earnings = calculateReferralRewards(referral);
        totalEarnings += earnings;

        referral.earnings = (referral.earnings || 0) + earnings;
        referral.lastClaimDate = new Date();
        await referral.save();
      }
    }

    if (totalEarnings === 0) {
      return res.status(400).json({
        success: false,
        message: 'No rewards available to claim at this time'
      });
    }

    // Update user's balance
    await User.findOneAndUpdate(
      { userId: user.userId },
      { $inc: { balance: totalEarnings } }
    );

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
  // Basic implementation - can be adjusted based on your reward structure
  const BASE_REWARD = 0.0001; // Base reward in BTC
  return BASE_REWARD;
}

module.exports = exports;