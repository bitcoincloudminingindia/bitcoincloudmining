const User = require('../models/user.model');
const Wallet = require('../models/wallet.model');
const { sendWelcomeEmail } = require('../services/email.service');
const Referral = require('../models/referral.model');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { generateReferralCode } = require('../utils/generators');
const crypto = require('crypto');
const catchAsync = require('../utils/catchAsync');
const AppError = require('../utils/appError');
const { sendPushToUser } = require('../utils/fcm');

// Register user
exports.register = async (req, res) => {
  try {
    const { username, email, password, fullName } = req.body;

    // Check if user already exists
    let user = await User.findOne({ $or: [{ email }, { username }] });
    if (user) {
      return res.status(400).json({ message: 'User already exists' });
    }

    // Create new user
    user = new User({
      username,
      email,
      password,
      fullName,
      referralCode: generateReferralCode()
    });

    // Hash password
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(password, salt);

    // Save user
    await user.save();

    // Create wallet
    const wallet = new Wallet({
      user: user._id,
      currency: 'BTC',
      balance: 0,
      availableBalance: 0,
      exchangeRate: 1
    });
    await wallet.save();

    // Send welcome email
    await sendWelcomeEmail(user.email, user.username);

    // Generate JWT
    const payload = {
      user: {
        id: user.id
      }
    };

    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '24h' },
      (err, token) => {
        if (err) throw err;
        res.json({ token });
      }
    );
  } catch (error) {
    console.error('Error in register:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Login user
exports.login = catchAsync(async (req, res, next) => {
  const { email, password } = req.body;
  console.log('🔑 Login attempt for email:', { timestamp: new Date().toISOString() });

  // Find user with password
  const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
  if (!user) {
    console.log('❌ User not found for email:', { timestamp: new Date().toISOString() });
    return next(new AppError('User not found', 404));
  }

  // Check if user has password
  if (!user.password) {
    console.log('❌ No password set for user:', { email, timestamp: new Date().toISOString() });
    return next(new AppError('Please set your password first', 401));
  }

  // Compare password using model method
  console.log('🔐 Comparing passwords', { timestamp: new Date().toISOString() });
  const isPasswordValid = await user.comparePassword(password);
  console.log('✅ Password match result:', { timestamp: new Date().toISOString() });

  if (!isPasswordValid) {
    return next(new AppError('Invalid password', 401));
  }

  // Generate token
  const token = jwt.sign(
    { id: user._id },
    process.env.JWT_SECRET,
    { expiresIn: '24h' }
  );

  // Update last login
  user.lastLogin = new Date();
  await user.save();

  console.log('✅ Login successful for email:', { timestamp: new Date().toISOString() });

  res.status(200).json({
    success: true,
    message: 'Login successful',
    data: {
      token,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        username: user.username,
        role: user.role,
        isVerified: user.isEmailVerified,
        referralCode: user.referralCode,
        referralStats: user.referralStats,
        miningStatus: user.miningStatus,
        wallet: user.wallet
      }
    }
  });
});

// Forgot password
exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;

    // Check if user exists
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'User not found' });
    }

    // Generate reset token
    const resetToken = crypto.randomBytes(32).toString('hex');
    user.resetPasswordToken = resetToken;
    user.resetPasswordExpires = Date.now() + 3600000; // 1 hour
    await user.save();

    // Send reset email
    await sendResetPasswordEmail(user.email, resetToken);

    res.json({ message: 'Password reset email sent' });
  } catch (error) {
    console.error('Error in forgotPassword:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Reset password
exports.resetPassword = async (req, res) => {
  try {
    const { token, password } = req.body;

    // Find user by reset token
    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired token' });
    }

    // Hash new password
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(password, salt);
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();

    res.json({ message: 'Password reset successful' });
  } catch (error) {
    console.error('Error in resetPassword:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Verify email
exports.verifyEmail = catchAsync(async (req, res) => {
  const { token } = req.body;
  const user = await User.findOne({
    emailVerificationToken: token,
    emailVerificationExpires: { $gt: Date.now() }
  });

  if (!user) {
    throw new AppError('Invalid or expired token', 400);
  }

  user.isEmailVerified = true;
  user.emailVerificationToken = undefined;
  user.emailVerificationExpires = undefined;
  await user.save();

  res.status(200).json({
    status: 'success',
    message: 'Email verified successfully'
  });
});

// Resend verification
exports.resendVerification = async (req, res) => {
  try {
    const { email } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ message: 'User not found' });
    }

    if (user.emailVerified) {
      return res.status(400).json({ message: 'Email already verified' });
    }

    // Generate new verification token
    const verificationToken = crypto.randomBytes(32).toString('hex');
    user.verificationToken = verificationToken;
    user.verificationExpires = Date.now() + 3600000; // 1 hour
    await user.save();

    // Send verification email
    await sendVerificationEmail(user.email, verificationToken);

    res.json({ message: 'Verification email sent' });
  } catch (error) {
    console.error('Error in resendVerification:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Get user profile
exports.getProfile = catchAsync(async (req, res) => {
  const user = await User.findById(req.user._id).select('-password');
  if (!user) {
    throw new AppError('User not found', 404);
  }
  res.status(200).json({
    status: 'success',
    data: { user }
  });
});

// Update user profile
exports.updateProfile = catchAsync(async (req, res) => {
  const { fullName } = req.body;

  const user = await User.findByIdAndUpdate(
    req.user._id,
    { fullName },
    { new: true, runValidators: true }
  );

  if (!user) {
    throw new AppError('User not found', 404);
  }

  res.status(200).json({
    status: 'success',
    data: {
      user
    }
  });
});

// Get user wallet
exports.getWallet = catchAsync(async (req, res) => {
  const wallet = await Wallet.findOne({ user: req.user._id });
  if (!wallet) {
    throw new AppError('Wallet not found', 404);
  }

  res.status(200).json({
    status: 'success',
    data: { wallet }
  });
});

// Get user referrals
exports.getReferrals = async (req, res) => {
  try {
    const referrals = await Referral.find({ referrer: req.user.id })
      .populate('referred', 'fullName username email');
    res.json(referrals);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

// Get user transactions
exports.getTransactions = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ user: req.user.id });
    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }
    res.json(wallet.transactions);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

// Get referral info
exports.getReferralInfo = catchAsync(async (req, res) => {
  const user = await User.findById(req.user._id);
  const referral = await Referral.findOne({ referred: req.user._id });

  res.status(200).json({
    status: 'success',
    data: {
      referralCode: user.referralCode,
      referredBy: referral ? referral.referrer : null
    }
  });
});

// Get referred users
exports.getReferredUsers = catchAsync(async (req, res) => {
  const referrals = await Referral.find({ referrer: req.user._id })
    .populate('referred', 'username email fullName');

  res.status(200).json({
    status: 'success',
    data: { referrals }
  });
});

// Get total earnings
exports.getTotalEarnings = catchAsync(async (req, res) => {
  const referrals = await Referral.find({ referrer: req.user._id });
  const totalEarnings = referrals.reduce((sum, ref) => sum + ref.earnings, 0);

  const wallet = await Wallet.findOne({ user: req.user._id });

  res.status(200).json({
    status: 'success',
    data: {
      totalEarnings,
      walletBalance: wallet ? wallet.balance : 0
    }
  });
});

// Get mining stats
exports.getMiningStats = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ user: req.user.id });
    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }
    res.json(wallet.miningStats);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

