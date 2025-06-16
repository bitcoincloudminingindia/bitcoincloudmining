const logger = require('../utils/logger');

exports.adminAuth = async (req, res, next) => {
  try {
    // Check if user exists and is admin
    if (!req.user || !req.user.isAdmin) {
      return res.status(403).json({
        success: false,
        message: 'Admin access required'
      });
    }

    next();
  } catch (error) {
    logger.error('Admin auth middleware error:', error);
    res.status(403).json({
      success: false,
      message: 'Admin authentication failed'
    });
  }
};
