const mongoose = require('mongoose');
const { Schema } = mongoose;
const crypto = require('crypto');
const { formatBTC } = require('../utils/format');
const BigNumber = require('bignumber.js');
const logger = require('../utils/logger');

// Balance History schema
const balanceHistorySchema = new Schema({
  balance: {
    type: String,
    required: true,
    default: '0.000000000000000000',
    validate: {
      validator: function (v) {
        return /^\d+\.\d{18}$/.test(v);
      },
      message: props => `${props.value} must have exactly 18 decimal places`
    }
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
});

// Transaction schema
const transactionSchema = new Schema({
  transactionId: {
    type: String,
    required: true
  },
  type: {
    type: String,
    required: true,
    enum: [
      'deposit',
      'withdrawal',
      'transfer',
      'reward',
      'referral',
      'tap',
      'mining',
      'earning',
      'claim',
      'balance_sync',
      'penalty',
      'daily_reward',
      'gaming_reward',
      'game',
      'streak_reward',
      'youtube_reward',
      'twitter_reward',
      'telegram_reward',
      'instagram_reward',
      'facebook_reward',
      'tiktok_reward',
      'social_reward',
      'ad_reward',
      'withdrawal_bitcoin',
      'withdrawal_paypal',
      'withdrawal_paytm',
      'Withdrawal - Bitcoin',
      'Withdrawal - Paypal',
      'Withdrawal - Paytm',
      'Withdrawal - BTC',
      'refund',
      'mining',
      'earning',
      'claim',
      'balance_sync'
    ]
  },
  amount: {
    type: String,
    required: true,
    validate: {
      validator: function (v) {
        return /^\d+\.\d{18}$/.test(v);
      },
      message: props => `${props.value} must have exactly 18 decimal places`
    }
  },
  status: {
    type: String,
    required: true,
    enum: ['pending', 'completed', 'failed', 'cancelled', 'rejected'],
    default: 'completed'
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
});

// Wallet schema
const walletSchema = new Schema({
  walletId: {
    type: String,
    unique: true,
    required: true,
    default: () => 'WAL' + crypto.randomBytes(8).toString('hex').toUpperCase()
  },
  userId: {
    type: String,
    required: true,
    unique: true
  },
  balance: {
    type: String,
    required: true,
    default: '0.000000000000000000',
    validate: {
      validator: function (v) {
        return /^\d+\.\d{18}$/.test(v);
      },
      message: props => `${props.value} must have exactly 18 decimal places`
    }
  },
  pendingBalance: {
    type: String,
    default: '0.000000000000000000',
    validate: {
      validator: function (v) {
        return /^\d+\.\d{18}$/.test(v);
      },
      message: props => `${props.value} must have exactly 18 decimal places`
    }
  },
  transactions: [transactionSchema],
  balanceHistory: [balanceHistorySchema],
  lastUpdated: {
    type: Date,
    default: Date.now
  },
  currency: {
    type: String,
    default: 'BTC'
  }
});

// Safe save method with retries
walletSchema.methods.safeSave = async function (session = null) {
  let attempts = 0;
  const maxAttempts = 5;

  while (attempts < maxAttempts) {
    try {
      // Format balances
      this.balance = formatBTC(this.balance);
      this.pendingBalance = formatBTC(this.pendingBalance);

      // Save wallet
      if (session) {
        await this.save({ session });
      } else {
        await this.save();
      }

      // Get database connection
      const db = mongoose.connection.db;
      if (!db) {
        throw new Error('Database connection not available');
      }

      // Update user's wallet data directly in MongoDB
      const userCollection = db.collection('users');
      const updateOptions = session ? { session } : {};

      const updateResult = await userCollection.updateOne(
        { userId: this.userId },
        {
          $set: {
            'wallet.balance': this.balance,
            'wallet.pendingBalance': this.pendingBalance,
            'wallet.currency': this.currency,
            'wallet.lastUpdated': new Date()
          }
        },
        updateOptions
      );

      // Check if user was found and updated
      if (updateResult.matchedCount === 0) {
        throw new Error(`User not found for wallet update: ${this.userId}`);
      }

      logger.info('Wallet and user updated successfully', {
        walletId: this.walletId,
        userId: this.userId,
        timestamp: new Date().toISOString()
      });

      return true;

    } catch (error) {
      attempts++;

      logger.error('Wallet save attempt failed:', {
        attempt: attempts,
        error: error.message,
        walletId: this.walletId,
        userId: this.userId,
        timestamp: new Date().toISOString()
      });

      if (attempts === maxAttempts) {
        throw new Error(`Failed to save wallet after ${maxAttempts} attempts: ${error.message}`);
      }

      // Wait before retry with exponential backoff
      await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempts) * 1000));
    }
  }
};

