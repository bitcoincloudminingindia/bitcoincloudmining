const express = require('express');
const router = express.Router();

// Example handler for GET /api/market/rates
router.get('/rates', async (req, res) => {
    // Replace with your actual logic to fetch rates
    res.json({
        success: true,
        data: {
            rates: {
                USD: 1.0,
                EUR: 0.91,
                INR: 83.0
            },
            btcPrice: 65000 // Example BTC price
        }
    });
});

module.exports = router;
