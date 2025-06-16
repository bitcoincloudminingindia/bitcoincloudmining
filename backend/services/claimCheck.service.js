const ClaimCheck = require('../models/claimCheck.model');
const Wallet = require('../models/wallet.model');
const User = require('../models/user.model');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');
const crypto = require('crypto');
const BigNumber = require('bignumber.js');

// Check if user has claimed reward
const checkClaimStatus = async (userId) => {
    try {
        const wallet = await Wallet.findOne({ userId });
        if (!wallet) {
            throw new Error('Wallet not found');
        }

        // Check last claim transaction
        const lastClaim = wallet.transactions.find(
            t => t.type === 'claim'
        );

        if (!lastClaim) {
            return {
                canClaim: true,
                lastClaimTime: null,
                timeUntilNextClaim: 0
            };
        }

        const lastClaimTime = new Date(lastClaim.timestamp);
        const now = new Date();
        const timeSinceLastClaim = now - lastClaimTime;
        const timeUntilNextClaim = Math.max(0, 24 * 60 * 60 * 1000 - timeSinceLastClaim);

        return {
            canClaim: timeUntilNextClaim === 0,
            lastClaimTime,
            timeUntilNextClaim
        };
    } catch (error) {
        logger.error('Error checking claim status:', error);
        throw error;
    }
};

// Add claim transaction
const addClaimTransaction = async (userId, amount) => {
    try {
        const wallet = await Wallet.findOne({ userId });
        if (!wallet) {
            throw new Error('Wallet not found');
        }

        // Generate transaction ID
        const transactionId = crypto.randomBytes(16).toString('hex');

        // Create new transaction
        const transaction = {
            type: 'claim',
            amount: new BigNumber(amount).toFixed(18),
            netAmount: new BigNumber(amount).toFixed(18),
            currency: 'BTC',
            localAmount: new BigNumber(amount).times(wallet.exchangeRate).toFixed(2),
            exchangeRate: wallet.exchangeRate,
            status: 'completed',
            transactionId,
            timestamp: new Date(),
            description: 'Claim reward',
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
        logger.error('Error adding claim transaction:', error);
        throw error;
    }
};

module.exports = {
    checkClaimStatus,
    addClaimTransaction
}; 