const mongoose = require('mongoose');
const { Schema } = mongoose;
const crypto = require('crypto');
const { formatBTC } = require('../utils/format');

// Update decimalUtils with better precision handling
const decimalUtils = {
  add: (a, b) => {
    try {
      // Remove any non-numeric characters except decimal point
      const num1 = a ? a.toString().replace(/[^\d.]/g, '') : '0';
      const num2 = b ? b.toString().replace(/[^\d.]/g, '') : '0';

      // Convert to BigInt for precise calculation (multiply by 10^18 to handle decimals)
      const factor = BigInt(1000000000000000000);
      const val1 = BigInt(Math.floor(parseFloat(num1) * 1000000000000000000));
      const val2 = BigInt(Math.floor(parseFloat(num2) * 1000000000000000000));

      // Perform addition with BigInt
      const sum = val1 + val2;

      // Convert back to decimal string with 18 places
      const result = (sum.toString() / factor).toFixed(18);
      return formatBTC(result);
    } catch (error) {
      console.error('Addition error:', error);
      return '0.000000000000000000';
    }
  },
  subtract: (a, b) => {
    try {
      // Remove any non-numeric characters except decimal point
      const num1 = a ? a.toString().replace(/[^\d.]/g, '') : '0';
      const num2 = b ? b.toString().replace(/[^\d.]/g, '') : '0';

      // Convert to BigInt for precise calculation (multiply by 10^18 to handle decimals)
      const factor = BigInt(1000000000000000000);
      const val1 = BigInt(Math.floor(parseFloat(num1) * 1000000000000000000));
      const val2 = BigInt(Math.floor(parseFloat(num2) * 1000000000000000000));

      // Perform subtraction with BigInt, ensuring result is not negative
      const diff = val1 > val2 ? val1 - val2 : BigInt(0);

      // Convert back to decimal string with 18 places
      const result = (diff.toString() / factor).toFixed(18);
      return formatBTC(result);
    } catch (error) {
      console.error('Subtraction error:', error);
      return '0.000000000000000000';
    }
  },
  isValidAmount: (amount) => {
    try {
      // Check if amount is a valid number with 18 decimal places
      const formatted = formatBTC(amount);
      return /^\d+\.\d{18}$/.test(formatted) && parseFloat(formatted) > 0;
    } catch (error) {
      return false;
    }
  }
};

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
    },
    set: function (v) {
      return formatBTC(v || '0.000000000000000000');
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
      'game',
      'ad_reward',
      'social_reward',
      'mining',
      'earning',
      'penalty',
      'daily_reward',
      'gaming_reward',
      'streak_reward',
      'youtube_reward',
      'twitter_reward',
      'telegram_reward',
      'instagram_reward',
      'facebook_reward',
      'tiktok_reward',
      'withdrawal_bitcoin',
      'withdrawal_paypal',
      'withdrawal_paytm',
      'Withdrawal - Bitcoin',
      'Withdrawal - Paypal',
      'Withdrawal - Paytm',
      'Withdrawal - BTC',
      'claim',
      'balance_sync'
    ]
  },
  currency: {
    type: String,
    required: true,
    default: 'BTC'
  },
  destination: {
    type: String,
    required: true,
    default: 'Wallet'
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
  netAmount: {
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
    enum: ['pending', 'completed', 'failed', 'cancelled'],
    default: 'completed'
  },
  description: {
    type: String
  },
  exchangeRate: {
    type: Number,
    required: true,
    default: 30000
  },
  localAmount: {
    type: String,
    required: true,
    default: '0.00'
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  details: {
    type: mongoose.Schema.Types.Mixed,
    default: {}
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
        return /^[0-9]+\.[0-9]{18}$/.test(v);
      },
      message: props => `${props.value} must have exactly 18 decimal places`
    },
    get: function (value) {
      // Access the raw value directly to avoid recursion
      return formatBTC(value || '0.000000000000000000');
    },
    set: function (value) {
      // Return raw value, letting mongoose handle the internal state
      return formatBTC(value || '0.000000000000000000');
    }
  },
  transactions: [transactionSchema],
  balanceHistory: [balanceHistorySchema],
  lastUpdated: {
    type: Date,
    default: Date.now
  }
});

