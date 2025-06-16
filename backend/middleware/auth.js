const { verifyToken } = require('../utils/jwt');
const User = require('../models/user.model');
const ApiError = require('../utils/ApiError');
const logger = require('../utils/logger');

const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    
    // Check if authorization header exists
    if (!authHeader) {
      logger.error('No authorization header found');
      return res.status(401).json({
        success: false,
        message: 'Authentication required - No token provided'
      });
    }

    // Check if token format is correct
    if (!authHeader.startsWith('Bearer ')) {
      logger.error('Invalid token format');
      return res.status(401).json({
        success: false,
        message: 'Authentication required - Invalid token format'
      });
    }

    const token = authHeader.split(' ')[1];
    
    try {
      const decoded = verifyToken(token);
      
      // Check if user exists
      const user = await User.findById(decoded.id);
      if (!user) {
        logger.error('User not found for token:', { userId: decoded.id });
        return res.status(401).json({
          success: false,
          message: 'Authentication required - User not found'
        });
      }

      // Attach user to request
      req.user = user;
      next();
    } catch (tokenError) {
      logger.error('Token verification failed:', tokenError);
      return res.status(401).json({
        success: false,
        message: 'Authentication required - Invalid token'
      });
    }
  } catch (error) {
    logger.error('Authentication error:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error during authentication'
    });
  }
};

const authorize = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (!roles.includes(req.user.role)) {
      logger.error('Access denied for user:', { 
        userId: req.user._id,
        role: req.user.role,
        requiredRoles: roles
      });
      return res.status(403).json({
        success: false,
        message: 'Access denied - Insufficient permissions'
      });
    }
    next();
  };
};

module.exports = {
  authenticate,
  authorize
};

