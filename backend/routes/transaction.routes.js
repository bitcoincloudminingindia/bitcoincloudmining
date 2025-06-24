const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const transactionController = require('../controllers/transaction.controller');
const logger = require('../utils/logger');

// Debug route
router.get('/debug/test', (req, res) => {
    logger.info('Debug route accessed');
    res.json({ message: 'Transaction routes are working' });
});

// Claim route - handle both /claim and root path for the claim endpoint
router.post(['/', '/claim'], authenticate, (req, res) => {
    logger.info('Claim route accessed', {
        body: req.body,
        path: req.path,
        baseUrl: req.baseUrl
    });
    return transactionController.claimRejectedTransaction(req, res);
});

// User routes
router.get('/my-transactions', authenticate, (req, res) => transactionController.getUserTransactions(req, res));
router.post('/', authenticate, (req, res) => transactionController.createTransaction(req, res));

// These routes must come after /claim to avoid shadowing
router.get('/:id', authenticate, (req, res) => transactionController.getTransaction(req, res));
router.put('/:id/status', authenticate, (req, res) => transactionController.updateTransactionStatus(req, res));

// Admin routes
router.get('/stats', authenticate, (req, res) => transactionController.getTransactionStats(req, res));

module.exports = router;