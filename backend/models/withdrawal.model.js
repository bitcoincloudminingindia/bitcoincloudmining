const mongoose = require('mongoose');
const Joi = require('joi');
const crypto = require('crypto');

// Drop existing model if it exists
mongoose.models = {};

const withdrawalSchema = new mongoose.Schema({
  withdrawalId: {
    type: String,
    required: true,
    unique: true,
    default: () => 'WD' + crypto.randomBytes(6).toString('hex').toUpperCase()
  },
  transactionId: {
    type: String,
    required: true,
    unique: true,
    default: () => 'TX' + crypto.randomBytes(6).toString('hex').toUpperCase()
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  amount: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        return !isNaN(parseFloat(v)) && parseFloat(v) > 0;
      },
      message: 'Amount must be a positive number'
    }
  },
  netAmount: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        return !isNaN(parseFloat(v)) && parseFloat(v) > 0;
      },
      message: 'Net amount must be a positive number'
    }
  },
  fees: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        return !isNaN(parseFloat(v)) && parseFloat(v) >= 0;
      },
      message: 'Fees must be a non-negative number'
    }
  },
  currency: {
    type: String,
    required: true,
    enum: ['BTC', 'USD', 'INR'],
    default: 'BTC'
  },
  destinationType: {
    type: String,
    required: true,
    enum: ['Paypal', 'Bank', 'UPI', 'Paytm', 'Crypto'],
    default: 'Paypal'
  },
  destinationAddress: {
    type: String,
    required: true
  },
  status: {
    type: String,
    required: true,
    enum: ['pending', 'processing', 'completed', 'failed', 'cancelled'],
    default: 'pending'
  },
  originalAmount: {
    type: String,
    required: true,
    validate: {
      validator: function(v) {
        return !isNaN(parseFloat(v)) && parseFloat(v) > 0;
      },
      message: 'Original amount must be a positive number'
    }
  },
  originalCurrency: {
    type: String,
    required: true,
    enum: ['BTC', 'USD', 'INR'],
    default: 'BTC'
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true,
  strict: true
});

// Create new indexes
withdrawalSchema.index({ withdrawalId: 1 }, { unique: true });
withdrawalSchema.index({ transactionId: 1 }, { unique: true });
withdrawalSchema.index({ user: 1, status: 1 });
withdrawalSchema.index({ timestamp: -1 });

// Validation function
const validateWithdrawal = (data) => {
  const schema = Joi.object({
    amount: Joi.string().required().custom((value, helpers) => {
      const num = parseFloat(value);
      if (isNaN(num) || num < 0.000000000000000001) {
        return helpers.error('any.invalid');
      }
      return value;
    }, 'amount-validation').messages({
      'any.invalid': 'Amount must be at least 0.000000000000000001 BTC'
    }),
    currency: Joi.string().valid('BTC', 'USD', 'INR').required(),
    method: Joi.string().valid('Paypal', 'Bank', 'UPI', 'Paytm', 'Crypto').required(),
    destination: Joi.string().required(),
    btcAmount: Joi.string().optional().custom((value, helpers) => {
      if (value) {
        const num = parseFloat(value);
        if (isNaN(num) || num < 0.000000000000000001) {
          return helpers.error('any.invalid');
        }
      }
      return value;
    }, 'btc-amount-validation').messages({
      'any.invalid': 'BTC amount must be at least 0.000000000000000001 BTC'
    }),
    status: Joi.string().valid('pending', 'processing', 'completed', 'failed', 'cancelled').default('pending'),
    timestamp: Joi.date().default(() => new Date())
  });

  const { error } = schema.validate(data, { 
    abortEarly: false,
    stripUnknown: true,
    convert: true
  });

  if (error) {
    const errorMessage = error.details.map(detail => detail.message).join(', ');
    return errorMessage;
  }
  return null;
};

const Withdrawal = mongoose.model('Withdrawal', withdrawalSchema);

module.exports = {
  Withdrawal,
  validateWithdrawal
};
