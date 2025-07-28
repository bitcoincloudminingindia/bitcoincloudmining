const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { formatBTCAmounts } = require('../middleware/format.middleware');
const walletController = require('../controllers/wallet.controller');
const transactionController = require('../controllers/transaction.controller');
const { formatBTC, toBigNumber } = require('../utils/format');
const logger = require('../utils/logger');
const withdrawalController = require('../controllers/withdrawal.controller');
const claimCheckRoutes = require('./claimCheck.routes');
const marketRatesRoutes = require('./marketRates.routes'); // <-- create if needed

// Store last sync times for each wallet
const lastSyncTimes = new Map();
const MIN_SYNC_INTERVAL = 5000; // 5 seconds minimum between syncs

// Initialize wallet
router.post('/initialize', authenticate, async (req, res) => {
    try {
        const wallet = await walletController.initializeWallet(req.user.userId);
        res.json({
            success: true,
            data: wallet
        });
    } catch (error) {
        logger.error('Error initializing wallet:', error);
        res.status(500).json({
            success: false,
            message: 'Error initializing wallet',
            error: error.message
        });
    }
});

// Get wallet balance and info
router.get('/balance', authenticate, async (req, res) => {
    try {
        const wallet = await walletController.getWalletByUserId(req.user.userId);

        // Only use wallet.transactions (not global transactions)
        const transactions = wallet.transactions || [];

        res.json({
            success: true,
            data: {
                balance: formatBTC(wallet.balance || '0.000000000000000000'),
                currency: 'BTC',
                transactions: transactions.map(tx => ({
                    ...(typeof tx.toObject === 'function' ? tx.toObject() : tx),
                    amount: formatBTC(tx.amount),
                    netAmount: formatBTC(tx.netAmount)
                })),
                balanceHistory: wallet.balanceHistory
            }
        });
    } catch (error) {
        logger.error('Error fetching wallet balance:', error);
        
        // ❌ FIXED: Don't return zero balance in error case
        // Try to get existing wallet balance first
        try {
            const { Wallet } = require('../models');
            const existingWallet = await Wallet.findOne({ userId: req.user.userId });
            const existingBalance = existingWallet?.balance || '0.000000000000000000';
            
            logger.info(`Fallback: Retrieved existing balance ${existingBalance} for user ${req.user.userId}`);
            
            res.status(200).json({
                success: true,
                data: {
                    balance: formatBTC(existingBalance),
                    currency: 'BTC',
                    transactions: existingWallet?.transactions || [],
                    balanceHistory: existingWallet?.balanceHistory || []
                },
                message: 'Retrieved existing wallet data'
            });
        } catch (fallbackError) {
            logger.error('Fallback wallet fetch also failed:', fallbackError);
            res.status(200).json({
                success: true,
                data: {
                    balance: formatBTC('0'),
                    currency: 'BTC',
                    transactions: [],
                    balanceHistory: []
                },
                message: 'Initializing wallet - no existing data found'
            });
        }
    }
});

// Transaction routes
router.post('/transactions', authenticate, formatBTCAmounts, transactionController.createTransaction);

// Show only wallet.transactions for the user wallet screen
router.get('/transactions', authenticate, async (req, res) => {
    try {
        const wallet = await walletController.getWalletByUserId(req.user.userId);
        const transactions = wallet.transactions || [];
        res.json({
            success: true,
            data: {
                transactions: transactions.map(tx => ({
                    ...(typeof tx.toObject === 'function' ? tx.toObject() : tx),
                    amount: formatBTC(tx.amount),
                    netAmount: formatBTC(tx.netAmount)
                }))
            }
        });
    } catch (error) {
        logger.error('Error fetching wallet transactions:', error);
        
        // ❌ FIXED: Try to get existing transactions before returning empty array
        try {
            const { Wallet } = require('../models');
            const existingWallet = await Wallet.findOne({ userId: req.user.userId });
            const existingTransactions = existingWallet?.transactions || [];
            
            logger.info(`Fallback: Retrieved ${existingTransactions.length} existing transactions for user ${req.user.userId}`);
            
            res.status(200).json({
                success: true,
                data: {
                    transactions: existingTransactions.map(tx => ({
                        ...(typeof tx.toObject === 'function' ? tx.toObject() : tx),
                        amount: formatBTC(tx.amount),
                        netAmount: formatBTC(tx.netAmount)
                    }))
                },
                message: 'Retrieved existing transactions'
            });
        } catch (fallbackError) {
            logger.error('Fallback transaction fetch also failed:', fallbackError);
            res.status(200).json({
                success: true,
                data: {
                    transactions: []
                },
                message: 'No wallet transactions found'
            });
        }
    }
});

router.get('/transactions/:id', authenticate, transactionController.getTransactionById);
router.get('/transactions/stats', authenticate, transactionController.getTransactionStats);

// Withdrawal routes
router.post('/withdraw', authenticate, withdrawalController.createWithdrawal);
router.get('/withdrawals', authenticate, withdrawalController.getUserWithdrawals);
router.get('/withdrawals/:id', authenticate, withdrawalController.getWithdrawalById);
router.post('/withdrawals/:id/cancel', authenticate, withdrawalController.cancelWithdrawal);

// Sync wallet balance with rate limiting
router.post('/sync-balance', authenticate, async (req, res) => {
    try {
        const userId = req.user.userId;
        const now = Date.now();
        const lastSync = lastSyncTimes.get(userId) || 0;

        // Check if too frequent
        if (now - lastSync < MIN_SYNC_INTERVAL) {
            return res.json({
                success: true,
                message: 'Sync skipped - too frequent'
            });
        }

        // Get new balance from request
        const { balance } = req.body;

        // Sync the balance
        const result = await walletController.syncWalletBalance(userId, balance);

        // Update last sync time
        lastSyncTimes.set(userId, now);

        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        logger.error('Error syncing wallet balance:', error);
        res.status(500).json({
            success: false,
            message: 'Error syncing wallet balance',
            error: error.message
        });
    }
});

// Claim rejected withdrawal transaction
router.post('/transactions/claim', authenticate, async (req, res) => {
    await withdrawalController.claimRejectedTransaction(req, res);
});

// Add this route to support POST /api/transactions/claim
router.use('/transactions', claimCheckRoutes);

// Add this route to support GET /api/market/rates
router.use('/market', marketRatesRoutes); // <-- create this router if not present

module.exports = router;
