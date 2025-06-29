const axios = require('axios');
const logger = require('./logger');
const BigNumber = require('bignumber.js');

// Cache for rates
let rateCache = {
  rate: null,
  timestamp: null
};

// Cache duration in milliseconds (5 minutes)
const CACHE_DURATION = 5 * 60 * 1000;

// Retry configuration
const RETRY_CONFIG = {
  maxRetries: 2,
  retryDelay: 1000, // 1 second
  timeout: 8000 // 8 seconds
};

/**
 * Retry function with exponential backoff
 */
async function retryWithBackoff(fn, maxRetries = RETRY_CONFIG.maxRetries) {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      if (attempt === maxRetries) {
        throw error;
      }

      const delay = RETRY_CONFIG.retryDelay * Math.pow(2, attempt);
      logger.warn(`API call failed, retrying in ${delay}ms (attempt ${attempt + 1}/${maxRetries + 1})`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}

/**
 * Get current BTC/USD exchange rate from multiple sources
 * @returns {Promise<BigNumber>} Current BTC/USD rate
 */
async function getBTCUSDRate() {
  try {
    // Check cache first
    if (rateCache.rate && rateCache.timestamp && (Date.now() - rateCache.timestamp < CACHE_DURATION)) {
      logger.info('Using cached BTC/USD rate:', rateCache.rate);
      return rateCache.rate;
    }

    // Fetch rates from multiple sources with individual error handling
    const ratePromises = [
      getCoinGeckoRate().catch(error => {
        logger.error('CoinGecko rate fetch failed:', error.message);
        return null;
      }),
      getBinanceRate().catch(error => {
        logger.error('Binance rate fetch failed:', error.message);
        return null;
      }),
      getKrakenRate().catch(error => {
        logger.error('Kraken rate fetch failed:', error.message);
        return null;
      })
    ];

    const results = await Promise.allSettled(ratePromises);

    const rates = {
      coinGecko: results[0].status === 'fulfilled' ? results[0].value : null,
      binance: results[1].status === 'fulfilled' ? results[1].value : null,
      kraken: results[2].status === 'fulfilled' ? results[2].value : null
    };

    logger.info('BTC/USD Rates:', rates);

    // Calculate average of available rates
    const validRates = Object.values(rates).filter(rate => rate !== null);
    if (validRates.length === 0) {
      logger.warn('No valid rates available, using default rate');
      return '30000.00'; // Default rate if all APIs fail
    }

    const averageRate = validRates.reduce((sum, rate) => sum.plus(new BigNumber(rate)), new BigNumber(0))
      .dividedBy(validRates.length)
      .toFixed(2);

    // Update cache
    rateCache = {
      rate: averageRate,
      timestamp: Date.now()
    };

    return averageRate;
  } catch (error) {
    logger.error('Error getting BTC/USD rate:', error);
    return '30000.00'; // Default rate on error
  }
}

/**
 * Get BTC/USD rate from CoinGecko
 */
async function getCoinGeckoRate() {
  return retryWithBackoff(async () => {
    const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd', {
      timeout: RETRY_CONFIG.timeout,
      headers: {
        'User-Agent': 'BitcoinCloudMining/1.0'
      }
    });
    return response.data.bitcoin.usd.toString();
  });
}

/**
 * Get BTC/USD rate from Binance
 */
async function getBinanceRate() {
  return retryWithBackoff(async () => {
    const response = await axios.get('https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT', {
      timeout: RETRY_CONFIG.timeout,
      headers: {
        'User-Agent': 'BitcoinCloudMining/1.0'
      }
    });
    return response.data.price;
  });
}

/**
 * Get BTC/USD rate from Kraken
 */
async function getKrakenRate() {
  return retryWithBackoff(async () => {
    const response = await axios.get('https://api.kraken.com/0/public/Ticker?pair=XBTUSD', {
      timeout: RETRY_CONFIG.timeout,
      headers: {
        'User-Agent': 'BitcoinCloudMining/1.0'
      }
    });
    return response.data.result.XXBTZUSD.c[0];
  });
}

module.exports = {
  getBTCUSDRate
}; 