// Replace virtual with direct formatting in toJSON
walletSchema.set('toJSON', {
  getters: true,
  transform: function (doc, ret) {
    // Format balance directly
    ret.balance = formatBTC(ret.balance || '0.000000000000000000');
    return ret;
  }
});

// Pre-save middleware to ensure proper balance format
walletSchema.pre('save', async function (next) {
  try {
    if (this.isModified('balance') || this.isModified('balanceHistory')) {
      // Format balance
      this.balance = formatBTC(this.balance || '0.000000000000000000');

      // Ensure balanceHistory entries have proper balance format
      if (this.balanceHistory && this.balanceHistory.length > 0) {
        this.balanceHistory.forEach(history => {
          if (!history.balance) {
            history.balance = '0.000000000000000000';
          }
          history.balance = formatBTC(history.balance);
        });
      }

      // Validate all balances
      if (!/^\d+\.\d{18}$/.test(this.balance)) {
        throw new Error('Invalid wallet balance format');
      }
    }
    next();
  } catch (error) {
    next(error);
  }
});

// Add transaction cache schema
const processedTransactionSchema = new Schema({
  transactionId: {
    type: String,
    required: true,
    unique: true
  },
  processedAt: {
    type: Date,
    default: Date.now
  }
});

// Define ProcessedTransaction model once
const ProcessedTransaction = mongoose.model('ProcessedTransaction', processedTransactionSchema);

// Add sync state to schema
walletSchema.add({
  syncInProgress: {
    type: Boolean,
    default: false
  }
});

// Single processTransaction implementation
walletSchema.methods.processTransaction = async function (transactionData) {
  return queueTransaction(this.walletId, async () => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      // Special handling for balance sync
      if (transactionData.type === 'balance_sync') {
        return await this.handleBalanceSync(transactionData);
      }

      // Check if sync is in progress
      if (syncLocks.has(this.walletId)) {
        console.log(`Sync in progress for wallet ${this.walletId}, deferring transaction processing`);
        return {
          success: false,
          status: 'deferred',
          message: 'Balance sync in progress'
        };
      }

      // Validate transaction data
      if (!transactionData?.transactionId || !transactionData?.amount) {
        throw new Error('Invalid transaction data: missing required fields');
      }

      // Format amount to 18 decimal places
      const amount = formatBTC(transactionData.amount);
      if (!amount || !/^\d+\.\d{18}$/.test(amount)) {
        throw new Error('Invalid transaction amount format');
      }

      // Check for duplicate transaction - both in DB and memory cache
      if (processedTransactionCache.has(transactionData.transactionId)) {
        return {
          success: true,
          status: 'skipped',
          message: 'Transaction already processed (cached)'
        };
      }

      const processed = await ProcessedTransaction.findOne({
        transactionId: transactionData.transactionId
      }).session(session);

      if (processed) {
        processedTransactionCache.add(transactionData.transactionId);
        return {
          success: true,
          status: 'skipped',
          message: 'Transaction already processed'
        };
      }

      // Get current wallet state atomically
      const currentWallet = await this.model('Wallet').findOne({
        _id: this._id
      }).select('balance transactions').session(session);

      if (!currentWallet) {
        throw new Error('Wallet not found');
      }

      // Calculate new balance using BigNumber for precision
      const currentBalance = new BigNumber(currentWallet.balance || '0.000000000000000000');
      const transactionAmount = new BigNumber(amount);
      let newBalance;

      if (['withdrawal', 'penalty'].includes(transactionData.type)) {
        if (currentBalance.isLessThan(transactionAmount)) {
          throw new Error('Insufficient balance for withdrawal');
        }
        newBalance = currentBalance.minus(transactionAmount);
      } else if (['deposit', 'reward', 'mining', 'earning', 'referral',
        'daily_reward', 'gaming_reward', 'claim', 'tap'].includes(transactionData.type)) {
        newBalance = currentBalance.plus(transactionAmount);
      } else {
        throw new Error(`Invalid transaction type: ${transactionData.type}`);
      }

      // Format final balance
      const formattedBalance = formatBTC(newBalance.toString());

      // Update wallet atomically
      const updatedWallet = await this.model('Wallet').findOneAndUpdate(
        {
          _id: this._id,
          balance: currentWallet.balance // Ensure balance hasn't changed
        },
        {
          $set: {
            balance: formattedBalance,
            lastUpdated: new Date()
          },
          $push: {
            transactions: {
              ...transactionData,
              amount,
              netAmount: formatBTC(transactionData.netAmount || amount),
              status: 'completed',
              timestamp: new Date(),
              details: {
                balanceBefore: currentWallet.balance,
                balanceAfter: formattedBalance,
                exchangeRate: transactionData.exchangeRate || 0,
                localAmount: transactionData.localAmount || '0.00',
                originalAmount: amount,
                originalNetAmount: formatBTC(transactionData.netAmount || amount)
              }
            },
            balanceHistory: {
              balance: formattedBalance,
              timestamp: new Date(),
              type: transactionData.type,
              amount: amount,
              transactionId: transactionData.transactionId,
              oldBalance: currentWallet.balance
            }
          }
        },
        { new: true, session }
      );

      if (!updatedWallet) {
        throw new Error('Failed to update wallet - balance may have changed');
      }

      // Record successful processing
      await ProcessedTransaction.create([{
        transactionId: transactionData.transactionId,
        processedAt: new Date()
      }], { session });

      // Add to memory cache
      processedTransactionCache.add(transactionData.transactionId);

      await session.commitTransaction();

      // Update instance state
      Object.assign(this, updatedWallet);

      console.log(`Transaction processed successfully:
        ID: ${transactionData.transactionId}
        Type: ${transactionData.type}
        Amount: ${amount}
        Old Balance: ${currentWallet.balance}
        New Balance: ${formattedBalance}`);

      return {
        success: true,
        status: 'completed',
        oldBalance: currentWallet.balance,
        newBalance: formattedBalance,
        amount: amount
      };

    } catch (error) {
      await session.abortTransaction();
      console.error('Transaction processing error:', {
        transactionId: transactionData?.transactionId,
        error: error.message
      });

      return {
        success: false,
        status: 'failed',
        error: error.message
      };

    } finally {
      session.endSession();
    }
  });
};

