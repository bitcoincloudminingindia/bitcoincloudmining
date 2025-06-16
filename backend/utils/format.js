const BigNumber = require('bignumber.js');
const mongoose = require('mongoose');

// Configure BigNumber globally
BigNumber.config({
  DECIMAL_PLACES: 18,
  ROUNDING_MODE: BigNumber.ROUND_DOWN,
  FORMAT: {
    decimalSeparator: '.',
    groupSeparator: '',
    groupSize: 0,
    secondaryGroupSize: 0,
    fractionGroupSeparator: '',
    fractionGroupSize: 0
  }
});

const FORMAT_OPTIONS = {
  BTC: {
    decimals: 18,
    groupSize: 0,
    decimalSeparator: '.',
    groupSeparator: '',
    fractionGroupSize: 0
  },
  USD: {
    decimals: 2,
    groupSize: 0,
    decimalSeparator: '.',
    groupSeparator: '',
    fractionGroupSize: 0
  }
};

/**
 * Format BTC amount to exactly 18 decimal places
 * @param {number|string} amount - Amount to format
 * @returns {string} Formatted amount with exactly 18 decimal places
 */
const formatBTC = (amount) => {
  if (amount === undefined || amount === null) {
    return '0.000000000000000000';
  }

  try {
    // Convert amount to a processable format
    let processedAmount = amount;

    // If it's an object, try to get its value
    if (typeof amount === 'object') {
      // Handle MongoDB Decimal128
      if (amount instanceof mongoose.Types.Decimal128) {
        processedAmount = amount.toString();
      }
      // Handle mongoose document
      else if (amount._doc) {
        processedAmount = amount._doc;
      }
      // Handle wallet balance object
      else if (amount.balance !== undefined) {
        processedAmount = amount.balance;
      }
      // Handle objects with valueOf
      else if (amount.valueOf) {
        processedAmount = amount.valueOf();
      }
      // Handle objects with toString
      else if (amount.toString) {
        processedAmount = amount.toString();
      }
    }

    // Ensure we're working with a string
    processedAmount = processedAmount?.toString() || '0';

    // First convert from scientific notation if needed
    const normalizedValue = fromScientific(processedAmount);
    const bn = new BigNumber(normalizedValue);
    const isNegative = bn.isNegative();
    const absoluteValue = bn.abs();

    // Use toFixed instead of toFormat for more reliable decimal handling
    const formatted = absoluteValue.toFixed(18);
    return isNegative ? `-${formatted}` : formatted;
  } catch (error) {
    console.error('Error formatting BTC amount:', error);
    return '0.000000000000000000';
  }
};

/**
 * Format USD amount to exactly 2 decimal places
 * @param {number|string} amount - Amount to format
 * @returns {string} Formatted amount with exactly 2 decimal places
 */
const formatUSD = (amount) => {
  if (amount === undefined || amount === null) {
    return '0.00';
  }

  try {
    const bn = new BigNumber(amount);
    return bn.toFormat(FORMAT_OPTIONS.USD.decimals, FORMAT_OPTIONS.USD);
  } catch (error) {
    console.error('Error formatting USD amount:', error);
    return '0.00';
  }
};

/**
 * Convert a value to BigNumber instance
 * @param {number|string|BigNumber} value - Value to convert
 * @returns {BigNumber} BigNumber instance
 */
const toBigNumber = (value) => {
  if (value === undefined || value === null) {
    return new BigNumber(0);
  }

  try {
    // Handle different value types
    if (value instanceof BigNumber) {
      return value;
    }

    // Convert to string and handle scientific notation
    const strValue = value.toString();
    if (strValue.includes('e')) {
      return new BigNumber(fromScientific(strValue));
    }

    // Handle normal decimal strings and numbers
    return new BigNumber(strValue);
  } catch (error) {
    console.error('Error converting to BigNumber:', error);
    return new BigNumber(0);
  }
};

/**
 * Convert any numeric value (including scientific notation) to a fixed-point decimal string
 * @param {string|number} value - The value to convert
 * @returns {string} - The value in fixed-point decimal notation with 18 decimal places
 */
const fromScientific = (value) => {
  if (value === undefined || value === null) {
    return '0.000000000000000000';
  }
  try {
    // Handle objects
    let processedValue = value;
    if (typeof value === 'object') {
      if (value.balance !== undefined) {
        processedValue = value.balance;
      } else if (value.toString) {
        processedValue = value.toString();
      }
    }

    // Ensure we have a string
    processedValue = processedValue?.toString() || '0';

    // Create BigNumber instance
    const bn = new BigNumber(processedValue);

    // Force conversion to fixed-point notation with exactly 18 decimal places
    const result = bn.toFixed(18);

    // Ensure the result has exactly 18 decimal places
    const parts = result.split('.');
    const integer = parts[0] || '0';
    const fraction = (parts[1] || '').padEnd(18, '0');

    return `${integer}.${fraction}`;
  } catch (error) {
    console.error('Error converting from scientific notation:', error);
    return '0.000000000000000000';
  }
};

// Export all utilities
module.exports = {
  BigNumber,
  formatBTC,
  formatUSD,
  toBigNumber,
  fromScientific
};