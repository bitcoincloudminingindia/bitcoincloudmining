const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { Schema } = require('mongoose');
const BigNumber = require('bignumber.js');
const jwt = require('jsonwebtoken');
// We'll get Wallet model via mongoose.model('Wallet') where needed
const { generateReferralCode } = require('../utils/generators');

// Indexes are managed in config/database.js

const userSchema = new mongoose.Schema({
  userId: {
    type: String,
    unique: true,
    required: [true, 'User ID is required']
  },
  firebaseUid: {
    type: String,
    unique: true,
    sparse: true // Allow multiple null values
  },
  fullName: {
    type: String,
    required: [true, 'Full name is required'],
    trim: true,
    minlength: [2, 'Full name must be at least 2 characters long'],
    maxlength: [50, 'Full name cannot exceed 50 characters']
  },
  userEmail: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    trim: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  userName: {
    type: String,
    required: [true, 'Username is required'],
    unique: true,
    trim: true,
    minlength: [3, 'Username must be at least 3 characters long'],
    maxlength: [20, 'Username cannot be more than 20 characters'],
    match: [/^[a-zA-Z0-9_]+$/, 'Username can only contain letters, numbers and underscores']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters long'],
    select: false
  },
  otp: String,
  otpExpires: Date,
  isVerified: {
    type: Boolean,
    default: false
  },
  verificationToken: String,
  verificationTokenExpires: Date,
  resetPasswordToken: String,
  resetPasswordExpires: Date,
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  },
  lastLogin: {
    type: Date,
    default: null
  },
  profilePicture: {
    type: String,
    default: null
  },
  avatar: {
    type: String,
    trim: true,
    default: null,
    validate: {
      validator: function (v) {
        return !v || v.length <= 1000; // URL or base64 image should be reasonable length
      },
      message: 'Avatar URL or data is too long'
    }
  },
  referredByCode: {
    type: String,
    trim: true
  },
  referralCode: {
    type: String,
    // unique: true, // Removed to avoid duplicate index
  },
  referredBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  referralCount: {
    type: Number,
    default: 0
  },
  wallet: {
    balance: {
      type: String,
      default: '0.000000000000000000',
      get: v => v.toString(),
      set: v => v.toString()
    },
    pendingBalance: {
      type: String,
      default: '0.000000000000000000',
      get: v => v.toString(),
      set: v => v.toString()
    },
    currency: {
      type: String,
      enum: ['BTC', 'INR', 'USD'],
      default: 'BTC'
    },
    transactions: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Transaction'
    }],
    address: String,
    lastUpdated: {
      type: Date,
      default: Date.now
    }
  },
  totalRewardsClaimed: {
    type: String,
    default: '0.000000000000000000'
  },
  todayRewardsClaimed: {
    type: String,
    default: '0.000000000000000000'
  },
  lastRewardClaimDate: {
    type: Date
  },
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  emailVerificationToken: String,
  emailVerificationExpires: Date,
  emailVerificationOTP: {
    code: String,
    expiresAt: Date
  },
  loginHistory: [{
    timestamp: {
      type: Date,
      default: Date.now
    },
    ip: String,
    userAgent: String
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  role: {
    type: String,
    enum: {
      values: ['user', 'admin'],
      message: 'Invalid role'
    },
    default: 'user'
  },
  status: {
    type: String,
    enum: {
      values: ['active', 'inactive', 'suspended'],
      message: 'Invalid status'
    },
    default: 'active'
  },
  referralEarnings: {
    type: Number,
    default: 0
  },
  fcmToken: {
    type: String,
    default: null
  }
}, {
  timestamps: true,
  toJSON: { getters: true },
  toObject: { getters: true }
});

// Remove userId generation pre-save hook
userSchema.pre('validate', function (next) {
  next();
});

// Generate unique referralCode before saving
userSchema.pre('save', async function (next) {
  if (!this.isNew) return next();

  try {
    const bytes = crypto.randomBytes(4);
    this.referralCode = 'REF' + bytes.toString('hex').toUpperCase();
    next();
  } catch (error) {
    next(error);
  }
});

