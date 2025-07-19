const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const { validationResult } = require('express-validator');
const mongoose = require('mongoose');
const { User, Wallet } = require('../models');
const Referral = require('../models/referral.model');
const logger = require('../utils/logger');
const OTP = require('../models/otp.model');
const emailService = require('../services/email.service');
const ApiError = require('../utils/ApiError');
const crypto = require('crypto');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { generateToken } = require('../utils/auth');
const BigNumber = require('bignumber.js');
const { generateReferralCode } = require('../utils/generators');

const SALT_ROUNDS = 10;

// Generate unique user ID
const generateUserId = () => {
  const timestamp = Date.now().toString();
  const random = crypto.randomBytes(2).toString('hex');
  return `USR${timestamp}${random}`;
};

// Register new user
exports.register = catchAsync(async (req, res, next) => {
  try {
    console.log('Registration request received:', req.body);

    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('Validation errors:', errors.array());
      return res.status(400).json({
        success: false,
        errors: errors.array()
      });
    }

    const {
      fullName,
      userName,
      userEmail,
      password,
      referredByCode,
      installReferralCode
    } = req.body;

    // Generate unique userId
    const userId = generateUserId();
    console.log('🆔 Generated userId:', userId);

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [
        { userEmail: userEmail.toLowerCase() },
        { userName: userName.toLowerCase() }
      ]
    });

    if (existingUser) {
      console.log('User already exists:', existingUser.userName);
      return res.status(400).json({
        success: false,
        message: 'User already exists'
      });
    }

    // Generate referral code for new user
    const userReferralCode = generateReferralCode();
    console.log('🎁 Generated referral code for new user:', userReferralCode);

    // Create user - DO NOT hash password here, let the pre-save middleware handle it
    const user = await User.create({
      fullName,
      userEmail: userEmail.toLowerCase(),
      userName: userName.toLowerCase(),
      password, // Pass plain password, will be hashed by pre-save middleware
      isEmailVerified: false,
      userId,
      userReferralCode,
      status: 'active'
    });

    // Create wallet for user
    const wallet = new Wallet({
      user: user._id, // keep _id for MongoDB relation
      userId: user.userId,
      walletId: 'WAL' + crypto.randomBytes(8).toString('hex').toUpperCase(),
      balance: '0.000000000000000000',
      currency: 'BTC',
      address: 'bc1' + crypto.randomBytes(20).toString('hex').slice(0, 40)
    });

    console.log('📝 Creating wallet:', wallet.toObject());
    await wallet.save();
    console.log('✅ Wallet created successfully');

    // Handle referral code if provided
    if (referredByCode) {
      const referrer = await User.findOne({ referralCode: referredByCode });
      if (referrer && referrer.userId !== user.userId) {
        await Referral.create({
          referrerId: referrer.userId,
          referredId: user.userId,
          referrerCode: referredByCode,
          status: 'active',
          referredUserDetails: {
            username: user.userName,
            email: user.userEmail,
            joinedAt: new Date()
          }
        });
        // Increment referrer's referralCount
        await User.updateOne(
          { userId: referrer.userId },
          { $inc: { referralCount: 1 } }
        );
        // Send notification email to referrer
        try {
          await emailService.sendPromotionalEmail(referrer.userEmail, {
            title: '🎉 Someone used your referral code!',
            content: `${user.userName} just signed up using your referral code. Thank you for spreading the word!`,
            ctaText: 'View Referrals',
            ctaUrl: 'https://your-app-url.com/referrals'
          });
        } catch (e) {
          logger.error('Failed to send referral notification email:', e);
        }
      }
    }

    // Generate token
    const token = generateToken(user);

    res.status(201).json({
      status: 'success',
      data: {
        user: {
          id: user.userId, // use userId instead of _id
          userId: user.userId,
          fullName: user.fullName,
          userName: user.userName,
          userEmail: user.userEmail,
          userReferralCode: user.userReferralCode
        },
        token
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    return res.status(500).json({
      success: false,
      message: 'Error registering user',
      error: error.message
    });
  }
});

