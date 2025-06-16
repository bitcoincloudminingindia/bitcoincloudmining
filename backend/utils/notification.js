const { sendTransactionNotification } = require('./email');

exports.sendNotification = async (email, subject, data) => {
  try {
    if (data.type === 'transaction') {
      await sendTransactionNotification(email, data);
    }
    return true;
  } catch (error) {
    console.error('Error sending notification:', error);
    return false;
  }
}; 