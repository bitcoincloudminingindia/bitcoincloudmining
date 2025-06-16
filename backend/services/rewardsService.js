const UserRewards = require('../models/userRewards.model');
const RewardsHistory = require('../models/rewardsHistory.model');
const User = require('../models/user.model');
const Wallet = require('../models/wallet.model');
const BigNumber = require('bignumber.js');
const logger = require('../utils/logger');

// Get total rewards for a user
exports.getTotalRewards = async (userId) => {
    try {
        const userRewards = await UserRewards.findOne({ user_id: userId });
        return (userRewards?.total_rewards || 0).toFixed(18);
    } catch (error) {
        console.error('Database error in getTotalRewards:', error);
        throw new Error('Failed to fetch total rewards');
    }
};

// Update rewards for a user
exports.updateRewards = async (userId, amount, type, description) => {
    try {
        // Update total rewards using findOneAndUpdate
        await UserRewards.findOneAndUpdate(
            { user_id: userId },
            { 
                $inc: { total_rewards: amount },
                $set: { last_updated: new Date() }
            },
            { upsert: true, new: true }
        );

        // Add to rewards history
        await RewardsHistory.create({
            user_id: userId,
            amount,
            type,
            description,
            created_at: new Date()
        });

        // Update user's claimed rewards for all reward types
        const user = await User.findById(userId);
        if (user) {
            const currentTotalClaimed = parseFloat(user.totalRewardsClaimed || '0');
            const currentTodayClaimed = parseFloat(user.todayRewardsClaimed || '0');
            const newAmount = parseFloat(amount);

            // Update total and today's claimed rewards
            user.totalRewardsClaimed = (currentTotalClaimed + newAmount).toFixed(18);
            user.todayRewardsClaimed = (currentTodayClaimed + newAmount).toFixed(18);
            user.lastRewardClaimDate = new Date();
            
            await user.save();
        }
    } catch (error) {
        console.error('Database error in updateRewards:', error);
        throw new Error('Failed to update rewards');
    }
};

// Get rewards history for a user
exports.getRewardsHistory = async (userId, page, limit) => {
    try {
        const skip = (page - 1) * limit;
        
        const [history, total] = await Promise.all([
            RewardsHistory.find({ user_id: userId })
                .sort({ created_at: -1 })
                .skip(skip)
                .limit(parseInt(limit)),
            RewardsHistory.countDocuments({ user_id: userId })
        ]);

        return {
            history,
            pagination: {
                total,
                page: parseInt(page),
                limit: parseInt(limit),
                pages: Math.ceil(total / limit)
            }
        };
    } catch (error) {
        console.error('Database error in getRewardsHistory:', error);
        throw new Error('Failed to fetch rewards history');
    }
};

// Get claimed rewards info for a user
exports.getClaimedRewardsInfo = async (userId) => {
    try {
        if (!userId) {
            throw new Error('User ID is required');
        }

        console.log('Finding user with ID:', userId);
        const user = await User.findById(userId);
        if (!user) {
            console.log('User not found with ID:', userId);
            throw new Error('User not found');
        }

        console.log('User found:', user._id);
        console.log('Current totalRewardsClaimed:', user.totalRewardsClaimed);
        console.log('Current todayRewardsClaimed:', user.todayRewardsClaimed);
        console.log('Last reward claim date:', user.lastRewardClaimDate);

        // Check if we need to reset today's rewards
        const now = new Date();
        const lastClaimDate = user.lastRewardClaimDate || new Date(0);
        const isToday = lastClaimDate.getDate() === now.getDate() &&
                       lastClaimDate.getMonth() === now.getMonth() &&
                       lastClaimDate.getFullYear() === now.getFullYear();

        console.log('Is today:', isToday);
        console.log('Last claim date:', lastClaimDate);
        console.log('Current date:', now);

        // Reset today's rewards if it's a new day
        if (!isToday) {
            console.log('Resetting today\'s rewards to 0');
            user.todayRewardsClaimed = '0.000000000000000000';
            
            // Clean up invalid transactions
            if (user.wallet && user.wallet.transactions) {
                user.wallet.transactions = user.wallet.transactions.filter(tx => 
                    tx && tx.type && tx.amount && 
                    ['deposit', 'withdrawal', 'mining', 'referral', 'tap', 'game', 'penalty', 
                     'Withdrawal - Paypal', 'Withdrawal - Paytm', 'Withdrawal - Bitcoin'].includes(tx.type)
                );
            }
            
            await user.save();
        }

        // Ensure we have valid values
        const totalRewards = user.totalRewardsClaimed || '0.000000000000000000';
        const todayRewards = user.todayRewardsClaimed || '0.000000000000000000';
        const lastDate = user.lastRewardClaimDate || new Date();

        console.log('Final total rewards:', totalRewards);
        console.log('Final today rewards:', todayRewards);

        return {
            claimedRewards: [
                {
                    amount: totalRewards,
                    date: lastDate,
                    type: 'total'
                },
                {
                    amount: todayRewards,
                    date: lastDate,
                    type: 'today'
                }
            ]
        };
    } catch (error) {
        console.error('Database error in getClaimedRewardsInfo:', error);
        throw new Error(error.message || 'Failed to fetch claimed rewards info');
    }
};

