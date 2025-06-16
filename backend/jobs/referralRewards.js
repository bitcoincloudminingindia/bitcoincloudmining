const cron = require('node-cron');
const Referral = require('../models/referral.model');
const User = require('../models/user.model');
const logger = require('../utils/logger');

// Helper function to format BTC amount to 18 decimal places
const formatBTC = (amount) => {
  return Number(amount.toFixed(18));
};

// Run every day at midnight
const scheduleDailyRewards = () => {
  cron.schedule('0 0 * * *', async () => {
    try {
      logger.info('Starting daily referral rewards calculation...');
      
      // Get all active referrals
      const referrals = await Referral.find({ status: 'active' })
        .populate('referred', 'walletBalance');
      
      logger.info(`Found ${referrals.length} active referrals`);
      
      // Process each referral
      for (const referral of referrals) {
        try {
          if (!referral.referred) {
            logger.warn(`Skipping referral ${referral._id}: No referred user`);
            continue;
          }

          const reward = await referral.calculateDailyReward(referral.referred);
          
          if (reward > 0) {
            logger.info(`Added daily reward of ${reward} BTC for referral ${referral._id}`);
          }
        } catch (error) {
          logger.error(`Error processing referral ${referral._id}:`, error);
        }
      }
      
      logger.info('Completed daily referral rewards calculation');
    } catch (error) {
      logger.error('Error in daily referral rewards job:', error);
    }
  });
};

module.exports = {
  scheduleDailyRewards
}; 