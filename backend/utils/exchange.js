const axios = require('axios');
const { getBTCUSDRate } = require('./rates');

// Cache exchange rates for 5 minutes
const exchangeRates = new Map();
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes in milliseconds
const DEFAULT_BTC_RATE = 30000; // Default BTC/USD rate

/**
 * Get exchange rate for a currency pair
 * @param {string} fromCurrency - The source currency (e.g., 'BTC')
 * @param {string} toCurrency - The target currency (e.g., 'USD')
 * @returns {Promise<number>} The exchange rate
 */
exports.getExchangeRate = async (fromCurrency, toCurrency = 'USD') => {
  if (!fromCurrency) {
    throw new Error('Source currency is required');
  }

  const cacheKey = `${fromCurrency}_${toCurrency}`;
  const now = Date.now();

  // Check cache
  const cached = exchangeRates.get(cacheKey);
  if (cached && (now - cached.timestamp < CACHE_DURATION)) {
    return cached.rate;
  }

  try {
    let rate;

    if (fromCurrency === toCurrency) {
      rate = 1;
    } else if (fromCurrency === 'BTC' && toCurrency === 'USD') {
      try {
        // Use robust multi-source rate from rates.js
        rate = await getBTCUSDRate();
        rate = Number(rate);
      } catch (error) {
        console.warn('Failed to fetch BTC rate from rates.js, using default:', error.message);
        rate = DEFAULT_BTC_RATE;
      }
    } else if (fromCurrency === 'USD' && toCurrency === 'INR') {
      // USD to INR rate from CoinGecko
      try {
        const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=usd&vs_currencies=inr');
        rate = response.data.usd.inr;
      } catch (error) {
        console.warn('Failed to fetch USD/INR rate, using fallback 83');
        rate = 83; // fallback
      }
    } else {
      throw new Error(`Unsupported currency pair: ${fromCurrency}/${toCurrency}`);
    }

    // Cache the new rate
    exchangeRates.set(cacheKey, {
      rate,
      timestamp: now
    });

    return rate;
  } catch (error) {
    console.error('Error fetching exchange rate:', error);

    // For BTC/USD, use default rate if not in cache
    if (fromCurrency === 'BTC' && toCurrency === 'USD') {
      return DEFAULT_BTC_RATE;
    }
    if (fromCurrency === 'USD' && toCurrency === 'INR') {
      return 83;
    }

    // For other pairs, throw error
    throw new Error(`Failed to get exchange rate for ${fromCurrency}/${toCurrency}: ${error.message}`);
  }
};

// Export BTC rate constants
exports.DEFAULT_BTC_RATE = DEFAULT_BTC_RATE;

// Convert amount between currencies
exports.convertAmount = async (amount, fromCurrency, toCurrency) => {
  if (fromCurrency === toCurrency) {
    return amount;
  }

  const fromRate = await exports.getExchangeRate(fromCurrency);
  const toRate = await exports.getExchangeRate(toCurrency);

  if (fromCurrency === 'BTC') {
    // Convert from BTC to target currency
    return amount * toRate;
  } else {
    // Convert from source currency to BTC
    return amount / fromRate;
  }
};