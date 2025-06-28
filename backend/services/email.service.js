const nodemailer = require('nodemailer');
const logger = require('../utils/logger');
const {
  getOTPTemplate,
  getOTPPlainText,
  getPromotionalTemplate,
  getNotificationTemplate
} = require('../utils/emailTemplates');

if (!process.env.GMAIL_USER || !process.env.GMAIL_APP_PASSWORD) {
  logger.error('❌ Missing Gmail credentials in environment variables');
  // Do not exit, just log the error
}

let emailServiceAvailable = true;

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD
  },
  // Add timeout and connection settings
  connectionTimeout: 30000, // 30 seconds
  greetingTimeout: 30000,   // 30 seconds
  socketTimeout: 30000,     // 30 seconds
  pool: true,               // Use pooled connections
  maxConnections: 5,        // Maximum connections in pool
  maxMessages: 100,         // Maximum messages per connection
  rateLimit: 14,            // Messages per second
  rateDelta: 1000,          // Time window for rate limiting
  // Retry settings
  retry: {
    retries: 3,
    factor: 2,
    minTimeout: 1000,
    maxTimeout: 5000
  }
});

// Verify connection on startup with timeout
const verifyEmailConnection = async () => {
  try {
    await transporter.verify();
    logger.info('✅ Email service connected successfully');
    emailServiceAvailable = true;
  } catch (error) {
    logger.error('❌ Email service connection failed:', error.message);
    emailServiceAvailable = false;
    // Don't exit, just log the error and set flag
  }
};

// Verify connection on startup
verifyEmailConnection();

const sendVerificationEmail = async (email, otp) => {
  if (!emailServiceAvailable) {
    logger.error('❌ Email service unavailable. Cannot send verification email.');
    return false;
  }
  try {
    logger.info(`📧 Sending verification email to ${email}`);

    const mailOptions = {
      from: `"Bitcoin Cloud Mining" <${process.env.GMAIL_USER}>`,
      to: email,
      subject: 'Verify Your Email',
      html: getOTPTemplate(otp, 'verification', 10) + '<p style="color:#888;font-size:12px;margin-top:20px;">If you find this email in your spam folder, please mark it as "Not Spam" to receive future emails in your inbox.</p>',
      text: require('../utils/emailTemplates').getOTPPlainText(otp, 'verification', 10),
      replyTo: process.env.GMAIL_USER
    };

    const info = await transporter.sendMail(mailOptions);
    logger.info('✅ Verification email sent:', info.messageId);
    return true;
  } catch (error) {
    logger.error('❌ Error sending verification email:', error.message);
    // Don't throw error, just return false
    return false;
  }
};

const sendPasswordResetEmail = async (email, otp) => {
  if (!emailServiceAvailable) {
    logger.error('❌ Email service unavailable. Cannot send password reset email.');
    return false;
  }
  try {
    logger.info(`📧 Sending password reset email to ${email}`);

    const mailOptions = {
      from: `"Bitcoin Cloud Mining" <${process.env.GMAIL_USER}>`,
      to: email,
      subject: 'Reset Your Password',
      html: getOTPTemplate(otp, 'password reset', 15)
    };

    const info = await transporter.sendMail(mailOptions);
    logger.info('✅ Password reset email sent:', info.messageId);
    return true;
  } catch (error) {
    logger.error('❌ Error sending password reset email:', error.message);
    return false;
  }
};

const sendTransactionNotification = async (user, transaction) => {
  if (!emailServiceAvailable) {
    logger.error('❌ Email service unavailable. Cannot send transaction notification.');
    return false;
  }
  try {
    const { type, amount, currency, status } = transaction;
    logger.info(`📧 Sending transaction notification to ${user.userEmail}`);

    const title = `Transaction ${status}: ${type}`;
    const message = `Your ${type} transaction of ${amount} ${currency} has been ${status}.`;
    const additionalInfo = `
      <strong>Transaction Details:</strong><br>
      Type: ${type}<br>
      Amount: ${amount} ${currency}<br>
      Status: ${status}<br>
      Date: ${new Date().toLocaleString()}
    `;

    const mailOptions = {
      from: `"Bitcoin Cloud Mining" <${process.env.GMAIL_USER}>`,
      to: user.userEmail,
      subject: title,
      html: getNotificationTemplate(title, message, additionalInfo)
    };

    const info = await transporter.sendMail(mailOptions);
    logger.info('✅ Transaction notification sent:', info.messageId);
    return true;
  } catch (error) {
    logger.error('❌ Error sending transaction notification:', error.message);
    return false;
  }
};

const sendPromotionalEmail = async (email, promotion) => {
  if (!emailServiceAvailable) {
    logger.error('❌ Email service unavailable. Cannot send promotional email.');
    return false;
  }
  try {
    logger.info(`📧 Sending promotional email to ${email}`);

    const { title, content, ctaText, ctaUrl } = promotion;
    const mailOptions = {
      from: `"Bitcoin Cloud Mining" <${process.env.GMAIL_USER}>`,
      to: email,
      subject: title,
      html: getPromotionalTemplate(title, content, ctaText, ctaUrl)
    };

    const info = await transporter.sendMail(mailOptions);
    logger.info('✅ Promotional email sent:', info.messageId);
    return true;
  } catch (error) {
    logger.error('❌ Error sending promotional email:', error.message);
    return false;
  }
};

const sendRewardNotification = async (user, reward) => {
  if (!emailServiceAvailable) {
    logger.error('❌ Email service unavailable. Cannot send reward notification.');
    return false;
  }
  try {
    logger.info(`📧 Sending reward notification to ${user.userEmail}`);

    const title = 'You Earned a Reward! 🎉';
    const message = `Congratulations! You've earned ${reward.amount} ${reward.currency} from ${reward.type}.`;
    const additionalInfo = `
      <strong>Reward Details:</strong><br>
      Type: ${reward.type}<br>
      Amount: ${reward.amount} ${reward.currency}<br>
      Date: ${new Date().toLocaleString()}
    `;

    const mailOptions = {
      from: `"Bitcoin Cloud Mining" <${process.env.GMAIL_USER}>`,
      to: user.userEmail,
      subject: title,
      html: getNotificationTemplate(title, message, additionalInfo)
    };

    const info = await transporter.sendMail(mailOptions);
    logger.info('✅ Reward notification sent:', info.messageId);
    return true;
  } catch (error) {
    logger.error('❌ Error sending reward notification:', error.message);
    return false;
  }
};

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendTransactionNotification,
  sendPromotionalEmail,
  sendRewardNotification
};