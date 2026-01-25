const nodemailer = require('nodemailer');

// Create transporter
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: process.env.SMTP_PORT || 587,
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASSWORD
  }
});

/**
 * Send athlete invitation email
 */
async function sendInvitationEmail(email, name, inviteUrl) {
  try {
    const mailOptions = {
      from: {
        name: 'Coach Kura - SafeStride by AKURA',
        address: process.env.SMTP_USER || 'coach@akura.in'
      },
      to: email,
      subject: '🏃‍♂️ You\'re Invited to Join SafeStride by AKURA!',
      html: getInvitationEmailTemplate(name, inviteUrl)
    };
    
    const info = await transporter.sendMail(mailOptions);
    console.log('Invitation email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending invitation email:', error);
    throw error;
  }
}

/**
 * Invitation email template
 */
function getInvitationEmailTemplate(name, inviteUrl) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>SafeStride Invitation</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      background-color: #f4f4f4;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 40px auto;
      background: white;
      border-radius: 8px;
      overflow: hidden;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .header {
      background: linear-gradient(135deg, #2563EB 0%, #1E40AF 100%);
      color: white;
      padding: 40px 30px;
      text-align: center;
    }
    .header h1 {
      margin: 0;
      font-size: 28px;
      font-weight: 700;
    }
    .header p {
      margin: 10px 0 0 0;
      font-size: 16px;
      opacity: 0.9;
    }
    .content {
      padding: 40px 30px;
    }
    .content h2 {
      color: #2563EB;
      font-size: 22px;
      margin-top: 0;
    }
    .btn {
      display: inline-block;
      padding: 14px 32px;
      background: #2563EB;
      color: white;
      text-decoration: none;
      border-radius: 6px;
      font-weight: 600;
      margin: 20px 0;
      text-align: center;
    }
    .btn:hover {
      background: #1E40AF;
    }
    .features {
      background: #F3F4F6;
      padding: 20px;
      border-radius: 6px;
      margin: 20px 0;
    }
    .features ul {
      margin: 10px 0;
      padding-left: 20px;
    }
    .features li {
      margin: 8px 0;
    }
    .footer {
      background: #F9FAFB;
      padding: 30px;
      text-align: center;
      color: #6B7280;
      font-size: 14px;
    }
    .footer a {
      color: #2563EB;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🏃‍♂️ SafeStride by AKURA</h1>
      <p>Professional Running Coach Platform</p>
    </div>
    
    <div class="content">
      <h2>Welcome, ${name}!</h2>
      
      <p>Coach Kura has invited you to join SafeStride, a professional training platform designed to transform your running performance.</p>
      
      <div class="features">
        <strong>🎯 What You'll Get:</strong>
        <ul>
          <li><strong>Personalized Training:</strong> Workouts auto-synced to your Garmin/Strava</li>
          <li><strong>HR-Based Training:</strong> 5-zone system calculated from your Max HR</li>
          <li><strong>7 Protocol System:</strong> START, ENGINE, OXYGEN, POWER, ZONES, STRENGTH, LONG RUN</li>
          <li><strong>Auto Activity Tracking:</strong> Runs automatically matched to scheduled workouts</li>
          <li><strong>Progress Dashboard:</strong> Track your transformation to elite performance</li>
          <li><strong>Chennai-Optimized:</strong> Training adapted for Chennai's climate</li>
        </ul>
      </div>
      
      <p><strong>Your Next Steps:</strong></p>
      <ol>
        <li>Click the button below to create your account</li>
        <li>Complete your profile (age, weight, height)</li>
        <li>Connect your Garmin or Strava account</li>
        <li>Start receiving personalized workouts!</li>
      </ol>
      
      <div style="text-align: center; margin: 30px 0;">
        <a href="${inviteUrl}" class="btn">🚀 Join SafeStride Now</a>
      </div>
      
      <p style="font-size: 14px; color: #6B7280;">
        <em>Note: This invitation is valid for 7 days. If you have any questions, feel free to contact Coach Kura.</em>
      </p>
    </div>
    
    <div class="footer">
      <p><strong>Coach Kura Balendar Sathyamoorthy</strong></p>
      <p>
        📧 <a href="mailto:coach@akura.in">coach@akura.in</a><br>
        📱 <a href="https://wa.me/message/24CYRZY5TMH7F1">WhatsApp</a><br>
        📸 <a href="https://instagram.com/akura_safestride">@akura_safestride</a>
      </p>
      <p style="margin-top: 20px;">
        <a href="https://akura.in">akura.in</a> | SafeStride by AKURA © 2026
      </p>
    </div>
  </div>
</body>
</html>
  `;
}

module.exports = {
  sendInvitationEmail
};
