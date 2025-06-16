const User = require('../models/user.model');
const Referral = require('../models/referral.model');
const AppError = require('../utils/appError');
const logger = require('../utils/logger');

// Get daily rewards for a user
exports.getDailyRewards = async (req, res, next) => {
  try {
    const user = await User.findOne({ userId: req.user.userId });
    if (!user) {
      return next(new AppError('User not found', 404));
    }

    // Get all active referrals
    const referrals = await Referral.find({ 
      referrerId: req.user.userId,
      status: 'active'
    }).populate('referredId', 'walletBalance');

    let totalDailyRewards = 0;
    const rewardsDetails = [];

    // Calculate daily rewards for each referral
    for (const referral of referrals) {
      if (referral.referredId && referral.referredId.walletBalance > 0) {
        const dailyReward = parseFloat(referral.referredId.walletBalance) * 0.01;
        totalDailyRewards += dailyReward;
        
        rewardsDetails.push({
          referralId: referral._id,
          referredUser: referral.referredId,
          referredBalance: referral.referredId.walletBalance,
          dailyReward
        });
      }
    }

    res.json({
      success: true,
      data: {
        totalDailyRewards,
        rewardsDetails
      }
    });
  } catch (error) {
    logger.error('Error getting daily rewards:', error);
    next(new AppError('Error getting daily rewards', 500));
  }
};

// Claim daily rewards
exports.claimDailyRewards = async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return next(new AppError('User not found', 404));
    }

    // Get all active referrals
    const referrals = await Referral.find({ 
      referrer: req.user.id,
      status: 'active'
    }).populate('referred', 'walletBalance');

    let totalClaimedRewards = 0;

    // Process each referral
    for (const referral of referrals) {
      if (referral.referred && referral.referred.walletBalance > 0) {
        const dailyReward = parseFloat(referral.referred.walletBalance) * 0.01;
        
        // Add reward to referral earnings
        await referral.calculateDailyReward(referral.referred);
        totalClaimedRewards += dailyReward;
      }
    }

    if (totalClaimedRewards > 0) {
      // Update user's wallet balance
      user.walletBalance = (parseFloat(user.walletBalance) + totalClaimedRewards).toFixed(8);
      await user.save();

      res.json({
        success: true,
        message: 'Daily rewards claimed successfully',
        data: {
          claimedAmount: totalClaimedRewards,
          newBalance: user.walletBalance
        }
      });
    } else {
      res.json({
        success: true,
        message: 'No daily rewards available to claim',
        data: {
          claimedAmount: 0,
          newBalance: user.walletBalance
        }
      });
    }
  } catch (error) {
    logger.error('Error claiming daily rewards:', error);
    next(new AppError('Error claiming daily rewards', 500));
  }
};

// Get daily rewards history
exports.getDailyRewardsHistory = async (req, res, next) => {
  try {
    const referrals = await Referral.find({ referrer: req.user.id })
      .select('earningsHistory')
      .sort({ 'earningsHistory.timestamp': -1 });

    const history = referrals.reduce((acc, referral) => {
      return acc.concat(
        referral.earningsHistory
          .filter(earning => earning.type === 'daily_reward')
          .map(earning => ({
            amount: earning.amount,
            timestamp: earning.timestamp,
            referredUserBalance: earning.referredUserBalance
          }))
      );
    }, []);

    res.json({
      success: true,
      data: {
        history
      }
    });
  } catch (error) {
    logger.error('Error getting daily rewards history:', error);
    next(new AppError('Error getting daily rewards history', 500));
  }
}; 