// Verify email and complete registration
exports.verifyEmail = catchAsync(async (req, res, next) => {
  const { email, otp } = req.body;
  console.log('🔍 Verifying OTP for email:', email, 'OTP:', otp);

  try {
    // Find user by email
    const user = await User.findOne({ userEmail: email.toLowerCase() });
    if (!user) {
      console.log('❌ User not found for email:', email);
      return res.status(404).json({
        success: false,
        message: 'User not found',
        error: 'USER_NOT_FOUND'
      });
    }

    // Find active OTP
    const otpRecord = await OTP.findOne({
      email: email.toLowerCase(),
      otp: otp,
      type: 'email_verification',
      expiresAt: { $gt: new Date() }
    });

    if (!otpRecord) {
      console.log('❌ Invalid or expired OTP for email:', email);
      return res.status(400).json({
        success: false,
        message: 'Invalid or expired OTP',
        error: 'INVALID_OTP'
      });
    }

    // Mark email as verified
    user.isEmailVerified = true;
    await user.save();

    // Delete the used OTP
    await OTP.deleteOne({ _id: otpRecord._id });

    console.log('✅ Email verified successfully for:', email);
    return res.status(200).json({
      success: true,
      message: 'Email verified successfully',
      data: {
        userId: user.userId,
        email: user.userEmail,
        isEmailVerified: true
      }
    });
  } catch (error) {
    console.error('❌ Error verifying email:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to verify email',
      error: error.message
    });
  }

  // Create user with verified email
  const user = new User({
    ...pendingUser,
    isEmailVerified: true
  });

  await user.save();

  // Create wallet for user
  const wallet = new Wallet({
    user: user._id,
    balance: 0
  });
  await wallet.save();

  // Clear session data
  delete req.session.pendingUser;

  // Generate JWT token
  const token = jwt.sign(
    { id: user._id },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || process.env.JWT_EXPIRE || '30d' }
  );

  res.status(201).json({
    message: 'Registration successful',
    token,
    user: {
      id: user._id,
      fullName: user.fullName,
      username: user.username,
      email: user.userEmail,
      referralCode: user.referralCode
    }
  });
});

// Error handler
const handleError = (res, error, message = 'An error occurred') => {
  console.error('Error:', error);
  res.status(500).json({
    success: false,
    message,
    error: error.message
  });
};

// Login user
exports.login = catchAsync(async (req, res, next) => {
  const { email, password } = req.body;
  console.log('🔑 Login attempt for email:', email);

  try {
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password'
      });
    }

    const user = await User.findOne({ userEmail: email.toLowerCase() })
      .select('+password')
      .exec();

    if (!user) {
      console.log('❌ User not found:', email);
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      console.log('❌ Password mismatch for user:', email);
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials'
      });
    }

    // Update last login
    user.lastLogin = new Date();
    await user.save();

    // Generate token using the auth utility for consistency
    const token = generateToken(user);

    console.log('✅ Login successful:', {
      userId: user.userId,
      timestamp: new Date().toISOString()
    });

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: user._id.toString(),
          userId: user.userId,
          fullName: user.fullName,
          userName: user.userName,
          userEmail: user.userEmail,
          isEmailVerified: user.isEmailVerified,
          role: user.role
        },
        token
      }
    });
  } catch (error) {
    console.error('❌ Login error:', error);
    return res.status(500).json({
      success: false,
      message: 'An error occurred during login'
    });
  }
});

// Get user profile
exports.getProfile = catchAsync(async (req, res, next) => {
  const user = await User.findById(req.user._id).select('-password');

  res.status(200).json({
    status: 'success',
    data: {
      user
    }
  });
});

// Update user profile
exports.updateProfile = catchAsync(async (req, res, next) => {
  const { fullName, userName, userEmail, avatar } = req.body;
  const userId = req.user.userId;

  // Validate required fields
  if (!fullName && !userName && !userEmail && !avatar) {
    return next(new AppError('Please provide at least one field to update', 400));
  }

  // Find user by userId
  const user = await User.findOne({ userId });
  if (!user) {
    return next(new AppError('User not found', 404));
  }

  // Update only provided fields
  if (fullName) user.fullName = fullName;
  if (userName) user.userName = userName.toLowerCase();
  if (userEmail) user.userEmail = userEmail.toLowerCase();
  if (avatar) user.avatar = avatar;

  // Check for unique email/username if being updated
  if (userName || userEmail) {
    const query = {
      userId: { $ne: userId }, // exclude current user
      $or: []
    };
    if (userName) query.$or.push({ userName: userName.toLowerCase() });
    if (userEmail) query.$or.push({ userEmail: userEmail.toLowerCase() });

    const existingUser = await User.findOne(query);
    if (existingUser) {
      return next(new AppError('Username or email already taken', 400));
    }
  }

  await user.save();

  const userResponse = user.toObject();
  delete userResponse.password;

  res.status(200).json({
    success: true,
    message: 'Profile updated successfully',
    data: {
      user: userResponse
    }
  });
});