// Hash password before saving
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();

  try {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(this.password, salt);
    this.password = hashedPassword;
    next();
  } catch (error) {
    next(error);
  }
});

// Pre-save middleware to ensure userId is set
userSchema.pre('save', function (next) {
  if (!this.userId) {
    this.userId = 'USER' + crypto.randomBytes(6).toString('hex').toUpperCase();
  }
  next();
});

// Pre-save middleware for data formatting
userSchema.pre('save', function (next) {
  // Convert userName field for database storage
  if (this.userName) {
    this.userName = this.userName.toLowerCase();
  }
  next();
});

// Update comparePassword method to be more reliable
userSchema.methods.comparePassword = async function (candidatePassword) {
  try {
    if (!candidatePassword || !this.password) {
      return false;
    }

    const isMatch = await bcrypt.compare(candidatePassword, this.password);
    return isMatch;
  } catch (error) {
    return false;
  }
};

// Drop indexes before creating new ones
// mongoose.connection.on('connected', async () => {
//   try {
//     await mongoose.connection.db.collection('users').dropIndexes();
//     console.log('✅ Dropped all indexes from users collection');
//   } catch (error) {
//     console.log('No indexes to drop');
//   }
// });

// Create indexes
userSchema.index({ username: 1 }, { unique: true });
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ userId: 1 }, { unique: true });
userSchema.index({ referralCode: 1 }, { unique: true });

// Generate email verification token
userSchema.methods.generateEmailVerificationToken = function () {
  const token = crypto.randomBytes(32).toString('hex');

  this.emailVerificationToken = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  this.emailVerificationExpires = Date.now() + 24 * 60 * 60 * 1000; // 24 hours

  return token;
};

// Generate password reset token
userSchema.methods.generatePasswordResetToken = function () {
  const token = crypto.randomBytes(32).toString('hex');

  this.resetPasswordToken = crypto
    .createHash('sha256')
    .update(token)
    .digest('hex');

  this.resetPasswordExpires = Date.now() + 10 * 60 * 1000; // 10 minutes

  return token;
};

// Update last login
userSchema.methods.updateLastLogin = async function () {
  this.lastLogin = new Date();
  await this.save();
};

// Get login history
userSchema.methods.getLoginHistory = function () {
  return this.loginHistory;
};

// Update wallet balance from wallet model
userSchema.methods.updateWalletBalance = async function () {
  try {
    const wallet = await Wallet.findOne({ userId: this._id });
    if (wallet) {
      // Calculate balance from transactions
      const calculatedBalance = wallet.calculateBalance();

      // Update user's wallet balance
      this.wallet.balance = calculatedBalance;
      this.wallet.pendingBalance = wallet.pendingBalance;
      this.wallet.lastUpdated = new Date();

      // Save user
      await this.save();

      // Update wallet balance
      wallet.balance = calculatedBalance;
      await wallet.save();

      return calculatedBalance;
    }
    return this.wallet.balance;
  } catch (error) {
    logger.error('Error updating wallet balance:', error);
    throw new Error(`Failed to update wallet balance: ${error.message}`);
  }
};

// Get wallet balance
userSchema.methods.getWalletBalance = function () {
  return this.wallet.balance;
};

// Add transaction to wallet
userSchema.methods.addTransaction = async function (transactionId) {
  try {
    this.wallet.transactions.push(transactionId);
    await this.save();
    return true;
  } catch (error) {
    throw new Error(`Failed to add transaction: ${error.message}`);
  }
};

// Get wallet transactions
userSchema.methods.getWalletTransactions = function () {
  return this.populate('wallet.transactions');
};

// Update referral earnings
userSchema.methods.updateReferralEarnings = async function (amount) {
  const currentEarnings = new BigNumber(this.referralStats.claimedEarnings);
  const transactionAmount = new BigNumber(amount);

  this.referralStats.claimedEarnings = currentEarnings.plus(transactionAmount).toFixed(18);
  return this.save();
};

