const express = require('express');
const router = express.Router();
const rewardsController = require('../controllers/rewardsController');
const { authenticate } = require('../middleware/auth.middleware');

// Get total rewards
router.get('/total', authenticate, rewardsController.getTotalRewards);

// Get claimed rewards info
router.get('/claimed', authenticate, rewardsController.getClaimedRewardsInfo);

// Update rewards
router.post('/update', authenticate, rewardsController.updateRewards);

// Get rewards history
router.get('/history', authenticate, rewardsController.getRewardsHistory);

module.exports = router; 