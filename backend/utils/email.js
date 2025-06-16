const nodemailer = require('nodemailer');

// Create reusable transporter
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: process.env.SMTP_PORT,
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

// Send email
exports.sendEmail = async ({ to, subject, text, html }) => {
  try {
    // Create email options
    const mailOptions = {
      from: process.env.SMTP_FROM,
      to,
      subject,
      text,
      html: html || text
    };

    // Send email
    const info = await transporter.sendMail(mailOptions);
    console.log('Email sent:', info.messageId);
    return info;
  } catch (error) {
    console.error('Error sending email:', error);
    throw error;
  }
};

// Send transaction notification
exports.sendTransactionNotification = async (user, transaction) => {
  const { type, amount, currency, status } = transaction;

  // Create email content
  const subject = `Transaction ${status}: ${type} of ${amount} ${currency}`;
  const text = `
    Hello ${user.username},

    Your ${type} transaction of ${amount} ${currency} has been ${status}.

    Transaction Details:
    - Type: ${type}
    - Amount: ${amount} ${currency}
    - Status: ${status}
    - Transaction ID: ${transaction.transactionId}
    - Date: ${transaction.timestamp}

    If you have any questions, please contact our support team.

    Best regards,
    Bitcoin Cloud Mining Team
  `;

  // Send email
  return exports.sendEmail({
    to: user.email,
    subject,
    text
  });
}; 