// Method to update balance safely
walletSchema.methods.updateBalance = async function (amount, type = 'add', options = {}) {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const currentBalance = new BigNumber(this.balance || '0.000000000000000000');
    const changeAmount = new BigNumber(amount);

    if (type === 'subtract' && currentBalance.isLessThan(changeAmount)) {
      throw new Error('Insufficient balance');
    }

    // Calculate new balance
    const newBalance = type === 'add'
      ? currentBalance.plus(changeAmount)
      : currentBalance.minus(changeAmount);

    // Update balance
    this.balance = formatBTC(newBalance.toString());

    // Add to balance history
    this.balanceHistory.push({
      balance: this.balance,
      timestamp: new Date()
    });

    // Save changes
    await this.safeSave(session);
    await session.commitTransaction();

    return this.balance;
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
};

// Add transaction with balance update
walletSchema.methods.addTransaction = async function (transactionData) {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { type, amount } = transactionData;
    const formattedAmount = formatBTC(amount);

    // Update balance based on transaction type
    if (['deposit', 'reward', 'mining', 'earning', 'referral', 'claim', 'tap'].includes(type)) {
      await this.updateBalance(formattedAmount, 'add', { session });
    } else if (type === 'withdrawal') {
      await this.updateBalance(formattedAmount, 'subtract', { session });
    }

    // Add transaction to history
    this.transactions.unshift({
      ...transactionData,
      amount: formattedAmount,
      timestamp: new Date()
    });

    // Save wallet changes
    await this.save({ session });

    // Update user's wallet data using direct MongoDB collection
    const db = mongoose.connection.db;
    if (!db) {
      throw new Error('Database connection not available');
    }

    const userCollection = db.collection('users');
    const updateResult = await userCollection.updateOne(
      { userId: this.userId },
      {
        $set: {
          'wallet.balance': this.balance,
          'wallet.pendingBalance': this.pendingBalance,
          'wallet.lastUpdated': new Date()
        }
      },
      session ? { session } : {}
    );

    if (updateResult.matchedCount === 0) {
      throw new Error(`User not found for wallet update: ${this.userId}`);
    }

    if (!updateResult.matchedCount) {
      throw new Error('Failed to update user wallet data - user not found');
    }

    await session.commitTransaction();
    return true;
  } catch (error) {
    await session.abortTransaction();
    throw error;
  } finally {
    session.endSession();
  }
};

// Method to clean up invalid transaction statuses
walletSchema.methods.cleanupTransactions = async function () {
  if (this.transactions && this.transactions.length > 0) {
    this.transactions = this.transactions.map(tx => {
      if (!['pending', 'completed', 'failed', 'cancelled', 'rejected'].includes(tx.status)) {
        tx.status = 'completed';  // Default to completed for invalid statuses
      }
      return tx;
    });
    await this.save();
  }
};

// Add pre-save hook to validate transaction statuses
walletSchema.pre('save', async function (next) {
  try {
    if (this.transactions && this.transactions.length > 0) {
      this.transactions.forEach(tx => {
        if (!['pending', 'completed', 'failed', 'cancelled', 'rejected'].includes(tx.status)) {
          tx.status = 'completed';  // Default to completed for invalid statuses
        }
      });
    }
    next();
  } catch (error) {
    next(error);
  }
});

module.exports = mongoose.model('Wallet', walletSchema);
