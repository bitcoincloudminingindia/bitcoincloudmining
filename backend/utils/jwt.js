const jwt = require('jsonwebtoken');
const config = require('../config/config');

const generateToken = (user) => {
  return jwt.sign(
    { userId: user.userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || process.env.JWT_EXPIRE || '30d' }
  );
};

const verifyToken = (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    return decoded;
  } catch (error) {
    throw new Error('Invalid token');
  }
};

module.exports = {
  generateToken,
  verifyToken
}; 