// Get rewards
exports.getRewards = async (req, res) => {
  try {
    const wallet = await Wallet.findOne({ user: req.user.id });
    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }
    res.json(wallet.rewards);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

// Claim reward
exports.claimReward = async (req, res) => {
  try {
    const { rewardId } = req.body;
    const wallet = await Wallet.findOne({ user: req.user.id });
    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }

    const reward = wallet.rewards.id(rewardId);
    if (!reward) {
      return res.status(404).json({ message: 'Reward not found' });
    }

    if (reward.claimed) {
      return res.status(400).json({ message: 'Reward already claimed' });
    }

    reward.claimed = true;
    reward.claimedAt = new Date();
    await wallet.save();

    res.json(reward);
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

// Change password
exports.changePassword = catchAsync(async (req, res) => {
  const { currentPassword, newPassword } = req.body;
  const user = await User.findById(req.user._id).select('+password');

  const isPasswordValid = await user.comparePassword(currentPassword);
  if (!isPasswordValid) {
    throw new AppError('Current password is incorrect', 401);
  }

  user.password = newPassword;
  await user.save();

  res.status(200).json({
    status: 'success',
    message: 'Password updated successfully'
  });
});

// Update wallet
exports.updateWallet = catchAsync(async (req, res) => {
  const { currency, address } = req.body;
  const wallet = await Wallet.findOneAndUpdate(
    { user: req.user._id },
    { currency, address },
    { new: true, runValidators: true }
  );

  res.status(200).json({
    status: 'success',
    data: { wallet }
  });
});

// Update FCM token for the authenticated user
exports.updateFcmToken = async (req, res) => {
  try {
    const userId = req.user._id;
    const { fcmToken } = req.body;
    if (!fcmToken) {
      return res.status(400).json({ message: 'FCM token is required' });
    }
    const user = await User.findByIdAndUpdate(userId, { fcmToken }, { new: true });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    return res.status(200).json({ message: 'FCM token updated successfully' });
  } catch (error) {
    return res.status(500).json({ message: 'Failed to update FCM token', error: error.message });
  }
};

// Example: Send a test push notification to the authenticated user
exports.sendTestNotification = async (req, res) => {
  try {
    const userId = req.user._id;
    await sendPushToUser(userId, {
      title: 'Test Notification',
      body: 'This is a test push notification!',
      data: { customKey: 'customValue' }
    });
    res.status(200).json({ message: 'Notification sent' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to send notification', error: error.message });
  }
};