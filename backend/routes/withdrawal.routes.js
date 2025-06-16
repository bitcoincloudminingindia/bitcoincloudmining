const express = require('express');
const router = express.Router();
const withdrawalController = require('../controllers/withdrawal.controller');
const { authenticate } = require('../middleware/auth');

// Protected routes
router.use(authenticate);

// Get user's withdrawals
router.get('/my-withdrawals', withdrawalController.getUserWithdrawals);

// Get withdrawal by ID
router.get('/:id', withdrawalController.getWithdrawalById);

// Create withdrawal
router.post('/', withdrawalController.createWithdrawal);

// Update withdrawal status
router.patch('/:id/status', withdrawalController.updateWithdrawalStatus);

// Cancel withdrawal
router.post('/:id/cancel', withdrawalController.cancelWithdrawal);

module.exports = router; 