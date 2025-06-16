// Fee rates (in percentage)
const FEE_RATES = {
  deposit: {
    BTC: 0.5, // 0.5% for Bitcoin deposits
    INR: 1.0  // 1% for INR deposits
  },
  withdrawal: {
    BTC: 20.0, // 20% for Bitcoin withdrawals
    INR: 2.0   // 2% for INR withdrawals
  },
  mining: 0,    // No fees for mining rewards
  referral: 0,  // No fees for referral rewards
  bonus: 0      // No fees for bonus rewards
};

// Minimum fees
const MIN_FEES = {
  BTC: 0.0001, // Minimum 0.0001 BTC
  INR: 10      // Minimum ₹10
};

// Calculate fees for a transaction
exports.calculateFees = async (type, amount, currency) => {
  // Get fee rate for transaction type and currency
  const feeRate = FEE_RATES[type]?.[currency] || 0;
  
  // Calculate fee amount
  let feeAmount;
  if (currency === 'BTC') {
    // For BTC, use percentage for all transactions
    feeAmount = amount * (feeRate / 100);
    // Ensure minimum fee
    feeAmount = Math.max(feeAmount, MIN_FEES.BTC);
  } else {
    // For INR, use percentage
    feeAmount = amount * (feeRate / 100);
    // Ensure minimum fee
    feeAmount = Math.max(feeAmount, MIN_FEES.INR);
  }

  return feeAmount;
}; 