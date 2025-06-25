const mongoose = require('mongoose');
const User = require('./user.model');
const { formatBTC } = require('../utils/format');
const { generateReferralCode } = require('../utils/generators');
const crypto = require('crypto');
const { Schema } = mongoose;

// Define schema
const referralSchema = new Schema({
  referrerId: {
    type: String,
    required: [true, 'Referrer ID is required'],
    ref: 'User'
  },
  referredId: {
    type: String,
    required: [true, 'Referred ID is required'],
    ref: 'User'
  },
  referrerCode: {
    type: String,
    required: [true, 'Referral code is required']
  },
  referralCode: {
    type: String,
    default: () => 'REF' + crypto.randomBytes(6).toString('hex').toUpperCase()
  },
  referredUserDetails: {
    username: String,
    email: String,
    joinedAt: {
      type: Date,
      default: Date.now
    }
  },
  status: {
    type: String,
    enum: ['active', 'completed', 'cancelled'],
    default: 'active'
  },
  earnings: {
    type: Number,
    default: 0,
    min: [0, 'Earnings cannot be negative'],
    get: v => v != null ? v.toFixed(18) : '0.000000000000000000',
    set: v => parseFloat(Number(v).toFixed(18))
  },
  pendingEarnings: {
    type: Number,
    default: 0,
    get: v => v != null ? v.toFixed(18) : '0.000000000000000000',
    set: v => parseFloat(Number(v).toFixed(18))
  },
  lastClaimDate: {
    type: Date,
    default: null
  },
  earningsHistory: [{
    amount: {
      type: Number,
      required: true,
      get: v => v != null ? v.toFixed(18) : '0.000000000000000000',
      set: v => parseFloat(Number(v).toFixed(18))
    },
    type: {
      type: String,
      enum: ['referral', 'bonus', 'claimed'],
      required: true
    },
    timestamp: {
      type: Date,
      default: Date.now
    }
  }],
  claimHistory: [{
    amount: {
      type: Number,
      required: [true, 'Amount is required'],
      get: v => v != null ? v.toFixed(18) : '0.000000000000000000',
      set: v => parseFloat(Number(v).toFixed(18))
    },
    timestamp: {
      type: Date,
      default: Date.now
    },
    status: {
      type: String,
      enum: ['pending', 'completed', 'failed'],
      default: 'pending'
    }
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  strict: true,
  toObject: {
    virtuals: true,
    getters: true,
    methods: true,
    versionKey: false
  },
  toJSON: {
    virtuals: true,
    getters: true,
    methods: true,
    versionKey: false
  }
});

// Prevent duplicate referrals
referralSchema.index({ referrerId: 1, referredId: 1 }, { unique: true });

// Pre-validate middleware to check for duplicate referrals
referralSchema.pre('validate', function (next) {
  if (this.referrerId === this.referredId) {
    this.invalidate('referredId', 'User cannot refer themselves');
  }
  next();
});

// Method to add earnings
referralSchema.methods.addEarnings = async function (amount, currency = 'BTC') {
  const currentEarnings = parseFloat(this.earnings) || 0;
  const newAmount = parseFloat(amount) || 0;
  const totalEarnings = currentEarnings + newAmount;

  this.earnings = totalEarnings;

  this.earningsHistory.push({
    amount: amount,
    currency,
    timestamp: new Date(),
    type: 'referral_bonus'
  });

  this.history.push({
    type: 'earn',
    amount: amount,
    currency,
    timestamp: new Date()
  });

  await this.save();
  return this;
};

// Method to claim earnings
referralSchema.methods.claimEarnings = async function (amount, currency = 'BTC') {
  const currentEarnings = parseFloat(this.earnings) || 0;
  const currentClaims = parseFloat(this.claims) || 0;
  const claimAmount = parseFloat(amount) || 0;

  if (claimAmount > currentEarnings) {
    throw new Error('Insufficient earnings to claim');
  }

  const newEarnings = currentEarnings - claimAmount;
  const newClaims = currentClaims + claimAmount;

  this.earnings = newEarnings;

  this.claims = newClaims;

  this.claimHistory.push({
    amount: amount,
    currency,
    timestamp: new Date(),
    status: 'completed'
  });

  this.history.push({
    type: 'claim',
    amount: amount,
    currency,
    timestamp: new Date()
  });

  await this.save();
  return this;
};

// Method to get total earnings
referralSchema.methods.getTotalEarnings = function () {
  return parseFloat(this.earnings) || 0;
};

// Method to get available earnings
referralSchema.methods.getAvailableEarnings = function () {
  const totalEarnings = parseFloat(this.earnings) || 0;
  const totalClaims = parseFloat(this.claims) || 0;
  return totalEarnings - totalClaims;
};

// Add referral reward
referralSchema.methods.addReferralReward = async function (referredUser) {
  try {
    console.log('Adding referral reward for:', {
      referralId: this._id,
      referrer: this.referrerId,
      referred: this.referredId
    });

    // Get referred user's wallet balance
    const referredUserBalance = parseFloat(referredUser.walletBalance);
    console.log('Found referred user:', {
      id: referredUser._id,
      walletBalance: referredUser.walletBalance
    });

    if (referredUserBalance <= 0) {
      console.log('Error: Referred user has no balance:', referredUserBalance);
      return;
    }

    // Calculate reward (5% of referred user's balance)
    const rewardAmount = formatBTC(referredUserBalance * 0.05);
    console.log('Calculated reward amount:', rewardAmount);

    // Add reward to earnings
    this.earnings += parseFloat(rewardAmount);

    // Add to history
    this.earningsHistory.push({
      amount: parseFloat(rewardAmount),
      currency: 'BTC',
      timestamp: new Date(),
      type: 'referral_bonus'
    });

    this.history.push({
      type: 'earn',
      amount: rewardAmount,
      currency: 'BTC',
      timestamp: new Date()
    });

    await this.save();
    console.log('Successfully added referral reward');
  } catch (error) {
    console.error('Error adding referral reward:', error);
    throw error;
  }
};

// Claim referral rewards
referralSchema.methods.claimReferralRewards = async function () {
  try {
    console.log('Claiming referral rewards for:', {
      referralId: this._id,
      referrer: this.referrerId
    });

    // Get pending rewards
    const pendingRewards = this.earnings > 0;
    console.log('Found pending rewards:', {
      pendingRewards
    });

    if (!pendingRewards) {
      console.log('No pending rewards to claim');
      return null;
    }

    // Calculate total claim amount
    const totalClaimAmount = this.earnings;
    console.log('Processed rewards:', {
      totalClaimAmount
    });

    // Update reward statuses
    this.earnings = 0;

    // Update statistics
    console.log('Updated statistics:', {
      claimedEarnings: this.earnings
    });

    // Update referrer's wallet balance
    const User = mongoose.model('User');
    // Use userId instead of _id for string-based IDs
    const referrer = await User.findOne({ userId: this.referrerId });
    if (!referrer) {
      throw new Error('Referrer not found');
    }

    const currentBalance = parseFloat(referrer.walletBalance);
    referrer.walletBalance = formatBTC(currentBalance + totalClaimAmount);
    await referrer.save();
    console.log('Updated referrer wallet balance:', {
      userId: referrer.userId,
      newBalance: referrer.walletBalance
    });

    // Add to history
    this.history.push({
      type: 'claim',
      amount: formatBTC(totalClaimAmount),
      currency: 'BTC',
      timestamp: new Date()
    });

    await this.save();
    console.log('Successfully saved referral after claiming rewards');

    return formatBTC(totalClaimAmount);
  } catch (error) {
    console.error('Error claiming referral rewards:', error);
    throw error;
  }
};

referralSchema.methods.addHistoricalRewards = async function (count) {
  try {
    const rewards = [];
    for (let i = 0; i < count; i++) {
      const date = new Date();
      date.setDate(date.getDate() - i - 1);
      const reward = await this.addReferralReward(date);
      rewards.push(reward);
    }
    return rewards;
  } catch (error) {
    throw new Error(`Failed to add historical rewards: ${error.message}`);
  }
};

referralSchema.methods.updateReferredUserBalance = async function () {
  try {
    const User = mongoose.model('User');
    const referred = await User.findById(this.referredId);

    if (!referred) {
      throw new Error('Referred user not found');
    }

    this.referredUserDetails = {
      walletBalance: referred.walletBalance,
      isVerified: referred.isVerified,
      lastBalanceUpdate: new Date()
    };

    this.history.push({
      type: 'earn',
      amount: referred.walletBalance,
      currency: 'BTC',
      timestamp: new Date(),
      description: `Updated referred user balance to ${referred.walletBalance} BTC`
    });

    return await this.save();
  } catch (error) {
    throw new Error(`Failed to update referred user balance: ${error.message}`);
  }
};

// Create indexes
referralSchema.index({ referralCode: 1 }, { unique: true });
referralSchema.index({ status: 1 });
referralSchema.index({ 'earnings': -1 });
referralSchema.index({ 'referredUserDetails.lastBalanceUpdate': 1 });

// Pre-save middleware to update timestamps and referralCount
referralSchema.pre('save', async function (next) {
  if (this.isModified()) {
    this.updatedAt = new Date();
  }

  // If this is a new referral, update referrer's referralCount
  if (this.isNew) {
    try {
      const User = mongoose.model('User');
      await User.updateOne(
        { userId: this.referrerId },
        { $inc: { referralCount: 1 } }
      );
    } catch (error) {
      return next(error);
    }
  }

  next();
});

// Calculate total earnings
referralSchema.methods.calculateTotalEarnings = function (currency) {
  return this.earningsHistory
    .filter(earning => earning.currency === currency)
    .reduce((total, earning) => total + parseFloat(earning.amount), 0);
};

// Calculate total claims
referralSchema.methods.calculateTotalClaims = function (currency) {
  return this.claimHistory
    .filter(claim => claim.currency === currency)
    .reduce((total, claim) => total + parseFloat(claim.amount), 0);
};

// Method to calculate daily reward from referred user's balance
referralSchema.methods.calculateDailyReward = async function (referredUser) {
  try {
    // Get referred user's current wallet balance
    const referredUserBalance = parseFloat(referredUser.walletBalance) || 0;

    // Calculate 1% of the balance
    const dailyReward = referredUserBalance * 0.01;

    if (dailyReward <= 0) {
      console.log('No daily reward: Referred user has no balance');
      return 0;
    }

    // Add reward to earnings
    this.earnings = (this.earnings || 0) + dailyReward;

    // Add to earnings history
    this.earningsHistory.push({
      amount: dailyReward,
      type: 'daily_reward',
      timestamp: new Date(),
      referredUserBalance: referredUserBalance
    });

    await this.save();
    console.log(`Added daily reward of ${dailyReward} BTC to referral ${this._id}`);

    return dailyReward;
  } catch (error) {
    console.error('Error calculating daily reward:', error);
    throw error;
  }
};

// Create and export model
const Referral = mongoose.model('Referral', referralSchema);
module.exports = Referral;