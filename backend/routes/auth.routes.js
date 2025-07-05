const express = require('express');
const router = express.Router();
const { registerValidation, loginValidation } = require('../middleware/validators');
const { validateRequest } = require('../middleware/validate-request');
const { User } = require('../models');
const OTP = require('../models/otp.model');
const jwt = require('jsonwebtoken');
const {
  register,
  login,
  getProfile,
  verifyEmail,
  checkUsername,
  sendVerificationOTP,
  resendVerification,
  requestPasswordReset,
  resetPassword,
  checkEmail,
  validateToken,
  refreshToken,
  profile,
  userProfile,
  updateProfile,
  changePassword,
  verifyResetOtp
} = require('../controllers/auth.controller');
const { googleSignIn, linkGoogleAccount } = require('../controllers/google_auth.controller');
const { authenticate } = require('../middleware/auth.middleware');

// Health check route
router.get('/health', (req, res) => {
  res.json({ status: 'ok', message: 'Server is running' });
});

// Public routes (no authentication required)
router.post('/check-username', checkUsername);
router.post('/check-email', checkEmail);
router.post('/register', registerValidation, validateRequest, register);
router.post('/login', loginValidation, validateRequest, login);
router.post('/verify-email', verifyEmail);
router.post('/resend-verification', resendVerification);
router.post('/request-password-reset', requestPasswordReset);
router.post('/reset-password', resetPassword);
router.post('/validate-token', validateToken);

// Protected routes (require authentication)
router.get('/profile', authenticate, getProfile);

// FCM Token endpoint
router.post('/fcm-token', authenticate, async (req, res) => {
  try {
    const userId = req.user._id;
    const { fcmToken } = req.body;

    if (!fcmToken) {
      return res.status(400).json({
        success: false,
        message: 'FCM token is required'
      });
    }

    const user = await User.findByIdAndUpdate(
      userId,
      { fcmToken },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'FCM token updated successfully'
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Failed to update FCM token',
      error: error.message
    });
  }
});

// Send verification OTP
router.post('/send-verification-otp', sendVerificationOTP);

// Password reset flow
router.post('/request-reset', requestPasswordReset);
router.post('/verify-reset-otp', async (req, res) => {
  try {
    const { email, otp } = req.body;
    console.log('🔍 Verifying reset OTP:', { email, otp });

    if (!email || !otp) {
      console.log('❌ Missing email or OTP');
      return res.status(400).json({
        success: false,
        message: 'Email and OTP are required'
      });
    }

    // First find the user to get their ID
    const user = await User.findOne({ userEmail: email.toLowerCase() });
    if (!user) {
      console.log('❌ User not found');
      return res.status(400).json({
        success: false,
        message: 'Invalid email or OTP'
      });
    }

    // Find the valid OTP with user ID
    console.log('🔍 Looking for OTP record...', {
      userId: user._id,
      email: email.toLowerCase(),
      otp,
      type: 'password_reset'
    });

    const validOTP = await OTP.findOne({
      userId: user._id,
      email: email.toLowerCase(),
      otp,
      type: 'password_reset',
      expiresAt: { $gt: new Date() },
      used: false
    });

    console.log('🔍 OTP search result:', validOTP ? 'Found' : 'Not found');

    if (!validOTP) {
      console.log('❌ Invalid or expired OTP');
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP'
      });
    }

    // Mark OTP as used
    console.log('✅ Marking OTP as used');
    validOTP.used = true;
    await validOTP.save();

    // Generate a short-lived reset token
    const resetToken = jwt.sign(
      { email: email.toLowerCase(), type: 'password_reset' },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );

    res.json({
      success: true,
      message: 'OTP verified successfully',
      resetToken
    });
  } catch (error) {
    console.error('Error verifying reset OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify OTP'
    });
  }
});
router.post('/reset-password', resetPassword);
router.post('/request-password-reset', requestPasswordReset); // Keep old route for backward compatibility

// Google authentication routes
router.post('/google', googleSignIn);
router.post('/google-signin', googleSignIn); // Add this new route for frontend compatibility
router.post('/google/link', authenticate, linkGoogleAccount);

// Add catch-all route handler
router.all('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.originalUrl} not found`
  });
});

// Error handling middleware
router.use((err, req, res, next) => {
  console.error('Route error:', err);
  // Ensure we use a valid HTTP status code
  const statusCode = (err.statusCode || err.status || 500);
  res.status(typeof statusCode === 'number' ? statusCode : 500).json({
    success: false,
    message: err.message || 'Internal server error'
  });
});

module.exports = router;
