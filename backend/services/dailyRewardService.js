const DailyReward = require('../models/dailyReward.model');
const User = require('../models/user.model');
const Wallet = require('../models/wallet.model');
const BigNumber = require('bignumber.js');
const crypto = require('crypto');
const logger = require('../utils/logger');

// Calculate reward amount based on streak
const calculateRewardAmount = (streak) => {
    const baseAmount = 0.00000001; // Base reward amount
    const streakMultiplier = Math.min(streak, 7); // Cap streak multiplier at 7
    return (baseAmount * streakMultiplier).toFixed(18);
};

// Get daily reward info for a user
exports.getDailyRewardInfo = async (userId) => {
    try {
        let dailyReward = await DailyReward.findOne({ userId });
        
        if (!dailyReward) {
            dailyReward = new DailyReward({ userId });
            await dailyReward.save();
        }
        
        const canClaim = dailyReward.canClaim();
        const nextClaimTime = dailyReward.lastClaimDate 
            ? new Date(dailyReward.lastClaimDate.getTime() + 24 * 60 * 60 * 1000)
            : null;
            
        return {
            canClaim,
            streakCount: dailyReward.streakCount,
            lastClaimDate: dailyReward.lastClaimDate,
            nextClaimTime,
            nextRewardAmount: calculateRewardAmount(dailyReward.streakCount + 1)
        };
    } catch (error) {
        console.error('Error in getDailyRewardInfo:', error);
        throw new Error('Failed to get daily reward info');
    }
};

// Get daily reward for a user
exports.getDailyReward = async (userId) => {
    try {
        let dailyReward = await DailyReward.findOne({ userId });
        
        if (!dailyReward) {
            // Create new daily reward record
            dailyReward = await DailyReward.create({
                userId,
                lastClaimed: null,
                streak: 0,
                totalRewards: '0.000000000000000000'
            });
        }

        return dailyReward;
    } catch (error) {
        throw error;
    }
};

// Claim daily reward
exports.claimDailyReward = async (userId) => {
    try {
        const dailyReward = await DailyReward.findOne({ userId });
        if (!dailyReward) {
            throw new Error('Daily reward record not found');
        }

        // Check if already claimed today
        const now = new Date();
        const lastClaimed = dailyReward.lastClaimed;
        if (lastClaimed && isSameDay(lastClaimed, now)) {
            throw new Error('Daily reward already claimed today');
        }

        // Calculate reward amount
        const baseReward = new BigNumber('0.0001'); // 0.0001 BTC
        const streakBonus = new BigNumber(dailyReward.streak).times('0.00001'); // 0.00001 BTC per streak
        const totalReward = baseReward.plus(streakBonus).toFixed(18);

        // Update wallet balance
        const wallet = await Wallet.findOne({ userId });
        if (!wallet) {
            throw new Error('Wallet not found');
        }

        const currentBalance = new BigNumber(wallet.balance);
        wallet.balance = currentBalance.plus(totalReward).toFixed(18);
        wallet.lastUpdated = now;
        await wallet.save();

        // Update daily reward record
        dailyReward.lastClaimed = now;
        dailyReward.streak += 1;
        dailyReward.totalRewards = new BigNumber(dailyReward.totalRewards).plus(totalReward).toFixed(18);
        await dailyReward.save();

        return {
            reward: totalReward,
            streak: dailyReward.streak,
            nextClaimAvailable: new Date(now.getTime() + 24 * 60 * 60 * 1000)
        };
    } catch (error) {
        throw error;
    }
};

// Add daily reward
const addDailyReward = async (userId, amount) => {
  try {
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      throw new Error('Wallet not found');
    }

    // Generate transaction ID
    const transactionId = crypto.randomBytes(16).toString('hex');

    // Create new transaction
    const transaction = {
      type: 'daily_reward',
      amount: new BigNumber(amount).toFixed(18),
      netAmount: new BigNumber(amount).toFixed(18),
      currency: 'BTC',
      localAmount: new BigNumber(amount).times(wallet.exchangeRate).toFixed(2),
      exchangeRate: wallet.exchangeRate,
      status: 'completed',
      transactionId,
      timestamp: new Date(),
      description: 'Daily reward',
      completedAt: new Date()
    };

    // Add transaction to wallet
    wallet.transactions.unshift(transaction);

    // Update balance
    await wallet.updateBalance(amount, 'add');

    // Update user's wallet balance
    await User.findOneAndUpdate(
      { _id: userId },
      {
        $set: {
          'wallet.balance': wallet.balance,
          'wallet.lastUpdated': new Date(),
          'wallet.lastDailyReward': new Date()
        }
      }
    );

    // Save wallet
    await wallet.save();

    return transaction;
  } catch (error) {
    logger.error('Error adding daily reward:', error);
    throw error;
  }
};

module.exports = {
  addDailyReward
}; 