// Add transaction queue management
const transactionQueues = new Map();

// Transaction queue methods already defined above

// Add enhanced balance validation
const validateBalance = (balance) => {
  if (typeof balance !== 'string') {
    throw new Error('Balance must be a string');
  }
  if (!/^\d+\.\d{18}$/.test(balance)) {
    throw new Error('Balance must have exactly 18 decimal places');
  }
  if (parseFloat(balance) < 0) {
    throw new Error('Balance cannot be negative');
  }
  return true;
};

// Add transaction validation
const validateTransaction = (tx) => {
  if (!tx.transactionId || !tx.amount || !tx.type) {
    throw new Error('Missing required transaction fields');
  }
  if (!validateBalance(tx.amount)) {
    throw new Error('Invalid transaction amount format');
  }
  return true;
};

// Update process transaction method
walletSchema.methods.processTransaction = async function (transactionData) {
  return queueTransaction(this.walletId, async () => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      // Special handling for balance sync
      if (transactionData.type === 'balance_sync') {
        return await this.handleBalanceSync(transactionData);
      }

      // Check if sync is in progress
      if (syncLocks.has(this.walletId)) {
        console.log(`Sync in progress for wallet ${this.walletId}, deferring transaction processing`);
        return {
          success: false,
          status: 'deferred',
          message: 'Balance sync in progress'
        };
      }

      // Validate transaction data
      if (!transactionData?.transactionId || !transactionData?.amount) {
        throw new Error('Invalid transaction data: missing required fields');
      }

      // Format amount to 18 decimal places
      const amount = formatBTC(transactionData.amount);
      if (!amount || !/^\d+\.\d{18}$/.test(amount)) {
        throw new Error('Invalid transaction amount format');
      }

      // Check for duplicate transaction - both in DB and memory cache
      if (processedTransactionCache.has(transactionData.transactionId)) {
        return {
          success: true,
          status: 'skipped',
          message: 'Transaction already processed (cached)'
        };
      }

      const processed = await ProcessedTransaction.findOne({
        transactionId: transactionData.transactionId
      }).session(session);

      if (processed) {
        processedTransactionCache.add(transactionData.transactionId);
        return {
          success: true,
          status: 'skipped',
          message: 'Transaction already processed'
        };
      }

      // Get current wallet state atomically
      const currentWallet = await this.model('Wallet').findOne({
        _id: this._id
      }).select('balance transactions').session(session);

      if (!currentWallet) {
        throw new Error('Wallet not found');
      }

      // Calculate new balance using BigNumber for precision
      const currentBalance = new BigNumber(currentWallet.balance || '0.000000000000000000');
      const transactionAmount = new BigNumber(amount);
      let newBalance;

      if (['withdrawal', 'penalty'].includes(transactionData.type)) {
        if (currentBalance.isLessThan(transactionAmount)) {
          throw new Error('Insufficient balance for withdrawal');
        }
        newBalance = currentBalance.minus(transactionAmount);
      } else if (['deposit', 'reward', 'mining', 'earning', 'referral',
        'daily_reward', 'gaming_reward', 'claim', 'tap'].includes(transactionData.type)) {
        newBalance = currentBalance.plus(transactionAmount);
      } else {
        throw new Error(`Invalid transaction type: ${transactionData.type}`);
      }

      // Format final balance
      const formattedBalance = formatBTC(newBalance.toString());

      // Update wallet atomically
      const updatedWallet = await this.model('Wallet').findOneAndUpdate(
        {
          _id: this._id,
          balance: currentWallet.balance // Ensure balance hasn't changed
        },
        {
          $set: {
            balance: formattedBalance,
            lastUpdated: new Date()
          },
          $push: {
            transactions: {
              ...transactionData,
              amount,
              netAmount: formatBTC(transactionData.netAmount || amount),
              status: 'completed',
              timestamp: new Date(),
              details: {
                balanceBefore: currentWallet.balance,
                balanceAfter: formattedBalance,
                exchangeRate: transactionData.exchangeRate || 0,
                localAmount: transactionData.localAmount || '0.00',
                originalAmount: amount,
                originalNetAmount: formatBTC(transactionData.netAmount || amount)
              }
            },
            balanceHistory: {
              balance: formattedBalance,
              timestamp: new Date(),
              type: transactionData.type,
              amount: amount,
              transactionId: transactionData.transactionId,
              oldBalance: currentWallet.balance
            }
          }
        },
        { new: true, session }
      );

      if (!updatedWallet) {
        throw new Error('Failed to update wallet - balance may have changed');
      }

      // Record successful processing
      await ProcessedTransaction.create([{
        transactionId: transactionData.transactionId,
        processedAt: new Date()
      }], { session });

      // Add to memory cache
      processedTransactionCache.add(transactionData.transactionId);

      await session.commitTransaction();

      // Update instance state
      Object.assign(this, updatedWallet);

      console.log(`Transaction processed successfully:
        ID: ${transactionData.transactionId}
        Type: ${transactionData.type}
        Amount: ${amount}
        Old Balance: ${currentWallet.balance}
        New Balance: ${formattedBalance}`);

      return {
        success: true,
        status: 'completed',
        oldBalance: currentWallet.balance,
        newBalance: formattedBalance,
        amount: amount
      };

    } catch (error) {
      await session.abortTransaction();
      console.error('Transaction processing error:', {
        transactionId: transactionData?.transactionId,
        error: error.message
      });

      return {
        success: false,
        status: 'failed',
        error: error.message
      };

    } finally {
      session.endSession();
    }
  });
};

