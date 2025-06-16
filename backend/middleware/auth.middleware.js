const jwt = require('jsonwebtoken');
const AppError = require('../utils/appError');
const catchAsync = require('../utils/catchAsync');
const User = require('../models/user.model');
const logger = require('../utils/logger');
const config = require('../config/config');

logger.info('Auth middleware module loaded', {
  timestamp: new Date().toISOString()
});

// List of routes that don't require authentication
const publicRoutes = [
  '/register',
  '/login',
  '/check-username',
  '/check-email',
  '/verify-email',
  '/resend-verification',
  '/request-password-reset',
  '/reset-password',
  '/health'
];

// Protect routes
const authenticate = catchAsync(async (req, res, next) => {
  try {
    // Check if route is public
    const isPublicRoute = publicRoutes.some(route => req.path.endsWith(route));
    if (isPublicRoute) {
      return next();
    }

    // Get token from header
    const authHeader = req.headers.authorization;
    logger.info('Auth header:', { authHeader, timestamp: new Date().toISOString() });

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      logger.error('Invalid auth header format:', { authHeader });
      return res.status(401).json({
        success: false,
        message: 'Please log in to access this resource',
        error: 'NO_TOKEN'
      });
    }

    const token = authHeader.split(' ')[1];
    logger.info('Token received:', {
      tokenLength: token.length,
      firstChars: token.substring(0, 10),
      lastChars: token.substring(token.length - 10),
      timestamp: new Date().toISOString()
    });

    // Verify token
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
      logger.error('JWT_SECRET not configured');
      throw new Error('Server configuration error');
    }

    let decoded;
    try {
      // Verify token with explicit algorithm
      decoded = jwt.verify(token, jwtSecret, { algorithms: ['HS256'] });

      // Check minimum required fields (userId is the only mandatory field)
      if (!decoded.userId) {
        logger.error('Token missing userId:', {
          decodedFields: Object.keys(decoded),
          timestamp: new Date().toISOString()
        });
        return res.status(401).json({
          success: false,
          message: 'Invalid token',
          error: 'INVALID_TOKEN'
        });
      }

      logger.info('Token decoded successfully:', {
        decodedFields: Object.keys(decoded),
        userId: decoded.userId,
        id: decoded.id || 'not_present',
        version: decoded.version || 'legacy',
        exp: decoded.exp,
        iat: decoded.iat,
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      logger.error('Token verification failed:', {
        error: err.message,
        token: token.substring(0, 10) + '...',
        timestamp: new Date().toISOString()
      });
      return res.status(401).json({
        success: false,
        message: 'Invalid token',
        error: 'INVALID_TOKEN'
      });
    }

    // Enhanced user lookup with detailed logging
    logger.info('Starting user lookup:', {
      decodedToken: decoded,
      timestamp: new Date().toISOString()
    });

    let user;

    // Primary lookup by userId
    try {
      logger.info('Looking up user by userId:', {
        userId: decoded.userId,
        timestamp: new Date().toISOString()
      });

      user = await User.findOne({ userId: decoded.userId }).select('-password');

      if (!user && decoded.id) {
        logger.info('User not found by userId, trying _id:', {
          id: decoded.id,
          timestamp: new Date().toISOString()
        });
        user = await User.findById(decoded.id).select('-password');
      }

      if (user) {
        logger.info('User found:', {
          userId: user.userId,
          id: user._id,
          timestamp: new Date().toISOString()
        });
      } else {
        logger.error('User not found:', {
          userId: decoded.userId,
          id: decoded.id || 'not_present',
          timestamp: new Date().toISOString()
        });
      }

      if (user) {
        logger.info('User found through lookup:', {
          userId: user.userId,
          id: user._id,
          email: user.userEmail,
          timestamp: new Date().toISOString()
        });
      } else {
        logger.error('User not found through any lookup method:', {
          decodedToken: decoded,
          timestamp: new Date().toISOString()
        });
      }
    } catch (err) {
      logger.error('Error during user lookup:', {
        error: err.message,
        timestamp: new Date().toISOString()
      });
    }

    // Auto-repair: ensure user has both _id and userId
    if (user) {
      let needsSave = false;

      if (!user.userId && decoded.userId) {
        user.userId = decoded.userId;
        needsSave = true;
        logger.info('Adding missing userId to user:', {
          id: user._id,
          userId: decoded.userId,
          timestamp: new Date().toISOString()
        });
      }

      if (needsSave) {
        try {
          await user.save();
          logger.info('Successfully updated user:', {
            id: user._id,
            userId: user.userId,
            timestamp: new Date().toISOString()
          });
        } catch (err) {
          logger.error('Error updating user:', {
            error: err.message,
            id: user._id,
            userId: user.userId,
            timestamp: new Date().toISOString()
          });
        }
      }
    } else {
      logger.error('User not found after all lookup attempts:', {
        decodedToken: decoded,
        timestamp: new Date().toISOString()
      });
    }

    if (user) {
      logger.info('User found:', {
        userId: user.userId,
        role: user.role,
        timestamp: new Date().toISOString()
      });
    } else {
      // If user not found by userId, log the attempted lookup
      logger.error('User lookup failed:', {
        attemptedUserId: decoded.userId,
        decodedToken: decoded,
        timestamp: new Date().toISOString()
      });
    }

    if (!user) {
      logger.error('User not found:', {
        userId: decoded.userId,
        role: decoded.role,
        timestamp: new Date().toISOString()
      });
      return res.status(401).json({
        success: false,
        message: 'Authentication required - User not found',
        error: 'USER_NOT_FOUND'
      });
    }

    // Check if user is active
    if (user.status !== 'active') {
      throw new AppError('User account is inactive', 401);
    }

    // Add user to request
    req.user = user;  // Pass the full Mongoose document
    next();
  } catch (error) {
    logger.error('Auth middleware error:', {
      name: error.name,
      message: error.message,
      stack: error.stack
    });

    // Return JSON responses instead of HTML errors
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        message: 'Invalid token',
        error: 'INVALID_TOKEN'
      });
    } else if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token has expired',
        error: 'TOKEN_EXPIRED'
      });
    } else {
      return res.status(401).json({
        success: false,
        message: 'Authentication failed',
        error: 'AUTH_FAILED'
      });
    }
  }
});

// Restrict to certain roles
exports.restrictTo = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return next(new AppError('You do not have permission to perform this action', 403));
    }
    next();
  };
};

exports.isAdmin = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required'
      });
    }

    if (req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Admin access required'
      });
    }

    next();
  } catch (error) {
    logger.error('Admin check error:', error);
    res.status(500).json({
      success: false,
      message: 'Error checking admin status'
    });
  }
};

module.exports = {
  authenticate
};