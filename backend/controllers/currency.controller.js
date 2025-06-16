const Currency = require('../models/currency.model');
const logger = require('../utils/logger');
const axios = require('axios');
const { validationResult } = require('express-validator');

// Get all currency rates
const getCurrencyRates = async (req, res) => {
  try {
    const rates = await Currency.find();
    res.json({
      success: true,
      data: rates
    });
  } catch (error) {
    logger.error('Get currency rates error:', error);
    res.status(500).json({
      success: false,
      message: 'Error getting currency rates'
    });
  }
};

// Update currency rates from external API
const updateCurrencyRates = async (req, res) => {
  try {
    // Get BTC price in USD from CoinGecko
    const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd,inr');
    const btcUsdRate = response.data.bitcoin.usd;
    const btcInrRate = response.data.bitcoin.inr;

    // Update USD rate
    await Currency.findOneAndUpdate(
      { code: 'USD' },
      { 
        code: 'USD',
        rate: btcUsdRate,
        lastUpdated: new Date()
      },
      { upsert: true }
    );

    // Update INR rate
    await Currency.findOneAndUpdate(
      { code: 'INR' },
      {
        code: 'INR',
        rate: btcInrRate,
        lastUpdated: new Date()
      },
      { upsert: true }
    );

    // Update BTC rate (always 1)
    await Currency.findOneAndUpdate(
      { code: 'BTC' },
      {
        code: 'BTC',
        rate: 1,
        lastUpdated: new Date()
      },
      { upsert: true }
    );

    res.json({
      success: true,
      message: 'Currency rates updated successfully'
    });
  } catch (error) {
    logger.error('Update currency rates error:', error);
    res.status(500).json({
      success: false,
      message: 'Error updating currency rates'
    });
  }
};

const formatBTCAmount = (amount) => {
  return parseFloat(amount).toFixed(18);
};

// Convert amount between currencies
const convertCurrency = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const { amount, fromCurrency, toCurrency } = req.body;

    // Get current rates
    const rates = await Currency.find();
    const ratesMap = rates.reduce((acc, curr) => {
      acc[curr.code] = curr.rate;
      return acc;
    }, {});

    // Convert to BTC first
    let btcAmount = parseFloat(amount);
    if (fromCurrency !== 'BTC') {
      btcAmount = parseFloat(amount) / ratesMap[fromCurrency];
    }
    btcAmount = formatBTCAmount(btcAmount);

    // Convert from BTC to target currency
    let convertedAmount = btcAmount;
    if (toCurrency !== 'BTC') {
      convertedAmount = btcAmount * ratesMap[toCurrency];
    }

    res.json({
      success: true,
      data: {
        amount: parseFloat(amount),
        fromCurrency,
        toCurrency,
        btcAmount: parseFloat(btcAmount),
        convertedAmount: parseFloat(convertedAmount)
      }
    });
  } catch (error) {
    logger.error('Convert currency error:', error);
    res.status(500).json({
      success: false,
      message: 'Error converting currency'
    });
  }
};

module.exports = {
  getCurrencyRates,
  updateCurrencyRates,
  convertCurrency
}; 