exports.getUserRewards = async (userId) => {
    try {
        const userRewards = await UserRewards.findOne({ userId });
        if (!userRewards) {
            return {
                totalRewards: '0.000000000000000000',
                claimedRewards: '0.000000000000000000',
                pendingRewards: '0.000000000000000000',
                lastClaimed: null
            };
        }

        return {
            totalRewards: userRewards.totalRewards,
            claimedRewards: userRewards.claimedRewards,
            pendingRewards: userRewards.pendingRewards,
            lastClaimed: userRewards.lastClaimed
        };
    } catch (error) {
        throw error;
    }
};

exports.claimRewards = async (userId) => {
    try {
        const user = await User.findOne({ userId });
        if (!user) {
            throw new Error('User not found');
        }

        const userRewards = await UserRewards.findOne({ userId });
        if (!userRewards || userRewards.pendingRewards === '0.000000000000000000') {
            throw new Error('No rewards to claim');
        }

        // Create transaction for reward claim
        const transaction = await Transaction.create({
            userId,
            type: 'reward_claim',
            amount: userRewards.pendingRewards,
            netAmount: userRewards.pendingRewards,
            status: 'completed',
            details: {
                type: 'reward_claim'
            }
        });

        // Update wallet balance
        const wallet = await Wallet.findOne({ userId });
        if (!wallet) {
            throw new Error('Wallet not found');
        }

        const currentBalance = new BigNumber(wallet.balance);
        const rewardAmount = new BigNumber(userRewards.pendingRewards);
        wallet.balance = currentBalance.plus(rewardAmount).toFixed(18);
        wallet.lastUpdated = new Date();
        wallet.transactions.push(transaction._id);
        await wallet.save();

        // Update rewards record
        userRewards.claimedRewards = new BigNumber(userRewards.claimedRewards)
            .plus(userRewards.pendingRewards)
            .toFixed(18);
        userRewards.pendingRewards = '0.000000000000000000';
        userRewards.lastClaimed = new Date();
        await userRewards.save();

        return {
            success: true,
            amount: userRewards.claimedRewards,
            transactionId: transaction._id
        };
    } catch (error) {
        throw error;
    }
};

// Add reward transaction
const addRewardTransaction = async (userId, amount, type, description = '') => {
  try {
    const wallet = await Wallet.findOne({ userId });
    if (!wallet) {
      throw new Error('Wallet not found');
    }

    // Generate transaction ID
    const transactionId = crypto.randomBytes(16).toString('hex');

    // Create new transaction
    const transaction = {
      type,
      amount: new BigNumber(amount).toFixed(18),
      netAmount: new BigNumber(amount).toFixed(18),
      currency: 'BTC',
      localAmount: new BigNumber(amount).times(wallet.exchangeRate).toFixed(2),
      exchangeRate: wallet.exchangeRate,
      status: 'completed',
      transactionId,
      timestamp: new Date(),
      description,
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
          'wallet.lastUpdated': new Date()
        }
      }
    );

    // Save wallet
    await wallet.save();

    return transaction;
  } catch (error) {
    logger.error('Error adding reward transaction:', error);
    throw error;
  }
};

module.exports = {
  addRewardTransaction
}; 