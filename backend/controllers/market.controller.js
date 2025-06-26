const { getExchangeRate } = require('../utils/exchange');
const axios = require('axios');

// Supported currencies and their symbols
const supportedCurrencies = {
  USD: '$',
  INR: '₹',
  EUR: '€',
  GBP: '£',
  JPY: '¥',
  AUD: 'A$',
  CAD: 'C$'
};

// Fallback rates
const fallbackRates = {
  USD: 1.0,
  INR: 83.0,
  EUR: 0.91,
  GBP: 0.79,
  JPY: 142.50,
  AUD: 1.48,
  CAD: 1.33
};

exports.getRates = async (req, res) => {
  try {
    // Use robust exchange utility for BTC/USD
    const btcPrice = await getExchangeRate('BTC', 'USD');
    // Optionally, fetch other fiat rates as needed
    res.json({
      success: true,
      data: {
        rates: { USD: 1.0, ...fallbackRates },
        btcPrice
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch rates', error: error.message });
  }
};

exports.getMarketRates = async (req, res) => {
  try {
    // Get robust BTC price in USD
    const btcPrice = await getExchangeRate('BTC', 'USD');
    let rates = { ...fallbackRates };

    // Try to fetch latest USD rates
    try {
      const response = await axios.get('https://api.exchangerate-api.com/v4/latest/USD');
      const data = response.data && response.data.rates ? response.data.rates : {};
      Object.keys(supportedCurrencies).forEach((cur) => {
        if (cur !== 'USD' && data[cur]) {
          rates[cur] = data[cur];
        }
      });
    } catch (e) {
      // Use fallback rates if API fails
    }

    res.json({
      success: true,
      data: {
        btcPrice,
        rates
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch market rates',
      error: error.message
    });
  }
};
