const cron = require('node-cron');
const mongoose = require('mongoose');
const Referral = require('../models/referral.model');
const Wallet = require('../models/wallet.model');
const User = require('../models/user.model');
const logger = require('../utils/logger');

// Helper function to check MongoDB connection
const checkConnection = () => {
    return mongoose.connection.readyState === 1;
};

// Helper function to wait for connection
const waitForConnection = async (maxWaitTime = 30000) => {
    const startTime = Date.now();
    while (!checkConnection() && (Date.now() - startTime) < maxWaitTime) {
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
    return checkConnection();
};

// Calculate 1% of referred users' wallet balance daily at 1 AM
cron.schedule('0 1 * * *', async () => {
    logger.info('Starting scheduled referral earnings calculation (1% of referred users wallet balance, daily at 1 AM)');

    // Check connection before starting
    if (!await waitForConnection()) {
        logger.error('MongoDB connection not available for referral earnings calculation');
        return;
    }

    try {
        // Use aggregation for better performance
        const referrals = await Referral.find({ status: 'active' }).lean();
        logger.info(`Processing ${referrals.length} active referrals`);

        let processedCount = 0;
        let errorCount = 0;

        for (const referral of referrals) {
            try {
                // Check connection before each operation
                if (!checkConnection()) {
                    logger.warn('MongoDB connection lost during referral processing, skipping remaining');
                    break;
                }

                const referredWallet = await Wallet.findOne({ userId: referral.referredId }).lean();
                if (referredWallet && referredWallet.balance) {
                    const balance = parseFloat(referredWallet.balance);
                    const earning = parseFloat((balance * 0.01).toFixed(18));
                    const prevPending = typeof referral.pendingEarnings === 'number' ? referral.pendingEarnings : parseFloat(referral.pendingEarnings || '0');
                    const newPending = parseFloat((prevPending + earning).toFixed(18));

                    // Use updateOne for better performance
                    await Referral.updateOne(
                        { _id: referral._id },
                        { $set: { pendingEarnings: newPending } }
                    );

                    processedCount++;
                    logger.info(`Added ${earning.toFixed(18)} BTC to referral ${referral._id} (referrer: ${referral.referrerId}) pending earnings. New pendingEarnings: ${newPending.toFixed(18)}`);
                }
            } catch (error) {
                errorCount++;
                logger.error(`Error processing referral ${referral._id}:`, error);
                // Continue with next referral instead of stopping
            }
        }

        logger.info(`Scheduled referral earnings calculation completed. Processed: ${processedCount}, Errors: ${errorCount}`);
    } catch (error) {
        logger.error('Error in scheduled referral earnings calculation:', error);
    }
});

// Reset claim eligibility at 1 AM (set lastClaimDate to null)
cron.schedule('0 1 * * *', async () => {
    logger.info('Resetting referral claim eligibility at 1 AM');

    // Check connection before starting
    if (!await waitForConnection()) {
        logger.error('MongoDB connection not available for claim eligibility reset');
        return;
    }

    try {
        const result = await Referral.updateMany({}, { $set: { lastClaimDate: null } });
        logger.info(`All referral claim cooldowns reset. Updated ${result.modifiedCount} documents.`);
    } catch (error) {
        logger.error('Error resetting claim eligibility:', error);
    }
});

module.exports = {};