// Add transaction processing method
walletSchema.methods.handleBalanceSync = async function (transactionData) {
  // Acquire sync lock with timeout
  if (!await acquireSyncLock(this.walletId, 30000)) {
    return {
      success: false,
      status: 'locked',
      message: 'Balance sync already in progress'
    };
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // Calculate new balance from all completed transactions
    const { balance: newBalance, history, processedTransactions } =
      await calculateBalanceFromTransactions(this.transactions);

    const currentBalance = this.balance || '0.000000000000000000';

    // Skip if balance hasn't changed
    if (newBalance === currentBalance) {
      await session.commitTransaction();
      return {
        success: true,
        status: 'skipped',
        message: 'Balance unchanged'
      };
    }

    // Update processed transaction cache
    for (const txId of processedTransactions) {
      processedTransactionCache.add(txId);
    }

    // Update wallet atomically
    const updatedWallet = await this.model('Wallet').findOneAndUpdate(
      {
        _id: this._id,
        balance: currentBalance // Ensure balance hasn't changed during sync
      },
      {
        $set: {
          balance: newBalance,
          lastUpdated: new Date(),
          lastBalanceSync: new Date(),
          processedTransactionIds: processedTransactions,
          syncInProgress: false
        },
        $push: {
          balanceHistory: {
            balance: newBalance,
            timestamp: new Date(),
            type: 'balance_sync',
            amount: decimalUtils.subtract(newBalance, currentBalance),
            oldBalance: currentBalance
          }
        }
      },
      { new: true, session }
    );

    if (!updatedWallet) {
      throw new Error('Failed to update wallet during balance sync');
    }

    await session.commitTransaction();

    // Update instance state
    Object.assign(this, updatedWallet);

    console.log(`Balance sync completed:
      Wallet: ${this.walletId}
      Old Balance: ${currentBalance}
      New Balance: ${newBalance}
      Transactions Processed: ${processedTransactions.length}
      History Records: ${history.length}`);

    return {
      success: true,
      status: 'completed',
      oldBalance: currentBalance,
      newBalance: newBalance,
      transactionsProcessed: processedTransactions.length,
      historyRecords: history.length
    };

  } catch (error) {
    await session.abortTransaction();
    console.error('Balance sync error:', error);
    return {
      success: false,
      status: 'failed',
      error: error.message
    };
  } finally {
    session.endSession();
    releaseSyncLock(this.walletId);
  }
};

