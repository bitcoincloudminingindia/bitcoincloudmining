const express = require('express');
const router = express.Router();
const adminController = require('../controllers/admin.controller');
console.log('admin.routes.js adminController:', Object.keys(adminController));
const { authenticate, isAdmin } = require('../middleware/auth.middleware');

// Get all pending withdrawal requests
router.get('/withdrawals/pending', authenticate, isAdmin, adminController.getPendingWithdrawals);

// Approve withdrawal request
router.post('/withdrawals/approve', authenticate, isAdmin, adminController.approveWithdrawal);

// Reject withdrawal request
router.post('/withdrawals/reject', authenticate, isAdmin, adminController.rejectWithdrawal);

// Get withdrawal statistics
router.get('/withdrawals/stats', authenticate, isAdmin, adminController.getWithdrawalStats);

// Get latest withdrawals (for dashboard)
router.get('/withdrawals', authenticate, isAdmin, adminController.getLatestWithdrawals);

// Admin login endpoint (no auth required)
router.post('/login', adminController.adminLogin);

// User Management
// User stats routes (specific first) - these must come BEFORE dynamic routes
router.get('/users/count', authenticate, isAdmin, adminController.getUserCount);
router.get('/users/active-count', authenticate, isAdmin, adminController.getActiveUserCount);
router.get('/users/active-hours', authenticate, isAdmin, adminController.getUserActiveHours);
router.get('/users/export', authenticate, isAdmin, adminController.exportUsers);

// User hourly activity (platform-wide) - must come before dynamic routes
router.get('/users/activity-hours', authenticate, isAdmin, adminController.getUserHourlyActivity);

// General user routes (dynamic last)
router.get('/users', authenticate, isAdmin, adminController.getUsers);
router.get('/users/:id', authenticate, isAdmin, adminController.getUserById);
router.post('/users/:id/block', authenticate, isAdmin, adminController.blockUser);
router.post('/users/:id/unblock', authenticate, isAdmin, adminController.unblockUser);

// Wallet Management
router.get('/users/:id/wallet', authenticate, isAdmin, adminController.getUserWallet);
router.post('/users/:id/wallet/adjust', authenticate, isAdmin, adminController.adjustWallet);
router.get('/users/:id/wallet/transactions', authenticate, isAdmin, adminController.getWalletTransactions);
router.put('/users/:id/wallet/transactions/:txId/status', authenticate, isAdmin, adminController.updateTransactionStatus);
router.get('/wallets/export', authenticate, isAdmin, adminController.exportWallets);
// All wallets and all wallet transactions
router.get('/wallets', authenticate, isAdmin, adminController.getAllWallets);
router.get('/wallets/transactions', authenticate, isAdmin, adminController.getAllWalletTransactions);

// Market rates for wallet conversion
router.get('/wallets/rates', authenticate, isAdmin, adminController.getWalletMarketRates);

// Referral Analytics
router.get('/referral/stats', authenticate, isAdmin, adminController.getReferralStats);
router.get('/referral', authenticate, isAdmin, adminController.getReferrals);

// Referral Settings
router.get('/settings/referral', authenticate, isAdmin, adminController.getReferralSettings);
router.put('/settings/referral', authenticate, isAdmin, adminController.updateReferralSettings);

// Dashboard Analytics
router.get('/dashboard/analytics', authenticate, isAdmin, adminController.getDashboardAnalytics);

module.exports = router; 