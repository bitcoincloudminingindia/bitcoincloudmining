const Wallet = require('../models/wallet.model');
const User = require('../models/user.model');
const Transaction = require('../models/transaction.model');
const BigNumber = require('bignumber.js');

const REWARD_TYPES = {
  DAILY_REWARD: 'daily_reward',
  GAME_REWARD: 'game_reward',
  TAP_REWARD: 'tap_reward',
  REFERRAL_REWARD: 'referral',
  STREAK_REWARD: 'streak_reward',
  YOUTUBE_REWARD: 'youtube_reward',
  TWITTER_REWARD: 'twitter_reward',
  TELEGRAM_REWARD: 'telegram_reward',
  INSTAGRAM_REWARD: 'instagram_reward',
  FACEBOOK_REWARD: 'facebook_reward',
  TIKTOK_REWARD: 'tiktok_reward',
  SOCIAL_REWARD: 'social_reward',
  AD_REWARD: 'ad_reward'
};

const addReward = async (userId, amount, type, description = '') => {
  try {
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      throw new Error('Wallet not found');
    }

    const transaction = {
      type,
      amount,
      status: 'completed',
      description,
      timestamp: new Date()
    };

    wallet.transactions.push(transaction);
    wallet.balance = (parseFloat(wallet.balance) + amount).toFixed(18);
    await wallet.save();

    // Update user's claimed rewards
    const user = await User.findById(userId);
    if (user) {
      const currentTotalClaimed = parseFloat(user.totalRewardsClaimed || '0');
      const currentTodayClaimed = parseFloat(user.todayRewardsClaimed || '0');
      const newAmount = parseFloat(amount);

      user.totalRewardsClaimed = (currentTotalClaimed + newAmount).toFixed(18);
      user.todayRewardsClaimed = (currentTodayClaimed + newAmount).toFixed(18);
      user.lastRewardClaimDate = new Date();
      await user.save();
    }

    return {
      success: true,
      message: 'Reward added successfully',
      transaction
    };
  } catch (error) {
    console.error('Error adding reward:', error);
    throw error;
  }
};

const getClaimedRewardsInfo = async (userId) => {
  try {
    const user = await User.findById(userId);
    if (!user) {
      throw new Error('User not found');
    }

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
    }

    // Get wallet transactions
    const wallet = await Wallet.findOne({ userId });
    const rewards = wallet ? wallet.transactions.filter(tx => 
      Object.values(REWARD_TYPES).includes(tx.type)
    ) : [];

    return {
      success: true,
      data: {
        claimedRewards: [
          {
            amount: user.totalRewardsClaimed || '0.000000000000000000',
            date: user.lastRewardClaimDate || new Date(),
            type: 'total'
          },
          {
            amount: user.todayRewardsClaimed || '0.000000000000000000',
            date: user.lastRewardClaimDate || new Date(),
            type: 'today'
          }
        ],
        transactions: rewards
      }
    };
  } catch (error) {
    console.error('Error getting claimed rewards:', error);
    throw error;
  }
};

exports.calculateRewards = async (userId) => {
  try {
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      throw new Error('Wallet not found');
    }

    const user = await User.findOne({ userId });
    if (!user) {
      throw new Error('User not found');
    }

    // Calculate rewards based on wallet balance
    const balance = new BigNumber(wallet.balance);
    const rewardRate = new BigNumber('0.0001'); // 0.01% per day
    const reward = balance.times(rewardRate).toFixed(18);

    return {
      userId,
      reward,
      timestamp: new Date()
    };
  } catch (error) {
    throw error;
  }
};

exports.distributeRewards = async (userId, reward) => {
  try {
    const user = await User.findOne({ userId });
    if (!user) {
      throw new Error('User not found');
    }

    // Create transaction for reward
    const transaction = await Transaction.create({
      userId,
      type: 'reward',
      amount: reward,
      netAmount: reward,
      status: 'completed',
      details: {
        type: 'daily_reward'
      }
    });

    // Update wallet balance
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      throw new Error('Wallet not found');
    }

    const currentBalance = new BigNumber(wallet.balance);
    const rewardAmount = new BigNumber(reward);
    wallet.balance = currentBalance.plus(rewardAmount).toFixed(18);
    wallet.lastUpdated = new Date();
    wallet.transactions.push(transaction._id);
    await wallet.save();

    return transaction;
  } catch (error) {
    throw error;
  }
};

module.exports = {
  REWARD_TYPES,
  addReward,
  getClaimedRewardsInfo,
  calculateRewards,
  distributeRewards
}; 