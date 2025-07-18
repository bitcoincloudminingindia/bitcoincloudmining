const express = require('express');
const axios = require('axios');
const router = express.Router();

router.get('/', async (req, res) => {
    const { url } = req.query;
    if (!url) return res.status(400).send('No url');
    try {
        const response = await axios.get(url, {
            responseType: 'arraybuffer',
            headers: { 'User-Agent': 'Mozilla/5.0' }
        });
        res.set('Content-Type', response.headers['content-type']);
        res.send(response.data);
    } catch (e) {
        res.status(500).send('Image fetch error');
    }
});

module.exports = router; 