// Get referral earnings
userSchema.methods.getReferralEarnings = function () {
  return this.referralStats.claimedEarnings;
};

// Get total earnings
userSchema.methods.getTotalEarnings = function () {
  return this.referralStats.claimedEarnings;
};

// Get referral code
userSchema.methods.getReferralCode = function () {
  return this.referralCode;
};

// Get referred by
userSchema.methods.getReferredBy = function () {
  return this.populate('referredBy');
};

// Get user profile
userSchema.methods.getProfile = function () {
  return {
    userName: this.userName,
    userEmail: this.userEmail,
    referralCode: this.referralCode,
    referralEarnings: this.referralStats.claimedEarnings,
    walletBalance: this.wallet.balance,
    isEmailVerified: this.isEmailVerified,
    lastLogin: this.lastLogin
  };
};

// Get user stats
userSchema.methods.getStats = function () {
  return {
    totalEarnings: this.referralStats.claimedEarnings,
    walletBalance: this.wallet.balance,
    transactionCount: this.wallet.transactions.length,
    loginCount: this.loginHistory.length
  };
};

// Get user activity
userSchema.methods.getActivity = function () {
  return {
    lastLogin: this.lastLogin,
    loginHistory: this.loginHistory,
    transactions: this.wallet.transactions
  };
};

// Get user security info
userSchema.methods.getSecurityInfo = function () {
  return {
    isEmailVerified: this.isEmailVerified,
    lastPasswordChange: this.updatedAt,
    loginHistory: this.loginHistory
  };
};

// Get user referral info
userSchema.methods.getReferralInfo = function () {
  return {
    referralCode: this.referralCode,
    referredBy: this.referredBy,
    referralEarnings: this.referralStats.claimedEarnings
  };
};

// Get user wallet info
userSchema.methods.getWalletInfo = function () {
  return {
    balance: this.wallet.balance,
    transactions: this.wallet.transactions
  };
};

// Get user account info
userSchema.methods.getAccountInfo = function () {
  return {
    userName: this.userName,
    userEmail: this.userEmail,
    isEmailVerified: this.isEmailVerified,
    createdAt: this.createdAt
  };
};

// Get user settings
userSchema.methods.getSettings = function () {
  return {
    emailNotifications: true,
    twoFactorAuth: false,
    language: 'en',
    timezone: 'UTC'
  };
};

// Update user settings
userSchema.methods.updateSettings = async function (settings) {
  // Implement settings update logic here
  return this.save();
};

// Get user notifications
userSchema.methods.getNotifications = function () {
  return {
    email: true,
    push: false,
    sms: false
  };
};

// Update user notifications
userSchema.methods.updateNotifications = async function (notifications) {
  // Implement notifications update logic here
  return this.save();
};

// Get user preferences
userSchema.methods.getPreferences = function () {
  return {
    theme: 'light',
    currency: 'USD',
    dateFormat: 'MM/DD/YYYY'
  };
};

// Update user preferences
userSchema.methods.updatePreferences = async function (preferences) {
  // Implement preferences update logic here
  return this.save();
};

// Get user activity log
userSchema.methods.getActivityLog = function () {
  return {
    logins: this.loginHistory,
    transactions: this.wallet.transactions,
    referrals: this.referralStats.claimedEarnings > 0
  };
};

// Get user security log
userSchema.methods.getSecurityLog = function () {
  return {
    passwordChanges: this.updatedAt,
    emailVerification: this.isEmailVerified,
    lastLogin: this.lastLogin
  };
};

// Get user referral log
userSchema.methods.getReferralLog = function () {
  return {
    code: this.referralCode,
    earnings: this.referralStats.claimedEarnings,
    referredBy: this.referredBy
  };
};

// Get user wallet log
userSchema.methods.getWalletLog = function () {
  return {
    balance: this.wallet.balance,
    transactions: this.wallet.transactions
  };
};

