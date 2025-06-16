const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const transactionController = require('../controllers/transaction.controller');

// User routes
router.get('/my-transactions', authenticate, (req, res) => transactionController.getUserTransactions(req, res));
router.get('/:id', authenticate, (req, res) => transactionController.getTransaction(req, res));
router.post('/', authenticate, (req, res) => transactionController.createTransaction(req, res));
router.post('/:id/claim', authenticate, (req, res) => transactionController.claimRejectedTransaction(req, res));

// Admin routes
router.get('/', authenticate, (req, res) => transactionController.getAllTransactions(req, res));
router.put('/:id/status', authenticate, (req, res) => transactionController.updateTransactionStatus(req, res));
router.get('/stats', authenticate, (req, res) => transactionController.getTransactionStats(req, res));

module.exports = router; 