const express = require('express');
const router = express.Router();
const marketController = require('../controllers/market.controller');

// GET /api/market/rates
router.get('/rates', marketController.getMarketRates);

module.exports = router;
