// Get correct transaction type based on payment method
const getTransactionType = (method) => {
  switch (method.toLowerCase()) {
    case 'paytm':
      return 'withdrawal_paytm';
    case 'paypal':
      return 'withdrawal_paypal';
    case 'btc':
    case 'bitcoin':
      return 'withdrawal_bitcoin';
    default:
      throw new Error('Invalid payment method');
  }
};

// Format transaction type for display
const formatTransactionType = (type) => {
  switch (type) {
    case 'withdrawal_paytm':
      return 'Withdrawal - Paytm';
    case 'withdrawal_paypal':
      return 'Withdrawal - Paypal';
    case 'withdrawal_bitcoin':
      return 'Withdrawal - Bitcoin';
    default:
      return type;
  }
};

module.exports = {
  getTransactionType,
  formatTransactionType
}; 