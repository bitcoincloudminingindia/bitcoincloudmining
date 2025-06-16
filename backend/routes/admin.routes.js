const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
const { isAdmin } = require('../middleware/auth.middleware');

// Get all pending withdrawal requests
router.get('/withdrawals/pending', isAdmin, adminController.getPendingWithdrawals);

// Approve withdrawal request
router.post('/withdrawals/approve', isAdmin, adminController.approveWithdrawal);

// Reject withdrawal request
router.post('/withdrawals/reject', isAdmin, adminController.rejectWithdrawal);

// Get withdrawal statistics
router.get('/withdrawals/stats', isAdmin, adminController.getWithdrawalStats);

module.exports = router; 