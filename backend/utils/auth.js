const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/user.model');

// Hash password
const hashPassword = async (password) => {
  const salt = await bcrypt.genSalt(10);
  return bcrypt.hash(password, salt);
};

// Compare password
const comparePassword = async (password, hashedPassword) => {
  return bcrypt.compare(password, hashedPassword);
};

// Generate JWT token
const generateToken = (user) => {
  // Validate user object
  if (!user || typeof user !== 'object') {
    throw new Error('Invalid user object provided');
  }

  // Ensure required fields exist
  if (!user._id) {
    throw new Error('User document missing _id field');
  }

  // Ensure we have a valid userId or generate one
  if (!user.userId) {
    user.userId = 'USR' + crypto.randomBytes(6).toString('hex').toUpperCase();
  }

  const payload = {
    id: user._id.toString(), // Convert ObjectId to string
    userId: user.userId,
    role: user.role || 'user', // Default role
    email: user.userEmail, // Include email for additional verification
    version: '1.0' // Add version for future compatibility
  };

  // Log token generation
  console.log('Generating token for user:', {
    userId: user.userId,
    id: user._id.toString(),
    timestamp: new Date().toISOString()
  });

  return jwt.sign(
    payload,
    process.env.JWT_SECRET,
    {
      expiresIn: process.env.JWT_EXPIRES_IN || '1d',
      algorithm: 'HS256' // Explicitly set algorithm
    }
  );
};

// Generate verification token
const generateVerificationToken = () => {
  const token = crypto.randomBytes(32).toString('hex');
  const expires = Date.now() + 24 * 60 * 60 * 1000; // 24 hours
  return { token, expires };
};

// Generate reset password token
const generateResetPasswordToken = () => {
  const token = crypto.randomBytes(32).toString('hex');
  const expires = Date.now() + 1 * 60 * 60 * 1000; // 1 hour
  return { token, expires };
};

// Generate OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Verify JWT token
const verifyToken = (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return decoded;
  } catch (error) {
    throw new Error('Invalid token');
  }
};

module.exports = {
  hashPassword,
  comparePassword,
  generateToken,
  generateVerificationToken,
  generateResetPasswordToken,
  generateOTP,
  verifyToken
}; 