// Add atomic balance update method
walletSchema.statics.atomicBalanceUpdate = async function (walletId, amount, type, transactionId, session) {
  // Use MongoDB's atomic operators for precise balance updates
  const updateOperation = type === 'withdrawal' || type === 'penalty'
    ? { $inc: { "numericBalance": -parseFloat(amount) } }
    : { $inc: { "numericBalance": parseFloat(amount) } };

  const result = await this.findOneAndUpdate(
    { walletId: walletId },
    {
      ...updateOperation,
      $set: { lastUpdated: new Date() },
      $push: {
        balanceHistory: {
          timestamp: new Date(),
          type: type,
          amount: amount,
          transactionId: transactionId
        }
      }
    },
    {
      new: true,
      session,
      setDefaultsOnInsert: true
    }
  );

  if (!result) {
    throw new Error('Failed to update balance atomically');
  }

  // Convert numeric balance to string format with 18 decimal places
  result.balance = formatBTC(result.numericBalance.toFixed(18));
  await result.save({ session });

  return result;
};

// Add numeric balance field to schema
walletSchema.add({
  numericBalance: {
    type: Number,
    default: 0,
    get: function () {
      return parseFloat(this.balance || '0.000000000000000000');
    },
    set: function (value) {
      this.balance = formatBTC(value.toFixed(18));
      return value;
    }
  }
});

// Add new fields to wallet schema
walletSchema.add({
  lastBalanceSync: {
    type: Date
  },
  lastBalanceUpdate: {
    type: Date
  },
  processedTransactionIds: {
    type: [String],
    default: []
  }
});

// Define Wallet model
const Wallet = mongoose.model('Wallet', walletSchema);

// Export models
module.exports = Wallet;
module.exports.ProcessedTransaction = ProcessedTransaction;

// Indexes are managed in config/database.js

