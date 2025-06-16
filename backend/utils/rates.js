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

    // Fetch rates from multiple sources
    const [coinGeckoRate, binanceRate, krakenRate] = await Promise.allSettled([
      getCoinGeckoRate(),
      getBinanceRate(),
      getKrakenRate()
    ]);

    const rates = {
      coinGecko: coinGeckoRate.status === 'fulfilled' ? coinGeckoRate.value : null,
      binance: binanceRate.status === 'fulfilled' ? binanceRate.value : null,
      kraken: krakenRate.status === 'fulfilled' ? krakenRate.value : null
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
  try {
    const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd');
    return response.data.bitcoin.usd.toString();
  } catch (error) {
    logger.error('Error fetching CoinGecko rate:', error);
    return null;
  }
}

/**
 * Get BTC/USD rate from Binance
 */
async function getBinanceRate() {
  try {
    const response = await axios.get('https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT');
    return response.data.price;
  } catch (error) {
    logger.error('Error fetching Binance rate:', error);
    return null;
  }
}

/**
 * Get BTC/USD rate from Kraken
 */
async function getKrakenRate() {
  try {
    const response = await axios.get('https://api.kraken.com/0/public/Ticker?pair=XBTUSD', {
      timeout: 5000 // 5 second timeout
    });
    return response.data.result.XXBTZUSD.c[0];
  } catch (error) {
    logger.error('Error fetching Kraken rate:', error);
    return null;
  }
}

module.exports = {
  getBTCUSDRate
}; 