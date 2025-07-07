const cron = require('node-cron');
const mongoose = require('mongoose');
const Referral = require('../models/referral.model');
const User = require('../models/user.model');
const logger = require('../utils/logger');

// Helper function to format BTC amount to 18 decimal places
const formatBTC = (amount) => {
  return Number(amount.toFixed(18));
};

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

// Run every day at midnight
const scheduleDailyRewards = () => {
  cron.schedule('0 0 * * *', async () => {
    try {
      logger.info('Starting daily referral rewards calculation...');

      // Check connection before starting
      if (!await waitForConnection()) {
        logger.error('MongoDB connection not available for daily referral rewards calculation');
        return;
      }

      // Get all active referrals with lean() for better performance
      const referrals = await Referral.find({ status: 'active' })
        .populate('referred', 'walletBalance')
        .lean();

      logger.info(`Found ${referrals.length} active referrals`);

      let processedCount = 0;
      let errorCount = 0;

      // Process each referral
      for (const referral of referrals) {
        try {
          // Check connection before each operation
          if (!checkConnection()) {
            logger.warn('MongoDB connection lost during referral rewards processing, skipping remaining');
            break;
          }

          if (!referral.referred) {
            logger.warn(`Skipping referral ${referral._id}: No referred user`);
            continue;
          }

          const reward = await referral.calculateDailyReward(referral.referred);

          if (reward > 0) {
            logger.info(`Added daily reward of ${reward} BTC for referral ${referral._id}`);
            processedCount++;
          }
        } catch (error) {
          errorCount++;
          logger.error(`Error processing referral ${referral._id}:`, error);
          // Continue with next referral instead of stopping
        }
      }

      logger.info(`Completed daily referral rewards calculation. Processed: ${processedCount}, Errors: ${errorCount}`);
    } catch (error) {
      logger.error('Error in daily referral rewards job:', error);
    }
  });
};

module.exports = {
  scheduleDailyRewards
}; 