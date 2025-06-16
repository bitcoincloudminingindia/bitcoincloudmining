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
              <img src="https://your-domain.com/logo.png" alt="Bitcoin Cloud Mining" style="width: 150px; height: auto;">
            </td>
          </tr>
          <!-- Content -->
          <tr>
            <td style="padding: 40px 30px;">
              ${content}
            </td>
          </tr>          <!-- Footer -->
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
                <a href="https://t.me/your_telegram" style="color: #1a237e; text-decoration: none; margin: 0 10px; font-size: 14px;">Telegram</a>
                <span style="color: #666;">|</span>
                <a href="https://discord.gg/your_discord" style="color: #1a237e; text-decoration: none; margin: 0 10px; font-size: 14px;">Discord</a>
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
    getPromotionalTemplate,
    getNotificationTemplate
};
