const express = require('express');
const router = express.Router();
const dailyRewardController = require('../controllers/dailyReward.controller');
const { authenticate } = require('../middleware/auth');

// Get daily rewards
router.get('/', authenticate, dailyRewardController.getDailyRewards);

// Claim daily rewards
router.post('/claim', authenticate, dailyRewardController.claimDailyRewards);

// Get daily rewards history
router.get('/history', authenticate, dailyRewardController.getDailyRewardsHistory);

module.exports = router; 