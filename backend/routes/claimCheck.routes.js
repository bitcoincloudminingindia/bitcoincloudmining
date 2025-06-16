const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { authenticate } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validator');
const { checkClaimStatus, addClaimTransaction } = require('../controllers/claimCheck.controller');

// Check claim status
router.get('/status', authenticate, checkClaimStatus);

// Add claim transaction
router.post('/claim', authenticate, [
  body('amount').isFloat({ min: 0 }).withMessage('Amount must be a positive number')
], validateRequest, addClaimTransaction);

module.exports = router; 