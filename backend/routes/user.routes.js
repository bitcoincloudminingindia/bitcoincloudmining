const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { authenticate } = require('../middleware/auth');
const userController = require('../controllers/user.controller');
const authController = require('../controllers/auth.controller');
const walletController = require('../controllers/wallet.controller');
const transactionController = require('../controllers/transaction.controller');

// Validation middleware
const registerValidator = [
  body('fullName').notEmpty().withMessage('Full name is required'),
  body('email').isEmail().withMessage('Please enter a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters long')
];

const loginValidator = [
  body('email').isEmail().withMessage('Please enter a valid email'),
  body('password').notEmpty().withMessage('Password is required')
];

// Public routes
router.post('/register', userController.register);
router.post('/verify-email', userController.verifyEmail);
router.post('/login', userController.login);
router.post('/forgot-password', userController.forgotPassword);
router.post('/reset-password', userController.resetPassword);
router.post('/resend-verification', userController.resendVerification);

// Protected routes
router.get('/profile', authenticate, userController.getProfile);
router.patch('/profile', authenticate, userController.updateProfile);
router.get('/referral-info', authenticate, userController.getReferralInfo);
router.get('/referred-users', authenticate, userController.getReferredUsers);
router.get('/total-earnings', authenticate, userController.getTotalEarnings);
router.post('/change-password', authenticate, userController.changePassword);
router.get('/wallet', authenticate, userController.getWallet);
router.post('/wallet/update', authenticate, userController.updateWallet);

router.get('/transactions', authenticate, (req, res) => userController.getTransactions(req, res));
router.get('/mining-stats', authenticate, (req, res) => userController.getMiningStats(req, res));
router.get('/rewards', authenticate, (req, res) => userController.getRewards(req, res));
router.post('/claim-reward', authenticate, (req, res) => userController.claimReward(req, res));

// Transaction routes
router.get('/transactions', authenticate, transactionController.getUserTransactions);
router.get('/transactions/:transactionId', authenticate, transactionController.getTransactionById);
router.get('/transactions/stats', authenticate, transactionController.getTransactionStats);

// Referral routes
router.get('/referrals', authenticate, userController.getReferrals);

// Wallet routes
router.get('/wallet/balance', authenticate, walletController.getWalletBalance);
router.get('/wallet/transactions', authenticate, walletController.getWalletTransactions);
router.get('/wallet/transactions/:transactionId', authenticate, walletController.getTransactionById);
router.post('/wallet/sync-balance', authenticate, walletController.syncBalance);
router.post('/wallet/withdraw', authenticate, walletController.requestWithdrawal);

module.exports = router; 