// Get referred users
exports.getReferredUsers = catchAsync(async (req, res, next) => {
  const userId = req.user._id;

  if (!referral) {
    return next(new AppError('No referral found', 404));
  }

  res.status(200).json({
    status: 'success',
    data: {
      referral
    }
  });
});

// Get referred users
exports.getReferredUsers = catchAsync(async (req, res, next) => {
  const userId = req.user._id;
  const referrals = await Referral.find({ referrer: userId }).populate('referred');

  res.status(200).json({
    status: 'success',
    data: {
      referrals
    }
  });
});

// Get total earnings
exports.getTotalEarnings = catchAsync(async (req, res, next) => {
  const userId = req.user._id;
  const referrals = await Referral.find({ referrer: userId });

  const totalEarnings = referrals.reduce((sum, ref) => sum + (ref.reward || 0), 0);

  res.status(200).json({
    status: 'success',
    data: {
      totalEarnings
    }
  });
});

// Change password
exports.changePassword = catchAsync(async (req, res, next) => {
  const { currentPassword, newPassword } = req.body;
  const userId = req.user._id;

  const user = await User.findById(userId).select('+password');
  if (!user) {
    return next(new AppError('User not found', 404));
  }

  const isPasswordValid = await user.comparePassword(currentPassword);
  if (!isPasswordValid) {
    return next(new AppError('Current password is incorrect', 401));
  }

  user.password = newPassword;
  await user.save();

  res.status(200).json({
    status: 'success',
    message: 'Password changed successfully'
  });
});

// Get wallet info
exports.getWalletInfo = catchAsync(async (req, res, next) => {
  const userId = req.user._id;
  const wallet = await Wallet.findOne({ user: userId });

  if (!wallet) {
    return next(new AppError('Wallet not found', 404));
  }

  res.status(200).json({
    status: 'success',
    data: {
      wallet
    }
  });
});

// Update wallet balance
exports.updateWalletBalance = catchAsync(async (req, res, next) => {
  const { amount } = req.body;
  const userId = req.user._id;

  const wallet = await Wallet.findOne({ user: userId });
  if (!wallet) {
    return next(new AppError('Wallet not found', 404));
  }

  wallet.balance += amount;
  await wallet.save();

  res.status(200).json({
    status: 'success',
    data: {
      wallet
    }
  });
});

// Send verification OTP
exports.sendVerificationOTP = catchAsync(async (req, res, next) => {
  const { email } = req.body;
  console.log('📧 Sending verification OTP for email:', email);

  try {
    const user = await User.findOne({ userEmail: email.toLowerCase() });
    console.log('🔍 Found user:', user);

    if (!user) {
      console.log('❌ User not found for email:', email);
      return res.status(404).json({
        success: false,
        message: 'User not found',
        error: 'USER_NOT_FOUND'
      });
    }

    // Check if user is already verified
    if (user.isEmailVerified) {
      console.log('⚠️ User already verified:', email);
      return res.status(400).json({
        success: false,
        message: 'Email already verified',
        error: 'EMAIL_ALREADY_VERIFIED'
      });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000);

    // Create OTP record first
    const otpRecord = await OTP.create({
      userId: user._id,
      email: email.toLowerCase(),
      otp,
      type: 'email_verification',
      expiresAt: otpExpiry
    });

    // Then try to send email
    try {
      await emailService.sendVerificationEmail(email.toLowerCase(), otp);
      console.log('✅ OTP sent successfully to:', email);

      return res.status(200).json({
        success: true,
        message: 'OTP sent successfully'
      });
    } catch (emailError) {
      // If email fails, delete the OTP record
      await OTP.deleteOne({ _id: otpRecord._id });
      console.error('❌ Email service error:', emailError);

      return res.status(500).json({
        success: false,
        message: 'Failed to send verification email. Please try again later.',
        error: 'EMAIL_SERVICE_ERROR'
      });
    }
  } catch (error) {
    console.error('❌ Error in sendVerificationOTP:', error);
    return res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: 'SERVER_ERROR'
    });
  }
});

