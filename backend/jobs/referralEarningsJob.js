const cron = require('node-cron');
const Referral = require('../models/referral.model');
const Wallet = require('../models/wallet.model');
const User = require('../models/user.model');
const logger = require('../utils/logger');

// Calculate 1% of referred users' wallet balance daily at 1 AM
cron.schedule('0 1 * * *', async () => {
    logger.info('Starting scheduled referral earnings calculation (1% of referred users wallet balance, daily at 1 AM)');
    try {
        const referrals = await Referral.find({ status: 'active' });
        for (const referral of referrals) {
            const referredWallet = await Wallet.findOne({ userId: referral.referredId });
            if (referredWallet && referredWallet.balance) {
                const balance = parseFloat(referredWallet.balance);
                const earning = parseFloat((balance * 0.01).toFixed(18));
                const prevPending = typeof referral.pendingEarnings === 'number' ? referral.pendingEarnings : parseFloat(referral.pendingEarnings || '0');
                referral.pendingEarnings = parseFloat((prevPending + earning).toFixed(18));
                await referral.save();
                const pendingNum = typeof referral.pendingEarnings === 'number' ? referral.pendingEarnings : parseFloat(referral.pendingEarnings || '0');
                logger.info(`Added ${earning.toFixed(18)} BTC to referral ${referral._id} (referrer: ${referral.referrerId}) pending earnings. New pendingEarnings: ${pendingNum.toFixed(18)}`);
            }
        }
        logger.info('Scheduled referral earnings calculation completed.');
    } catch (error) {
        logger.error('Error in scheduled referral earnings calculation:', error);
    }
});

// Reset claim eligibility at 1 AM (set lastClaimDate to null)
cron.schedule('0 1 * * *', async () => {
    logger.info('Resetting referral claim eligibility at 1 AM');
    try {
        await Referral.updateMany({}, { $set: { lastClaimDate: null } });
        logger.info('All referral claim cooldowns reset.');
    } catch (error) {
        logger.error('Error resetting claim eligibility:', error);
    }
});

module.exports = {};
