const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');

// Subscribe to notifications
router.post('/subscribe', auth, async (req, res) => {
  try {
    const { type, enabled } = req.body;
    const userId = req.user.id;

    // Here you would typically update user's notification preferences in the database
    // For now, we'll just send a success response
    res.json({
      success: true,
      message: 'Notification preferences updated',
      data: { type, enabled }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to update notification preferences'
    });
  }
});

module.exports = router; 