// Verify OTP
exports.verifyOtp = catchAsync(async (req, res, next) => {
  const { email, otp } = req.body;
  console.log('🔍 Verifying OTP for email:', email, 'OTP:', otp);

  const user = await User.findOne({ userEmail: email.toLowerCase() });
  if (!user) {
    console.log('❌ User not found for email:', email);
    return next(new AppError('User not found', 404));
  }

  const otpRecord = await OTP.findOne({
    userId: user._id,
    email: email.toLowerCase(),
    otp,
    type: 'email_verification',
    expiresAt: { $gt: new Date() }
  }).sort({ createdAt: -1 }); // Get the most recent OTP

  if (!otpRecord) {
    console.log('❌ Invalid or expired OTP for email:', email);
    return next(new AppError('Invalid or expired OTP', 400));
  }

  // Mark email as verified
  user.isEmailVerified = true;
  await user.save();

  // Mark OTP as used
  otpRecord.used = true;
  await otpRecord.save();

  console.log('✅ Email verified successfully for:', email);
  res.status(200).json({
    status: 'success',
    message: 'Email verified successfully',
    data: {
      userId: user.userId,
      email: user.userEmail,
      isEmailVerified: true
    }
  });
});

// Check if email exists
exports.checkEmail = catchAsync(async (req, res, next) => {
  const { email } = req.body;
  console.log('Checking email availability:', email);

  if (!email) {
    return next(new AppError('Email is required', 400));
  }

  const normalizedEmail = email.toLowerCase();
  const existingUser = await User.findOne({ email: normalizedEmail });

  res.status(200).json({
    status: 'success',
    data: {
      isAvailable: !existingUser,
      message: existingUser ? 'Email is already in use' : 'Email is available'
    }
  });
});

// Request password reset
exports.requestPasswordReset = catchAsync(async (req, res, next) => {
  const { email } = req.body;
  logger.info('🔑 Password reset requested for:', email);

  if (!email) {
    return next(new AppError('Email is required', 400));
  }

  logger.debug('Finding user with query:', { userEmail: email.toLowerCase() });
  const user = await User.findOne({ userEmail: email.toLowerCase() });

  logger.debug('User find result:', user ? 'Found user' : 'No user found');

  if (!user) {
    logger.warn('❌ Password reset requested for non-existent user:', email);
    return res.status(404).json({
      success: false,
      message: 'No account found with this email address'
    });
  }

  // Generate OTP
  const otp = crypto.randomInt(100000, 999999).toString();
  const otpExpiry = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

  logger.debug('Generated OTP:', { otp, expiresAt: otpExpiry });

  // Delete any existing unused OTPs for this user
  await OTP.deleteMany({
    userId: user._id,
    type: 'password_reset',
    used: false
  });

  // Create new OTP
  const otpRecord = await OTP.create({
    userId: user._id,
    email: email.toLowerCase(),
    otp,
    type: 'password_reset',
    expiresAt: otpExpiry
  });

  logger.debug('Created OTP record:', {
    otpId: otpRecord._id,
    userId: otpRecord.userId,
    email: otpRecord.email,
    expiresAt: otpRecord.expiresAt
  });

  try {
    await emailService.sendPasswordResetEmail(email.toLowerCase(), otp);
    logger.info('✅ Password reset OTP sent successfully to:', email);

    res.status(200).json({
      success: true,
      message: 'Password reset OTP has been sent to your email'
    });
  } catch (error) {
    logger.error('❌ Error sending password reset OTP:', error);
    return next(new AppError('Failed to send password reset OTP. Please try again later.', 500));
  }
});