// Add validation middleware for transactions
walletSchema.pre('save', async function (next) {
  if (this.isModified('transactions')) {
    try {
      // Ensure all transaction amounts are properly formatted
      this.transactions.forEach(transaction => {
        if (transaction.amount) {
          transaction.amount = formatBTC(transaction.amount);
        }
        if (transaction.netAmount) {
          transaction.netAmount = formatBTC(transaction.netAmount);
        }
      });
    } catch (error) {
      return next(new Error(`Transaction validation failed: ${error.message}`));
    }
  }
  next();
});

// Sync and queue management
const syncLocks = new Map();
const processedTransactionCache = new Set();

const acquireSyncLock = async (walletId, timeout = 30000) => {
  if (syncLocks.has(walletId)) {
    // Lock already exists, wait for it
    const start = Date.now();
    while (syncLocks.has(walletId)) {
      if (Date.now() - start > timeout) {
        return false;
      }
      await new Promise(resolve => setTimeout(resolve, 100));
    }
  }
  syncLocks.set(walletId, true);
  return true;
};

const releaseSyncLock = (walletId) => {
  syncLocks.delete(walletId);
};

function getTransactionQueue(walletId) {
  if (!transactionQueues.has(walletId)) {
    transactionQueues.set(walletId, Promise.resolve());
  }
  return transactionQueues.get(walletId);
}

async function queueAndExecute(walletId, operation) {
  const queue = getTransactionQueue(walletId);
  const result = queue.then(operation).finally(() => {
    // Clean up the queue if this was the last operation
    if (transactionQueues.get(walletId) === result) {
      transactionQueues.delete(walletId);
    }
  });
  transactionQueues.set(walletId, result);
  return result;
};

// Enhanced transaction processing method with queueing and atomic updates
walletSchema.methods.processTransaction = async function (transactionData) {
  return queueAndExecute(this.walletId, async () => {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      // Special handling for balance sync
      if (transactionData.type === 'balance_sync') {
        return await this.handleBalanceSync(transactionData);
      }

      // Check if sync is in progress
      if (syncLocks.has(this.walletId)) {
        console.log(`Sync in progress for wallet ${this.walletId}, deferring transaction processing`);
        return {
          success: false,
          status: 'deferred',
          message: 'Balance sync in progress'
        };
      }

      // Validate transaction data
      if (!transactionData?.transactionId || !transactionData?.amount) {
        throw new Error('Invalid transaction data: missing required fields');
      }

      // Format amount to 18 decimal places
      const amount = formatBTC(transactionData.amount);
      if (!amount || !/^\d+\.\d{18}$/.test(amount)) {
        throw new Error('Invalid transaction amount format');
      }

      // Check for duplicate transaction - both in DB and memory cache
      if (processedTransactionCache.has(transactionData.transactionId)) {
        return {
          success: true,
          status: 'skipped',
          message: 'Transaction already processed (cached)'
        };
      }

      const processed = await ProcessedTransaction.findOne({
        transactionId: transactionData.transactionId
      }).session(session);

      if (processed) {
        processedTransactionCache.add(transactionData.transactionId);
        return {
          success: true,
          status: 'skipped',
          message: 'Transaction already processed'
        };
      }

      // Get current wallet state atomically
      const currentWallet = await this.model('Wallet').findOne({
        _id: this._id
      }).select('balance transactions').session(session);

      if (!currentWallet) {
        throw new Error('Wallet not found');
      }

      // Calculate new balance using BigNumber for precision
      const currentBalance = new BigNumber(currentWallet.balance || '0.000000000000000000');
      const transactionAmount = new BigNumber(amount);
      let newBalance;

      if (['withdrawal', 'penalty'].includes(transactionData.type)) {
        if (currentBalance.isLessThan(transactionAmount)) {
          throw new Error('Insufficient balance for withdrawal');
        }
        newBalance = currentBalance.minus(transactionAmount);
      } else if (['deposit', 'reward', 'mining', 'earning', 'referral',
        'daily_reward', 'gaming_reward', 'claim', 'tap'].includes(transactionData.type)) {
        newBalance = currentBalance.plus(transactionAmount);
      } else {
        throw new Error(`Invalid transaction type: ${transactionData.type}`);
      }

      // Format final balance
      const formattedBalance = formatBTC(newBalance.toString());

      // Update wallet atomically
      const updatedWallet = await this.model('Wallet').findOneAndUpdate(
        {
          _id: this._id,
          balance: currentWallet.balance // Ensure balance hasn't changed
        },
        {
          $set: {
            balance: formattedBalance,
            lastUpdated: new Date()
          },
          $push: {
            transactions: {
              ...transactionData,
              amount,
              netAmount: formatBTC(transactionData.netAmount || amount),
              status: 'completed',
              timestamp: new Date(),
              details: {
                balanceBefore: currentWallet.balance,
                balanceAfter: formattedBalance,
                exchangeRate: transactionData.exchangeRate || 0,
                localAmount: transactionData.localAmount || '0.00',
                originalAmount: amount,
                originalNetAmount: formatBTC(transactionData.netAmount || amount)
              }
            },
            balanceHistory: {
              balance: formattedBalance,
              timestamp: new Date(),
              type: transactionData.type,
              amount: amount,
              transactionId: transactionData.transactionId,
              oldBalance: currentWallet.balance
            }
          }
        },
        { new: true, session }
      );

      if (!updatedWallet) {
        throw new Error('Failed to update wallet - balance may have changed');
      }

      // Record successful processing
      await ProcessedTransaction.create([{
        transactionId: transactionData.transactionId,
        processedAt: new Date()
      }], { session });

      // Add to memory cache
      processedTransactionCache.add(transactionData.transactionId);

      await session.commitTransaction();

      // Update instance state
      Object.assign(this, updatedWallet);

      console.log(`Transaction processed successfully:
        ID: ${transactionData.transactionId}
        Type: ${transactionData.type}
        Amount: ${amount}
        Old Balance: ${currentWallet.balance}
        New Balance: ${formattedBalance}`);

      return {
        success: true,
        status: 'completed',
        oldBalance: currentWallet.balance,
        newBalance: formattedBalance,
        amount: amount
      };

    } catch (error) {
      await session.abortTransaction();
      console.error('Transaction processing error:', {
        transactionId: transactionData?.transactionId,
        error: error.message
      });

      return {
        success: false,
        status: 'failed',
        error: error.message
      };

    } finally {
      session.endSession();
    }
  });
};

