const axios = require('axios');
const logger = require('../utils/logger');
const { getExchangeRate } = require('../utils/exchange');

// Deprecated: Use getExchangeRate('BTC', 'USD') instead
const getBTCPrice = async () => {
  return getExchangeRate('BTC', 'USD');
};

const getETHPrice = async () => {
  try {
    const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=ethereum&vs_currencies=usd');
    return response.data.ethereum.usd;
  } catch (error) {
    logger.error('Error fetching ETH price:', error);
    throw new Error('Failed to fetch ETH price');
  }
};

const getUSDTPrice = async () => {
  try {
    const response = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=tether&vs_currencies=usd');
    return response.data.tether.usd;
  } catch (error) {
    logger.error('Error fetching USDT price:', error);
    throw new Error('Failed to fetch USDT price');
  }
};

module.exports = {
  getBTCPrice,
  getETHPrice,
  getUSDTPrice
};