// Get user account log
userSchema.methods.getAccountLog = function () {
  return {
    created: this.createdAt,
    updated: this.updatedAt,
    lastLogin: this.lastLogin
  };
};

// Get user settings log
userSchema.methods.getSettingsLog = function () {
  return {
    emailNotifications: true,
    twoFactorAuth: false,
    language: 'en',
    timezone: 'UTC'
  };
};

// Get user notifications log
userSchema.methods.getNotificationsLog = function () {
  return {
    email: true,
    push: false,
    sms: false
  };
};

// Get user preferences log
userSchema.methods.getPreferencesLog = function () {
  return {
    theme: 'light',
    currency: 'USD',
    dateFormat: 'MM/DD/YYYY'
  };
};

// Get user activity summary
userSchema.methods.getActivitySummary = function () {
  return {
    totalLogins: this.loginHistory.length,
    totalTransactions: this.wallet.transactions.length,
    totalReferrals: this.referralStats.claimedEarnings > 0 ? 1 : 0
  };
};

// Get user security summary
userSchema.methods.getSecuritySummary = function () {
  return {
    isEmailVerified: this.isEmailVerified,
    lastPasswordChange: this.updatedAt,
    lastLogin: this.lastLogin
  };
};

// Get user referral summary
userSchema.methods.getReferralSummary = function () {
  return {
    referralCode: this.referralCode,
    referralEarnings: this.referralStats.claimedEarnings,
    referredBy: this.referredBy
  };
};

// Get user wallet summary
userSchema.methods.getWalletSummary = function () {
  return {
    balance: this.wallet.balance,
    transactionCount: this.wallet.transactions.length
  };
};

// Get user account summary
userSchema.methods.getAccountSummary = function () {
  return {
    userName: this.userName,
    userEmail: this.userEmail,
    isEmailVerified: this.isEmailVerified
  };
};

// Get user settings summary
userSchema.methods.getSettingsSummary = function () {
  return {
    emailNotifications: true,
    twoFactorAuth: false,
    language: 'en',
    timezone: 'UTC'
  };
};

// Get user notifications summary
userSchema.methods.getNotificationsSummary = function () {
  return {
    email: true,
    push: false,
    sms: false
  };
};

// Get user preferences summary
userSchema.methods.getPreferencesSummary = function () {
  return {
    theme: 'light',
    currency: 'USD',
    dateFormat: 'MM/DD/YYYY'
  };
};

// Sign JWT and return
userSchema.methods.getSignedJwtToken = function () {
  return jwt.sign(
    {
      userId: this.userId,
      role: this.role,
      email: this.userEmail
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRE }
  );
};

// Match user entered password to hashed password in database
userSchema.methods.matchPassword = async function (candidatePassword) {
  try {
    console.log('🔐 Comparing passwords');
    console.log('📝 Input password:', candidatePassword);
    console.log('📝 Stored hash:', this.password);

    // Use compare instead of compareSync for better error handling
    const isMatch = await bcrypt.compare(candidatePassword, this.password);
    console.log('✅ Password match result:', isMatch);
    return isMatch;
  } catch (error) {
    console.error('❌ Error comparing passwords:', error);
    throw error;
  }
};

// Update password field schema
userSchema.path('password').set(function (password) {
  if (!password) return this.password;
  return password; // Will be hashed by pre-save middleware
});

// Method to generate referral code
userSchema.methods.generateReferralCode = async function () {
  if (!this.referralCode) {
    this.referralCode = 'REF' + crypto.randomBytes(6).toString('hex').toUpperCase();
  }
  return this.referralCode;
};

// Add debug logging for user queries
userSchema.pre('findOne', function () {
  console.log('Debug - Finding user with query:', this.getQuery());
});

// Add debug logging for when a user is found
userSchema.post('findOne', function (doc) {
  console.log('Debug - User find result:', doc ? 'Found user with ID: ' + doc.userId : 'No user found');
});

// Export the schema
module.exports = mongoose.model('User', userSchema);