// Add wallet balance verification and repair methods
walletSchema.methods.verifyBalance = async function () {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    if (this.syncInProgress) {
      return {
        success: false,
        status: 'locked',
        message: 'Wallet sync in progress'
      };
    }

    // Calculate expected balance from completed transactions
    const { balance: calculatedBalance, history, processedTransactions } =
      await calculateBalanceFromTransactions(this.transactions);

    // Check if current balance matches calculated balance
    if (this.balance !== calculatedBalance) {
      console.log(`Balance mismatch detected for wallet ${this.walletId}:
        Current: ${this.balance}
        Calculated: ${calculatedBalance}
        Transactions: ${this.transactions.length}
        Processed IDs: ${processedTransactions.length}`);

      // Update wallet with correct balance
      const updatedWallet = await this.model('Wallet').findOneAndUpdate(
        { _id: this._id },
        {
          $set: {
            balance: calculatedBalance,
            lastUpdated: new Date(),
            lastBalanceSync: new Date(),
            processedTransactionIds: processedTransactions,
            numericBalance: parseFloat(calculatedBalance)
          },
          $push: {
            balanceHistory: {
              balance: calculatedBalance,
              timestamp: new Date(),
              type: 'balance_repair',
              amount: decimalUtils.subtract(calculatedBalance, this.balance),
              oldBalance: this.balance
            }
          }
        },
        { new: true, session }
      );

      if (!updatedWallet) {
        throw new Error('Failed to update wallet during balance repair');
      }

      // Update processed transaction cache
      processedTransactions.forEach(txId => processedTransactionCache.add(txId));

      await session.commitTransaction();

      // Update instance state
      Object.assign(this, updatedWallet);

      return {
        success: true,
        status: 'repaired',
        oldBalance: this.balance,
        newBalance: calculatedBalance,
        difference: decimalUtils.subtract(calculatedBalance, this.balance),
        transactionsProcessed: processedTransactions.length
      };
    }

    await session.commitTransaction();
    return {
      success: true,
      status: 'verified',
      balance: this.balance,
      transactionsProcessed: processedTransactions.length
    };

  } catch (error) {
    await session.abortTransaction();
    console.error('Balance verification error:', error);
    return {
      success: false,
      status: 'error',
      error: error.message
    };
  } finally {
    session.endSession();
  }
};

