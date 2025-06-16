const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { body } = require('express-validator');
const {
  getCurrencyRates,
  updateCurrencyRates,
  convertCurrency
} = require('../controllers/currency.controller');

// Get all currency rates
router.get('/rates', auth, getCurrencyRates);

// Update currency rates (admin only)
router.post('/update-rates', auth, updateCurrencyRates);

// Convert amount between currencies
router.post('/convert', auth, [
  body('amount').isString().withMessage('Amount must be a string'),
  body('fromCurrency').isIn(['BTC', 'USD', 'INR']).withMessage('Invalid from currency'),
  body('toCurrency').isIn(['BTC', 'USD', 'INR']).withMessage('Invalid to currency')
], convertCurrency);

module.exports = router; 