// Reset password
exports.resetPassword = catchAsync(async (req, res, next) => {
  const { resetToken, newPassword } = req.body;
  console.log('🔑 Resetting password with token');

  if (!resetToken || !newPassword) {
    return next(new AppError('Reset token and new password are required', 400));
  }

  // Verify reset token
  let decoded;
  try {
    decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
  } catch (error) {
    return next(new AppError('Invalid or expired reset token', 400));
  }

  const user = await User.findOne({ userEmail: decoded.email.toLowerCase() });
  if (!user) {
    return next(new AppError('User not found', 404));
  }

  // Verify token type
  if (decoded.type !== 'password_reset') {
    return next(new AppError('Invalid token type', 400));
  }

  // Set password directly - will be hashed by pre-save middleware
  user.password = newPassword;
  await user.save();

  console.log('✅ Password reset successful for:', decoded.email);
  res.status(200).json({
    status: 'success',
    message: 'Password reset successful'
  });
});

// Check username
exports.checkUsername = catchAsync(async (req, res, next) => {
  try {
    const { userName } = req.body;

    if (!userName) {
      return res.status(400).json({
        success: false,
        message: 'Username is required'
      });
    }

    const user = await User.findOne({ userName: userName.toLowerCase() });
    if (user) {
      return res.status(200).json({
        success: false,
        message: 'Username already taken'
      });
    }

    return res.status(200).json({
      success: true,
      message: 'Username available'
    });
  } catch (error) {
    logger.error('Check username error:', {
      error: error.message,
      userName: req.body.userName,
      timestamp: new Date().toISOString()
    });
    return res.status(500).json({
      success: false,
      message: 'Error checking username availability'
    });
  }
});

// Health check
exports.healthCheck = catchAsync(async (req, res, next) => {
  res.status(200).json({
    status: 'success',
    message: 'Server is healthy'
  });
});

// Resend OTP
exports.resendOTP = catchAsync(async (req, res, next) => {
  const { email } = req.body;

  const user = await User.findOne({ email });
  if (!user) {
    return next(new AppError('User not found', 404));
  }

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  await OTP.create({
    user: user._id,
    otp,
    type: 'email_verification',
    expiresAt: otpExpiry
  });

  await emailService.sendVerificationEmail(email, otp);

  res.status(200).json({
    status: 'success',
    message: 'OTP resent successfully'
  });
});

// Forgot password
exports.forgotPassword = catchAsync(async (req, res, next) => {
  const { email } = req.body;
  console.log('🔑 Processing forgot password request for email:', email);

  const user = await User.findOne({ email: email.toLowerCase() });
  if (!user) {
    console.log('❌ User not found for email:', email);
    return next(new AppError('User not found', 404));
  }

  // Generate 6-digit OTP
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const otpExpiry = new Date(Date.now() + 5 * 60 * 1000); // 5 minutes

  // Delete any existing OTP for this user
  await OTP.deleteMany({
    userId: user._id,
    type: 'password_reset'
  });

  // Save OTP
  await OTP.create({
    userId: user._id,
    email: email.toLowerCase(),
    otp,
    type: 'password_reset',
    expiresAt: otpExpiry
  });

  try {
    await emailService.sendPasswordResetEmail(email.toLowerCase(), otp);
    console.log('✅ Password reset OTP sent successfully to:', email);
    res.status(200).json({
      status: 'success',
      message: 'Password reset OTP sent successfully'
    });
  } catch (error) {
    console.error('❌ Error sending password reset OTP:', error);
    return next(new AppError('Failed to send password reset OTP', 500));
  }
});

// Resend verification
exports.resendVerification = catchAsync(async (req, res, next) => {
  const { email } = req.body;

  const user = await User.findOne({ email });
  if (!user) {
    return next(new AppError('User not found', 404));
  }

  if (user.isEmailVerified) {
    return next(new AppError('Email already verified', 400));
  }

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

  await OTP.create({
    user: user._id,
    otp,
    type: 'email_verification',
    expiresAt: otpExpiry
  });

  await emailService.sendVerificationEmail(email, otp);

  res.status(200).json({
    status: 'success',
    message: 'Verification OTP resent successfully'
  });
});

