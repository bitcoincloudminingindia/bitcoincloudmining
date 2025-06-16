const jwt = require('jsonwebtoken');
const User = require('../models/user.model');
const logger = require('../utils/logger');

const adminAuth = async (req, res, next) => {
  try {
    // Check if user exists in request (set by auth middleware)
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    // Check if user is admin
    if (!req.user.isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Admin access required'
      });
    }

    next();
  } catch (error) {
    logger.error('Admin auth middleware error:', error);
    res.status(401).json({
      success: false,
      message: 'Admin authentication failed'
    });
  }
};

module.exports = adminAuth; 