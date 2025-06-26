const fetch = require('node-fetch');
const axios = require('axios');
const { getBTCPrice } = require('../services/price.service');

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

// Simple in-memory cache for CoinGecko rates
let cachedRates = null;
let cacheTimestamp = 0;
const CACHE_DURATION_MS = 2 * 60 * 1000; // 2 minutes

exports.getRates = async (req, res) => {
  try {
    const now = Date.now();
    if (cachedRates && (now - cacheTimestamp) < CACHE_DURATION_MS) {
      return res.json({ success: true, data: cachedRates });
    }
    const url = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd,inr,eur,gbp,jpy,aud,cad,sgd,chf,cny,rub,brl,zar';
    const response = await fetch(url);
    const data = await response.json();

    const rates = {
      USD: data.bitcoin.usd,
      INR: data.bitcoin.inr,
      EUR: data.bitcoin.eur,
      GBP: data.bitcoin.gbp,
      JPY: data.bitcoin.jpy,
      AUD: data.bitcoin.aud,
      CAD: data.bitcoin.cad,
      SGD: data.bitcoin.sgd,
      CHF: data.bitcoin.chf,
      CNY: data.bitcoin.cny,
      RUB: data.bitcoin.rub,
      BRL: data.bitcoin.brl,
      ZAR: data.bitcoin.zar
    };
    cachedRates = { rates, btcPrice: rates.USD };
    cacheTimestamp = now;
    res.json({ success: true, data: cachedRates });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch rates' });
  }
};

exports.getMarketRates = async (req, res) => {
  try {
    // Get BTC price in USD
    const btcPrice = await getBTCPrice();
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