// Method to reprocess transactions and fix balance
walletSchema.methods.reprocessTransactions = async function () {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    // Get all completed transactions ordered by timestamp
    const completedTransactions = this.transactions
      .filter(tx => tx.status === 'completed')
      .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

    // Track processed transactions
    const processedTxIds = new Set(this.processedTransactionIds || []);
    let balance = new BigNumber('0.000000000000000000');
    const balanceHistory = [];

    // Reprocess each transaction
    for (const tx of completedTransactions) {
      try {
        // Skip if already processed and verified
        if (processedTxIds.has(tx.transactionId)) {
          continue;
        }

        const prevBalance = new BigNumber(balance);
        const amount = new BigNumber(tx.amount);

        // Update balance based on transaction type
        if (['deposit', 'reward', 'mining', 'earning', 'referral',
          'daily_reward', 'gaming_reward', 'claim', 'tap'].includes(tx.type)) {
          balance = balance.plus(amount);
        } else if (['withdrawal', 'penalty'].includes(tx.type)) {
          if (balance.isLessThan(amount)) {
            console.warn(`Insufficient balance for transaction ${tx.transactionId}`, {
              balance: balance.toString(),
              amount: amount.toString()
            });
            continue;
          }
          balance = balance.minus(amount);
        }

        // Update transaction details
        tx.details = tx.details || {};
        tx.details.balanceBefore = formatBTC(prevBalance.toString());
        tx.details.balanceAfter = formatBTC(balance.toString());

        // Record balance history
        balanceHistory.push({
          balance: formatBTC(balance.toString()),
          timestamp: tx.timestamp,
          type: tx.type,
          amount: formatBTC(amount.toString()),
          transactionId: tx.transactionId,
          oldBalance: formatBTC(prevBalance.toString())
        });

        // Mark as processed
        processedTxIds.add(tx.transactionId);

      } catch (error) {
        console.error('Error reprocessing transaction:', {
          transactionId: tx.transactionId,
          error: error.message
        });
      }
    }

    // Update wallet with reprocessed data
    const updatedWallet = await this.model('Wallet').findOneAndUpdate(
      { _id: this._id },
      {
        $set: {
          balance: formatBTC(balance.toString()),
          lastUpdated: new Date(),
          processedTransactionIds: Array.from(processedTxIds),
          numericBalance: balance.toNumber(),
          transactions: completedTransactions
        },
        $push: {
          balanceHistory: {
            $each: balanceHistory
          }
        }
      },
      { new: true, session }
    );

    if (!updatedWallet) {
      throw new Error('Failed to update wallet after reprocessing');
    }

    await session.commitTransaction();

    // Update instance state
    Object.assign(this, updatedWallet);

    return {
      success: true,
      status: 'reprocessed',
      finalBalance: formatBTC(balance.toString()),
      transactionsProcessed: processedTxIds.size,
      historyRecords: balanceHistory.length
    };

  } catch (error) {
    await session.abortTransaction();
    console.error('Transaction reprocessing error:', error);
    return {
      success: false,
      status: 'error',
      error: error.message
    };
  } finally {
    session.endSession();
  }
};

// Pre-save middleware to verify balance
walletSchema.pre('save', async function (next) {
  try {
    if (this.isModified('transactions') || this.isModified('balance')) {
      // Skip verification if sync is in progress
      if (!this.syncInProgress) {
        const result = await this.verifyBalance();
        if (!result.success) {
          return next(new Error(`Balance verification failed: ${result.error}`));
        }
      }
    }
    next();
  } catch (error) {
    next(error);
  }
});


