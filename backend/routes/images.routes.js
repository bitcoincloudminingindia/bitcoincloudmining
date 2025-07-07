const express = require('express');
const fs = require('fs');
const path = require('path');
const router = express.Router();

// GET /api/images - List all images in public folder
router.get('/', (req, res) => {
    const publicDir = path.join(__dirname, '../public');
    fs.readdir(publicDir, (err, files) => {
        if (err) {
            return res.status(500).json({ error: 'Unable to list images' });
        }
        // Filter only image files (jpg, png, jpeg)
        const imageFiles = files.filter(f => /\.(jpg|jpeg|png)$/i.test(f));
        const baseUrl = req.protocol + '://' + req.get('host') + '/public/';
        const imageUrls = imageFiles.map(f => baseUrl + encodeURIComponent(f));
        res.json({ images: imageUrls });
    });
});

module.exports = router; 