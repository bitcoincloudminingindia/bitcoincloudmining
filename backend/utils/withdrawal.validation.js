const Joi = require('joi');

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

module.exports = {
  validateWithdrawal
}; 