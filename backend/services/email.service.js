const nodemailer = require('nodemailer');
const logger = require('../utils/logger');
const {
  getOTPTemplate,
  getPromotionalTemplate,
  getNotificationTemplate
} = require('../utils/emailTemplates');

if (!process.env.GMAIL_USER || !process.env.GMAIL_APP_PASSWORD) {
  logger.error('❌ Missing Gmail credentials in environment variables');
  process.exit(1);
}

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD
  }
});

// Verify connection on startup
transporter.verify()
  .then(() => logger.info('✅ Email service connected successfully'))
  .catch(error => {
    logger.error('❌ Email service connection failed:', error);
    process.exit(1);
  });

const sendVerificationEmail = async (email, otp) => {
  try {
    logger.info(`📧 Sending verification email to ${email}`);

    const mailOptions = {
      from: `"Bitcoin Cloud Mining" <${process.env.GMAIL_USER}>`,
      to: email,
      subject: 'Verify Your Email',
      html: getOTPTemplate(otp, 'verification', 10)
    };

    const info = await transporter.sendMail(mailOptions);
    logger.info('✅ Verification email sent:', info.messageId);
    return true;
  } catch (error) {
    logger.error('❌ Error sending verification email:', error);
    throw error;
  }
};

const sendPasswordResetEmail = async (email, otp) => {
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
    logger.error('❌ Error sending password reset email:', error);
    throw error;
  }
};

const sendTransactionNotification = async (user, transaction) => {
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
    logger.error('❌ Error sending transaction notification:', error);
    throw error;
  }
};

const sendPromotionalEmail = async (email, promotion) => {
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
    logger.error('❌ Error sending promotional email:', error);
    throw error;
  }
};

const sendRewardNotification = async (user, reward) => {
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
    logger.error('❌ Error sending reward notification:', error);
    throw error;
  }
};

module.exports = {
  sendVerificationEmail,
  sendPasswordResetEmail,
  sendTransactionNotification,
  sendPromotionalEmail,
  sendRewardNotification
};