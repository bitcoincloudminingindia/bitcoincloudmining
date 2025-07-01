const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const referralController = require('../controllers/referral.controller');
const transactionController = require('../controllers/transaction.controller');
const {
  validateReferralCode,
  getReferrals,
  getReferralEarnings,
  claimReferralRewards
} = referralController;
// Transaction related routes are now handled in transaction.routes.js

// Validate referral code
router.post('/validate', validateReferralCode);

// Get user's referrals
router.get('/list', authenticate, getReferrals);

// Get referral earnings
router.get('/earnings', authenticate, getReferralEarnings);

// Claim referral rewards
router.post('/claim', authenticate, claimReferralRewards);

// Create referral
router.post('/', authenticate, referralController.createReferral);

// Get referral stats
router.get('/stats', authenticate, (req, res) => transactionController.getTransactionStats(req, res));

// Transaction stats route has been moved to transaction.routes.js
// router.get('/transactions/stats', getTransactionStats);

// Get referral info
router.get('/info', authenticate, getReferrals);

// Get referred users
router.get('/users', authenticate, getReferrals);

// Add referral statistics route
router.get('/statistics', authenticate, referralController.getReferralStatistics);

module.exports = router;