// Reset user password
exports.resetUserPassword = catchAsync(async (req, res, next) => {
  const { email, otp, password } = req.body;
  console.log('🔑 Resetting password for email:', email);

  // Find user
  const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
  if (!user) {
    console.log('❌ User not found for email:', email);
    return next(new AppError('User not found', 404));
  }

  // Verify OTP
  const otpRecord = await OTP.findOne({
    userId: user._id,
    email: email.toLowerCase(),
    otp,
    type: 'password_reset',
    expiresAt: { $gt: new Date() }
  });

  if (!otpRecord) {
    console.log('❌ Invalid or expired OTP for email:', email);
    return next(new AppError('Invalid or expired OTP', 400));
  }

  try {
    // Update user password (hashing will be handled by pre-save middleware)
    console.log('🔐 Setting new password');
    user.password = password;
    await user.save();
    console.log('✅ User password updated successfully');

    // Delete used OTP
    await OTP.deleteOne({ _id: otpRecord._id });
    console.log('✅ OTP deleted successfully');

    console.log('✅ Password reset successful for email:', email);

    res.status(200).json({
      status: 'success',
      message: 'Password reset successful'
    });
  } catch (error) {
    console.error('❌ Error resetting password:', error);
    return next(new AppError('Failed to reset password', 500));
  }
});

// Check username availability
const checkUsername = catchAsync(async (req, res) => {
  console.log('📝 Checking username:', req.body);

  const { userName } = req.body;

  if (!userName) {
    console.log('❌ Username missing in request');
    return res.status(400).json({
      success: false,
      isAvailable: false,
      message: 'Username is required'
    });
  }

  // Validate username format
  const usernameRegex = /^[a-zA-Z0-9_]{3,30}$/;
  if (!usernameRegex.test(userName)) {
    console.log('❌ Invalid username format:', userName);
    return res.status(400).json({
      success: false,
      isAvailable: false,
      message: 'Username must be 3-30 characters long and can only contain letters, numbers, and underscores'
    });
  }

  try {
    const existingUser = await User.findOne({ userName: userName.toLowerCase() });
    console.log('🔍 Username check result:', { userName, exists: !!existingUser });

    return res.status(200).json({
      success: true,
      isAvailable: !existingUser,
      message: existingUser ? 'Username is already taken' : 'Username is available'
    });
  } catch (error) {
    console.error('❌ Database error while checking username:', error);
    return res.status(500).json({
      success: false,
      isAvailable: false,
      message: 'Error checking username availability'
    });
  }
});

// Add these new controller functions
exports.validateToken = catchAsync(async (req, res) => {
  res.status(200).json({
    status: 'success',
    message: 'Token is valid',
    user: req.user
  });
});

exports.refreshToken = catchAsync(async (req, res, next) => {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    return next(new AppError('Refresh token is required', 400));
  }

  // Verify refresh token and generate new access token
  const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
  const user = await User.findById(decoded.id);

  if (!user) {
    return next(new AppError('User not found', 404));
  }

  const token = generateToken(user);

  res.status(200).json({
    status: 'success',
    data: { token }
  });
});

exports.verifyResetOtp = catchAsync(async (req, res, next) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return next(new AppError('Email and OTP are required', 400));
  }

  const otpRecord = await OTP.findOne({
    email: email.toLowerCase(),
    otp,
    type: 'password_reset',
    expiresAt: { $gt: new Date() }
  });

  if (!otpRecord) {
    return next(new AppError('Invalid or expired OTP', 400));
  }

  res.status(200).json({
    status: 'success',
    message: 'OTP verified successfully'
  });
});

// Update the exports at the bottom of the file
module.exports = {
  register: exports.register,
  login: exports.login,
  getProfile: exports.getProfile,
  verifyEmail: exports.verifyEmail,
  checkUsername,
  sendVerificationOTP: exports.sendVerificationOTP,
  verifyOtp: exports.verifyOtp,
  forgotPassword: exports.forgotPassword,
  resetPassword: exports.resetPassword,
  changePassword: exports.changePassword,
  updateProfile: exports.updateProfile,
  getWalletInfo: exports.getWalletInfo,
  updateWalletBalance: exports.updateWalletBalance,
  getReferralInfo: exports.getReferralInfo,
  getReferredUsers: exports.getReferredUsers,
  getTotalEarnings: exports.getTotalEarnings,
  healthCheck: exports.healthCheck,
  resendOTP: exports.resendOTP,
  resendVerification: exports.resendVerification,
  resetUserPassword: exports.resetUserPassword,
  checkEmail: exports.checkEmail,
  requestPasswordReset: exports.requestPasswordReset,
  validateToken: exports.validateToken,
  refreshToken: exports.refreshToken,
  verifyResetOtp: exports.verifyResetOtp
};