const User = require('../models/user.model');
const UserRewards = require('../models/userRewards.model');
const Referral = require('../models/referral.model');
const AppError = require('../utils/appError');
const logger = require('../utils/logger');
const Wallet = require('../models/wallet.model');

// Get total rewards for a user
exports.getTotalRewards = async (req, res, next) => {
  try {
    // Use the user object already attached by auth middleware
    const user = req.user;
    logger.info('Processing total rewards for authenticated user:', {
      userId: user.userId,
      timestamp: new Date().toISOString()
    });

    logger.info('Getting total rewards for user:', {
      userId: user.userId,
      timestamp: new Date().toISOString()
    });

    const totalRewards = user.referralStats.claimedEarnings || 0;

    res.json({
      success: true,
      data: {
        totalRewards
      }
    });
  } catch (error) {
    logger.error('Error getting total rewards:', error);
    next(new AppError('Error getting total rewards', 500));
  }
};

// Get claimed rewards info
exports.getClaimedRewardsInfo = async (req, res, next) => {
  try {
    // Use the user object already attached by auth middleware
    const user = req.user;
    logger.info('Processing rewards for authenticated user:', {
      userId: user.userId,
      timestamp: new Date().toISOString()
    });

    logger.info('User found for rewards:', {
      userId: user.userId,
      timestamp: new Date().toISOString()
    });

    // Check if we need to reset today's rewards
    const now = new Date();
    const lastClaimDate = user.lastRewardClaimDate || new Date(0);
    const isToday = lastClaimDate.getDate() === now.getDate() &&
      lastClaimDate.getMonth() === now.getMonth() &&
      lastClaimDate.getFullYear() === now.getFullYear();

    // Reset today's rewards if it's a new day
    if (!isToday) {
      user.todayRewardsClaimed = '0.000000000000000000';
      await user.save();
    }    // Get user rewards and wallet
    const [userRewards, wallet] = await Promise.all([
      UserRewards.findOne({ userId: user.userId }),
      Wallet.findOne({ userId: user.userId })
    ]);

    logger.info('Found user data:', {
      userId: user.userId,
      hasRewards: !!userRewards,
      hasWallet: !!wallet,
      timestamp: new Date().toISOString()
    });    // Create or update user rewards record
    if (!userRewards) {
      try {
        await UserRewards.create({
          userId: user.userId,
          user_id: user._id,
          total_rewards: 0
        });
        logger.info('Created new UserRewards record:', {
          userId: user.userId,
          user_id: user._id,
          timestamp: new Date().toISOString()
        });
      } catch (error) {
        logger.error('Error creating UserRewards record:', {
          error: error.message,
          userId: user.userId,
          user_id: user._id,
          timestamp: new Date().toISOString()
        });
        // Continue execution even if creation fails
      }
    }

    const rewardTransactions = wallet ? wallet.transactions.filter(tx =>
      tx.type && ['daily_reward', 'game_reward', 'tap_reward', 'referral', 'streak_reward',
        'social_reward', 'ad_reward'].includes(tx.type)
    ) : [];

    logger.info('Reward transactions:', {
      userId: user.userId,
      transactionCount: rewardTransactions.length,
      timestamp: new Date().toISOString()
    });

    // Ensure we have valid values
    const totalRewards = user.totalRewardsClaimed || '0.000000000000000000';
    const todayRewards = user.todayRewardsClaimed || '0.000000000000000000';
    const lastClaimDateTime = user.lastRewardClaimDate || new Date(); res.json({
      success: true,
      data: {
        claimedRewards: [
          {
            amount: totalRewards,
            date: lastClaimDateTime,
            type: 'total'
          },
          {
            amount: todayRewards,
            date: lastClaimDateTime,
            type: 'today'
          }
        ],
        rewardTransactions: rewardTransactions.map(tx => ({
          amount: tx.amount,
          type: tx.type,
          timestamp: tx.timestamp,
          description: tx.description
        }))
      }
    });
  } catch (error) {
    logger.error('Error getting claimed rewards info:', error);
    next(new AppError('Error getting claimed rewards info', 500));
  }
};

// Update rewards
exports.updateRewards = async (req, res, next) => {
  try {
    const { amount } = req.body;
    if (!amount || amount <= 0) {
      return next(new AppError('Invalid reward amount', 400));
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return next(new AppError('User not found', 404));
    }

    // Update user's referral earnings
    user.referralStats.claimedEarnings += parseFloat(amount);
    user.referralStats.lastClaimDate = new Date();
    await user.save();

    res.json({
      success: true,
      message: 'Rewards updated successfully',
      data: {
        newTotal: user.referralStats.claimedEarnings
      }
    });
  } catch (error) {
    logger.error('Error updating rewards:', error);
    next(new AppError('Error updating rewards', 500));
  }
};

// Get rewards history
exports.getRewardsHistory = async (req, res, next) => {
  try {
    const referrals = await Referral.find({ referrer: req.user.id })
      .select('earningsHistory')
      .sort({ 'earningsHistory.timestamp': -1 });

    const history = referrals.reduce((acc, referral) => {
      return acc.concat(referral.earningsHistory.map(earning => ({
        amount: earning.amount,
        type: earning.type,
        timestamp: earning.timestamp
      })));
    }, []);

    res.json({
      success: true,
      data: {
        history
      }
    });
  } catch (error) {
    logger.error('Error getting rewards history:', error);
    next(new AppError('Error getting rewards history', 500));
  }
};
