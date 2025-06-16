const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { formatBTCAmounts } = require('../middleware/format.middleware');
const walletController = require('../controllers/wallet.controller');
const transactionController = require('../controllers/transaction.controller');
const { formatBTC, toBigNumber } = require('../utils/format');
const logger = require('../utils/logger');

// Store last sync times for each wallet
const lastSyncTimes = new Map();
const MIN_SYNC_INTERVAL = 5000; // 5 seconds minimum between syncs

// Get wallet balance and info
router.get('/balance', authenticate, async (req, res) => {
    try {
        const wallet = await walletController.getWalletByUserId(req.user.userId);

        // Get all completed transactions
        const transactions = await wallet.transactions || [];

        // Get the current balance
        const balance = wallet.balance || '0.000000000000000000';

        res.json({
            success: true,
            data: {
                balance: formatBTC(balance),
                currency: 'BTC',
                transactions: transactions.map(tx => ({
                    ...tx.toObject(),
                    amount: formatBTC(tx.amount),
                    netAmount: formatBTC(tx.netAmount)
                })),
                balanceHistory: wallet.balanceHistory
            }
        });
    } catch (error) {
        logger.error('Error fetching wallet balance:', error);
        res.status(200).json({
            success: true,
            data: {
                balance: formatBTC('0'),
                currency: 'BTC',
                transactions: [],
                balanceHistory: []
            },
            message: 'Initializing wallet'
        });
    }
});

// Transaction routes
router.post('/transactions', authenticate, formatBTCAmounts, transactionController.createTransaction);
router.get('/transactions', authenticate, transactionController.getUserTransactions);
router.get('/transactions/:id', authenticate, transactionController.getTransactionById);
router.get('/transactions/stats', authenticate, transactionController.getTransactionStats);

// Sync wallet balance with rate limiting
router.post('/sync-balance', authenticate, formatBTCAmounts, async (req, res) => {
    try {
        const userId = req.user.userId;
        const now = Date.now();
        const lastSync = lastSyncTimes.get(userId) || 0;

        // Check if enough time has passed since last sync
        if (now - lastSync < MIN_SYNC_INTERVAL) {
            logger.debug('Skipping sync - too soon since last sync', {
                userId,
                timeSinceLastSync: now - lastSync,
                minInterval: MIN_SYNC_INTERVAL
            });
            return res.json({
                success: true,
                message: 'Sync skipped - too frequent'
            });
        }

        const wallet = await walletController.getWalletByUserId(userId);
        const newBalance = req.body.balance || wallet.balance || '0';

        // Only sync if balance has changed
        const currentBalance = toBigNumber(wallet.balance || '0');
        const updatedBalance = toBigNumber(newBalance);

        if (currentBalance.isEqualTo(updatedBalance)) {
            logger.debug('Skipping sync - no balance change', {
                userId,
                currentBalance: formatBTC(currentBalance.toString())
            });
            return res.json({
                success: true,
                message: 'Sync skipped - no change'
            });
        }

        // Update balance with type 'balance_sync'
        await walletController.updateWalletBalance(
            wallet,
            newBalance,
            'balance_sync'
        );

        // Update last sync time
        lastSyncTimes.set(userId, now);

        // Return updated wallet info
        const walletInfo = await walletController.getWalletInfo(userId);

        res.json({
            success: true,
            data: walletInfo
        });
    } catch (error) {
        logger.error('Error syncing wallet balance:', error);
        res.status(500).json({
            success: false,
            message: 'Error syncing wallet balance'
        });
    }
});

// Sync wallet balance
router.post('/sync-balance', authenticate, async (req, res) => {
    try {
        const { userId } = req.user;

        // Check if we need to throttle syncs
        const lastSync = lastSyncTimes.get(userId);
        const now = Date.now();
        if (lastSync && now - lastSync < MIN_SYNC_INTERVAL) {
            return res.json({
                success: true,
                message: 'Balance sync throttled'
            });
        }

        // Update last sync time
        lastSyncTimes.set(userId, now);

        // Get wallet and transactions
        const wallet = await walletController.getWalletByUserId(userId);
        const Transaction = require('../models/transaction.model');
        const transactions = await Transaction.find({
            userId,
            status: 'completed'
        }).sort({ timestamp: 1 });

        // Import balance utilities
        const { updateWalletBalance } = require('../utils/balance');

        // Update the wallet balance
        const newBalance = await updateWalletBalance(wallet, transactions);

        res.json({
            success: true,
            data: {
                balance: formatBTC(newBalance),
                updatedAt: new Date()
            }
        });
    } catch (error) {
        logger.error('Error syncing wallet balance:', error);
        res.status(500).json({
            success: false,
            message: 'Error syncing balance'
        });
    }
});

module.exports = router;
