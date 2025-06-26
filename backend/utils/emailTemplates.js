const getBaseTemplate = (content) => `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Bitcoin Cloud Mining</title>
</head>
<body style="margin: 0; padding: 0; background-color: #f4f6f8; font-family: Arial, sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #f4f6f8;">
    <tr>
      <td style="padding: 20px 0;">
        <table role="presentation" width="600" align="center" cellspacing="0" cellpadding="0" style="margin: auto; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
          <!-- Header -->
          <tr>
            <td style="background: linear-gradient(135deg, #1a237e 0%, #0d47a1 100%); padding: 30px; text-align: center; border-radius: 8px 8px 0 0;">
              <img src="https://i.imgur.com/BX6a4RA.png" alt="Bitcoin Cloud Mining Logo" style="width: 120px; height: auto; margin-bottom: 10px; display: block; margin-left: auto; margin-right: auto;">
              <div style="margin-top: 10px; color: #fff; font-size: 14px; font-weight: bold;">If you find this email in your spam folder, please mark it as 'Not Spam' to receive future emails in your inbox.</div>
            </td>
          </tr>
          <!-- Not Spam Note -->
          <tr>
            <td style="padding: 10px 30px 0 30px; text-align: center;">
              <div style="background-color: #fffbe6; color: #b26a00; border: 1px solid #ffe082; border-radius: 6px; padding: 10px 15px; font-size: 14px; margin-bottom: 10px;">
                If you find this email in your spam or junk folder, please mark it as <b>Not Spam</b> to ensure you receive future updates in your inbox.
              </div>
            </td>
          </tr>
          <!-- Content -->
          <tr>
            <td style="padding: 40px 30px;">
              ${content}
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background-color: #f8f9fa; padding: 20px 30px; text-align: center; border-radius: 0 0 8px 8px;">
              <div style="margin-bottom: 20px;">
                <p style="margin: 0 0 10px; color: #1a237e; font-weight: bold; font-size: 16px;">
                  Bitcoin Cloud Mining
                </p>
                <p style="margin: 0; color: #666; font-size: 14px; line-height: 1.5;">
                  Your Trusted Platform for Cryptocurrency Mining
                </p>
              </div>
              <div style="margin-bottom: 15px;">
                <a href="https://t.me/+v6K5Agkb5r8wMjhl" style="color: #1a237e; text-decoration: none; margin: 0 10px; font-size: 14px;">Telegram</a>
                <span style="color: #666;">|</span>
                <a href="https://x.com/bitcoinclmining" style="color: #1a237e; text-decoration: none; margin: 0 10px; font-size: 14px;">X (Twitter)</a>
                <span style="color: #666;">|</span>
                <a href="https://www.instagram.com/bitcoincloudmining/" style="color: #1a237e; text-decoration: none; margin: 0 10px; font-size: 14px;">Instagram</a>
                <span style="color: #666;">|</span>
                <a href="https://www.youtube.com/channel/UC1V43aMm3KYUJu_J9Lx2DAw" style="color: #1a237e; text-decoration: none; margin: 0 10px; font-size: 14px;">YouTube</a>
                <span style="color: #666;">|</span>
                <a href="mailto:support@your-domain.com" style="color: #1a237e; text-decoration: none; margin: 0 10px; font-size: 14px;">Support</a>
              </div>
              <p style="margin: 15px 0 0; color: #666; font-size: 12px;">
                © ${new Date().getFullYear()} Bitcoin Cloud Mining. All rights reserved.<br>
                This email was sent to you as part of your Bitcoin Cloud Mining account services.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;

const getOTPTemplate = (otp, type = 'verification', expiryMinutes = 10) => {
  const title = type === 'verification' ? 'Email Verification' : 'Password Reset';
  return getBaseTemplate(`
    <h2 style="color: #1a237e; margin: 0 0 20px; font-size: 24px;">${title}</h2>
    <p style="color: #333; font-size: 16px; line-height: 24px;">Your ${type} code is:</p>
    <div style="background-color: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0; text-align: center;">
      <h1 style="color: #1a237e; font-size: 36px; letter-spacing: 8px; margin: 0;">${otp}</h1>
    </div>
    <p style="color: #666; font-size: 14px; line-height: 20px;">
      This code will expire in ${expiryMinutes} minutes.<br>
      If you didn't request this code, please ignore this email.
    </p>
    <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #eee;">
      <p style="color: #666; font-size: 14px; margin: 0;">
        For security reasons, never share this code with anyone.
      </p>
    </div>
  `);
};

const getOTPPlainText = (otp, type = 'verification', expiryMinutes = 10) => {
  const title = type === 'verification' ? 'Email Verification' : 'Password Reset';
  return `${title}\n\nYour ${type} code is: ${otp}\n\nThis code will expire in ${expiryMinutes} minutes.\nIf you didn't request this code, please ignore this email.\n\nFor security reasons, never share this code with anyone.\n\nIf you find this email in your spam folder, please mark it as \'Not Spam\' to receive future emails in your inbox.\n\n-- Bitcoin Cloud Mining`;
};

const getPromotionalTemplate = (title, content, ctaText, ctaUrl) => {
  return getBaseTemplate(`
    <h2 style="color: #1a237e; margin: 0 0 20px; font-size: 24px;">${title}</h2>
    <div style="color: #333; font-size: 16px; line-height: 24px;">
      ${content}
    </div>
    <div style="text-align: center; margin: 30px 0;">
      <a href="${ctaUrl}" style="display: inline-block; background: linear-gradient(135deg, #1a237e 0%, #0d47a1 100%); color: white; text-decoration: none; padding: 12px 30px; border-radius: 25px; font-weight: bold; text-transform: uppercase; font-size: 14px;">
        ${ctaText}
      </a>
    </div>
  `);
};

const getNotificationTemplate = (title, message, additionalInfo = null, actionUrl = null) => {
  let content = `
    <h2 style="color: #1a237e; margin: 0 0 20px; font-size: 24px;">${title}</h2>
    <div style="color: #333; font-size: 16px; line-height: 24px; margin-bottom: 20px;">
      ${message}
    </div>
  `;

  if (additionalInfo) {
    content += `
      <div style="background-color: #f8f9fa; border-radius: 8px; padding: 20px; margin: 20px 0;">
        <div style="color: #666; font-size: 14px; line-height: 20px;">
          ${additionalInfo}
        </div>
      </div>
    `;
  }

  if (actionUrl) {
    content += `
      <div style="text-align: center; margin: 30px 0;">
        <a href="${actionUrl}" style="display: inline-block; background: linear-gradient(135deg, #1a237e 0%, #0d47a1 100%); color: white; text-decoration: none; padding: 12px 30px; border-radius: 25px; font-weight: bold; font-size: 14px;">
          View Details
        </a>
      </div>
    `;
  }

  return getBaseTemplate(content);
};

module.exports = {
  getOTPTemplate,
  getOTPPlainText,
  getPromotionalTemplate,
  getNotificationTemplate
};
