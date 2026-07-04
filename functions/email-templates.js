// ═══════════════════════════════════════════════════════════════════════════════
// GupShupGo — Professional Email Templates
// ═══════════════════════════════════════════════════════════════════════════════
// Table-based, inline-CSS HTML emails compatible with Gmail, Outlook, Apple Mail,
// Yahoo, and all major email clients. No external stylesheets.
//
// Brand palette (from app_theme.dart):
//   Primary:   #6C5CE7  (vibrant purple-indigo)
//   PrimaryDk: #5246BE
//   Surface:   #FFFFFF
//   TextHigh:  #1E293B
//   TextMid:   #64748B
//   TextLow:   #94A3B8
//   Success:   #10B981
//   Warning:   #F59E0B
//   Error:     #EF4444
// ═══════════════════════════════════════════════════════════════════════════════

const BRAND = {
  name: "GupShupGo",
  primary: "#6C5CE7",
  primaryDark: "#5246BE",
  primaryLight: "#EDE9FE",
  surface: "#FFFFFF",
  bgOuter: "#F5F3FF",
  textHigh: "#1E293B",
  textMid: "#64748B",
  textLow: "#94A3B8",
  border: "#E4E1F5",
  success: "#10B981",
  warning: "#F59E0B",
  error: "#EF4444",
  fontStack:
    "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif",
  supportEmail: "gupshupgo.support@gmail.com",
  playStoreUrl: "https://play.google.com/store/apps/details?id=com.gupshupgo.app",
};

// ─── Shared Layout ─────────────────────────────────────────────────────────────

function emailWrapper(preheader, bodyContent, unsubscribeUrl) {
  return `<!DOCTYPE html>
<html lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="x-apple-disable-message-reformatting">
  <title>${BRAND.name}</title>
  <!--[if mso]>
  <noscript>
    <xml>
      <o:OfficeDocumentSettings>
        <o:AllowPNG/>
        <o:PixelsPerInch>96</o:PixelsPerInch>
      </o:OfficeDocumentSettings>
    </xml>
  </noscript>
  <![endif]-->
</head>
<body style="margin:0;padding:0;background-color:${BRAND.bgOuter};font-family:${BRAND.fontStack};-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;">
  <!-- Preheader (hidden preview text) -->
  <div style="display:none;font-size:1px;color:${BRAND.bgOuter};line-height:1px;max-height:0;max-width:0;opacity:0;overflow:hidden;">
    ${preheader}
  </div>

  <!-- Outer wrapper -->
  <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:${BRAND.bgOuter};">
    <tr>
      <td align="center" style="padding:32px 16px;">

        <!-- Inner card -->
        <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="max-width:580px;background-color:${BRAND.surface};border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(108,92,231,0.08);">

          <!-- Header bar -->
          <tr>
            <td style="background:linear-gradient(135deg, ${BRAND.primary} 0%, ${BRAND.primaryDark} 100%);padding:24px 32px;text-align:center;">
              <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="center">
                    <img src="cid:email_logo" alt="${BRAND.name}" height="48" style="display:block;margin:0 auto;height:48px;border:0;outline:none;text-decoration:none;" />
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Body content -->
          <tr>
            <td style="padding:32px 32px 24px 32px;">
              ${bodyContent}
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 32px;">
              <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td style="border-top:1px solid ${BRAND.border};"></td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:20px 32px 28px 32px;text-align:center;">
              <p style="margin:0 0 8px 0;font-size:13px;color:${BRAND.textLow};line-height:1.6;">
                You received this email because you have an account with ${BRAND.name}.
              </p>
              ${unsubscribeUrl ? `<p style="margin:0 0 8px 0;font-size:13px;">
                <a href="${unsubscribeUrl}" style="color:${BRAND.primary};text-decoration:underline;">Unsubscribe from emails</a>
              </p>` : ""}
              <p style="margin:0;font-size:12px;color:${BRAND.textLow};">
                &copy; ${new Date().getFullYear()} ${BRAND.name} &middot; All rights reserved
              </p>
            </td>
          </tr>

        </table>
        <!-- End inner card -->

      </td>
    </tr>
  </table>
</body>
</html>`;
}

// ─── Reusable button ───────────────────────────────────────────────────────────

function ctaButton(text, url) {
  return `<table role="presentation" cellpadding="0" cellspacing="0" style="margin:24px auto 8px auto;">
  <tr>
    <td align="center" style="background-color:${BRAND.primary};border-radius:12px;">
      <a href="${url}" target="_blank" style="display:inline-block;padding:14px 36px;font-size:15px;font-weight:600;color:#FFFFFF;text-decoration:none;font-family:${BRAND.fontStack};letter-spacing:0.2px;">
        ${text}
      </a>
    </td>
  </tr>
</table>`;
}

// ─── Reusable stat box ─────────────────────────────────────────────────────────

function statBox(label, value, color) {
  return `<td align="center" style="padding:12px 8px;">
  <div style="font-size:28px;font-weight:800;color:${color || BRAND.primary};line-height:1.2;">${value}</div>
  <div style="font-size:12px;color:${BRAND.textMid};margin-top:4px;text-transform:uppercase;letter-spacing:0.5px;">${label}</div>
</td>`;
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 1: Welcome Email
// ═══════════════════════════════════════════════════════════════════════════════

function welcomeEmail(name, unsubscribeUrl) {
  const body = `
    <h1 style="margin:0 0 8px 0;font-size:24px;font-weight:700;color:${BRAND.textHigh};line-height:1.3;">
      Welcome to ${BRAND.name}, ${escHtml(name)}.
    </h1>
    <p style="margin:0 0 20px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;">
      We're glad you're here. ${BRAND.name} is built for real conversations — fast messaging, 
      crystal-clear calls, and a few surprises along the way.
    </p>

    <!-- Feature highlights -->
    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="margin-bottom:20px;">
      <tr>
        <td style="padding:14px 16px;background-color:${BRAND.bgOuter};border-radius:12px;margin-bottom:8px;">
          <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
            <tr>
              <td width="40" valign="top" style="padding-right:12px;">
                <div style="width:36px;height:36px;background-color:${BRAND.primaryLight};border-radius:10px;text-align:center;line-height:36px;font-size:18px;">&#128172;</div>
              </td>
              <td valign="top">
                <div style="font-size:14px;font-weight:600;color:${BRAND.textHigh};margin-bottom:2px;">End-to-End Encrypted Chat</div>
                <div style="font-size:13px;color:${BRAND.textMid};line-height:1.5;">Your messages are secured with the Signal Protocol. Only you and the person you're talking to can read them.</div>
              </td>
            </tr>
          </table>
        </td>
      </tr>
      <tr><td style="height:8px;"></td></tr>
      <tr>
        <td style="padding:14px 16px;background-color:${BRAND.bgOuter};border-radius:12px;">
          <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
            <tr>
              <td width="40" valign="top" style="padding-right:12px;">
                <div style="width:36px;height:36px;background-color:${BRAND.primaryLight};border-radius:10px;text-align:center;line-height:36px;font-size:18px;">&#128293;</div>
              </td>
              <td valign="top">
                <div style="font-size:14px;font-weight:600;color:${BRAND.textHigh};margin-bottom:2px;">Bonds &amp; Streaks</div>
                <div style="font-size:13px;color:${BRAND.textMid};line-height:1.5;">Build daily streaks with friends. Hit milestones at 7, 30, 100, and 365 days to unlock achievements.</div>
              </td>
            </tr>
          </table>
        </td>
      </tr>
      <tr><td style="height:8px;"></td></tr>
      <tr>
        <td style="padding:14px 16px;background-color:${BRAND.bgOuter};border-radius:12px;">
          <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
            <tr>
              <td width="40" valign="top" style="padding-right:12px;">
                <div style="width:36px;height:36px;background-color:${BRAND.primaryLight};border-radius:10px;text-align:center;line-height:36px;font-size:18px;">&#9889;</div>
              </td>
              <td valign="top">
                <div style="font-size:14px;font-weight:600;color:${BRAND.textHigh};margin-bottom:2px;">Gup Points &amp; Rewards</div>
                <div style="font-size:13px;color:${BRAND.textMid};line-height:1.5;">Earn points by chatting, maintaining streaks, and completing challenges. Level up and collect badges.</div>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>

    <p style="margin:0 0 4px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;">
      Open the app, find someone you know, and start your first conversation.
    </p>

    ${ctaButton("Open GupShupGo", BRAND.playStoreUrl)}
  `;

  return {
    subject: `Welcome to ${BRAND.name}, ${name}`,
    html: emailWrapper(
      `${name}, welcome to GupShupGo — encrypted messaging, streaks, and more.`,
      body,
      unsubscribeUrl
    ),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 2: Login Alert
// ═══════════════════════════════════════════════════════════════════════════════

function loginAlertEmail(name, device, loginTime, unsubscribeUrl) {
  const body = `
    <h1 style="margin:0 0 8px 0;font-size:24px;font-weight:700;color:${BRAND.textHigh};line-height:1.3;">
      New sign-in to your account
    </h1>
    <p style="margin:0 0 20px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;">
      Hi ${escHtml(name)}, we detected a new sign-in to your ${BRAND.name} account. If this was you, no action is needed.
    </p>

    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:${BRAND.bgOuter};border-radius:12px;padding:20px 24px;margin-bottom:20px;">
      <tr>
        <td style="padding:8px 0;">
          <span style="font-size:13px;color:${BRAND.textLow};text-transform:uppercase;letter-spacing:0.5px;">Device</span><br>
          <span style="font-size:15px;color:${BRAND.textHigh};font-weight:500;">${escHtml(device)}</span>
        </td>
      </tr>
      <tr>
        <td style="border-top:1px solid ${BRAND.border};padding:8px 0;">
          <span style="font-size:13px;color:${BRAND.textLow};text-transform:uppercase;letter-spacing:0.5px;">Time</span><br>
          <span style="font-size:15px;color:${BRAND.textHigh};font-weight:500;">${escHtml(loginTime)}</span>
        </td>
      </tr>
    </table>

    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:#FEF2F2;border-radius:12px;padding:16px 20px;margin-bottom:8px;">
      <tr>
        <td>
          <p style="margin:0;font-size:14px;color:#991B1B;line-height:1.6;">
            <strong>Wasn't you?</strong> Change your password immediately and review your linked sign-in methods in Settings.
          </p>
        </td>
      </tr>
    </table>
  `;

  return {
    subject: `New sign-in to your ${BRAND.name} account`,
    html: emailWrapper(
      `A new device signed into your ${BRAND.name} account at ${loginTime}.`,
      body,
      unsubscribeUrl
    ),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 3: Streak Broken
// ═══════════════════════════════════════════════════════════════════════════════

function streakBrokenEmail(name, contactName, streakDays, unsubscribeUrl) {
  const body = `
    <div style="text-align:center;margin-bottom:20px;">
      <div style="display:inline-block;width:64px;height:64px;background-color:#FEF2F2;border-radius:50%;line-height:64px;font-size:32px;text-align:center;">&#128148;</div>
    </div>

    <h1 style="margin:0 0 8px 0;font-size:24px;font-weight:700;color:${BRAND.textHigh};line-height:1.3;text-align:center;">
      Your ${streakDays}-day bond broke
    </h1>
    <p style="margin:0 0 20px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;text-align:center;">
      Hi ${escHtml(name)}, your streak with <strong style="color:${BRAND.textHigh};">${escHtml(contactName)}</strong> 
      has ended after ${streakDays} days. These things happen — what matters is picking it back up.
    </p>

    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:${BRAND.bgOuter};border-radius:12px;margin-bottom:20px;">
      <tr>
        ${statBox("Previous Streak", `${streakDays}`, BRAND.error)}
        ${statBox("Current Streak", "0", BRAND.textLow)}
      </tr>
    </table>

    <p style="margin:0 0 4px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;text-align:center;">
      Send a message to ${escHtml(contactName)} to start rebuilding your bond.
    </p>

    ${ctaButton("Restart Your Bond", BRAND.playStoreUrl)}
  `;

  return {
    subject: `Your ${streakDays}-day bond with ${contactName} broke`,
    html: emailWrapper(
      `Your ${streakDays}-day streak with ${contactName} has ended. Start a new one today.`,
      body,
      unsubscribeUrl
    ),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 4: Streak Milestone
// ═══════════════════════════════════════════════════════════════════════════════

function streakMilestoneEmail(name, contactName, milestone, unsubscribeUrl) {
  const milestoneConfig = {
    7: { emoji: "&#128293;", label: "One Week", color: BRAND.warning },
    30: { emoji: "&#128142;", label: "One Month", color: BRAND.primary },
    100: { emoji: "&#127942;", label: "Century", color: "#D97706" },
    365: { emoji: "&#128081;", label: "One Year", color: "#7C3AED" },
  };

  const config = milestoneConfig[milestone] || {
    emoji: "&#11088;",
    label: `${milestone} Days`,
    color: BRAND.primary,
  };

  const body = `
    <div style="text-align:center;margin-bottom:20px;">
      <div style="display:inline-block;width:72px;height:72px;background:linear-gradient(135deg, ${BRAND.primaryLight} 0%, #F5F3FF 100%);border-radius:50%;line-height:72px;font-size:36px;text-align:center;">${config.emoji}</div>
    </div>

    <h1 style="margin:0 0 8px 0;font-size:24px;font-weight:700;color:${BRAND.textHigh};line-height:1.3;text-align:center;">
      ${config.label} Milestone
    </h1>
    <p style="margin:0 0 20px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;text-align:center;">
      ${escHtml(name)}, you and <strong style="color:${BRAND.textHigh};">${escHtml(contactName)}</strong> 
      have maintained your bond for <strong style="color:${config.color};">${milestone} days straight</strong>. 
      That's real commitment.
    </p>

    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:${BRAND.bgOuter};border-radius:12px;margin-bottom:20px;">
      <tr>
        ${statBox("Current Streak", `${milestone}`, config.color)}
        ${statBox("Milestone", config.label, BRAND.success)}
      </tr>
    </table>

    <p style="margin:0 0 4px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;text-align:center;">
      Keep going — your next milestone is within reach.
    </p>

    ${ctaButton("View Your Bonds", BRAND.playStoreUrl)}
  `;

  return {
    subject: `${milestone}-day milestone with ${contactName}`,
    html: emailWrapper(
      `You and ${contactName} hit a ${milestone}-day streak milestone on GupShupGo.`,
      body,
      unsubscribeUrl
    ),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 5: Weekly Digest
// ═══════════════════════════════════════════════════════════════════════════════

function weeklyDigestEmail(name, stats, unsubscribeUrl) {
  // stats: { messagesSent, activeBonds, longestStreak, gupPointsEarned }
  const s = {
    messagesSent: stats.messagesSent || 0,
    activeBonds: stats.activeBonds || 0,
    longestStreak: stats.longestStreak || 0,
    gupPointsEarned: stats.gupPointsEarned || 0,
  };

  const body = `
    <h1 style="margin:0 0 8px 0;font-size:24px;font-weight:700;color:${BRAND.textHigh};line-height:1.3;">
      Your weekly recap
    </h1>
    <p style="margin:0 0 24px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;">
      Hi ${escHtml(name)}, here's what happened on ${BRAND.name} this past week.
    </p>

    <!-- Stats grid -->
    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:${BRAND.bgOuter};border-radius:12px;margin-bottom:24px;">
      <tr>
        ${statBox("Messages Sent", s.messagesSent, BRAND.primary)}
        ${statBox("Active Bonds", s.activeBonds, BRAND.success)}
      </tr>
      <tr>
        ${statBox("Longest Streak", `${s.longestStreak}d`, BRAND.warning)}
        ${statBox("Points Earned", `+${s.gupPointsEarned}`, "#7C3AED")}
      </tr>
    </table>

    ${s.messagesSent === 0
      ? `<p style="margin:0 0 20px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;">
          It was a quiet week. Your friends are just a message away — open the app and say hello.
        </p>`
      : `<p style="margin:0 0 20px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;">
          Great week! Keep the momentum going and watch your bonds grow stronger.
        </p>`
    }

    ${ctaButton("Open GupShupGo", BRAND.playStoreUrl)}
  `;

  return {
    subject: `Your week on ${BRAND.name} — ${s.messagesSent} messages, ${s.activeBonds} active bonds`,
    html: emailWrapper(
      `Weekly recap: ${s.messagesSent} messages sent, ${s.activeBonds} active bonds, +${s.gupPointsEarned} points.`,
      body,
      unsubscribeUrl
    ),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 6: Inactivity Reminder
// ═══════════════════════════════════════════════════════════════════════════════

function inactivityReminderEmail(name, daysSince, unsubscribeUrl) {
  const body = `
    <h1 style="margin:0 0 8px 0;font-size:24px;font-weight:700;color:${BRAND.textHigh};line-height:1.3;">
      We haven't seen you in a while
    </h1>
    <p style="margin:0 0 20px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;">
      Hi ${escHtml(name)}, it's been ${daysSince} days since you last opened ${BRAND.name}. 
      Your conversations are waiting for you, and your bonds could use some attention.
    </p>

    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:${BRAND.bgOuter};border-radius:12px;padding:20px 24px;margin-bottom:20px;">
      <tr>
        <td>
          <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
            <tr>
              <td width="8" style="padding-right:12px;">
                <div style="width:4px;height:100%;background-color:${BRAND.warning};border-radius:2px;min-height:40px;">&nbsp;</div>
              </td>
              <td>
                <p style="margin:0;font-size:14px;color:${BRAND.textHigh};line-height:1.6;">
                  Active bonds need messages from both sides every day. If you've been away, 
                  some of your streaks may have already broken. There's still time to rebuild.
                </p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>

    ${ctaButton("Come Back", BRAND.playStoreUrl)}
  `;

  return {
    subject: `${escHtml(name)}, your friends on ${BRAND.name} miss you`,
    html: emailWrapper(
      `It's been ${daysSince} days since you last visited GupShupGo. Your conversations are waiting.`,
      body,
      unsubscribeUrl
    ),
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEMPLATE 7: Gup Points Earned
// ═══════════════════════════════════════════════════════════════════════════════

function gupPointsEarnedEmail(name, gained, total, unsubscribeUrl) {
  const level = Math.floor(total / 100) + 1;
  const progress = (total % 100);

  const body = `
    <div style="text-align:center;margin-bottom:20px;">
      <div style="display:inline-block;width:64px;height:64px;background:linear-gradient(135deg, ${BRAND.primaryLight} 0%, #F5F3FF 100%);border-radius:50%;line-height:64px;font-size:32px;text-align:center;">&#9889;</div>
    </div>

    <h1 style="margin:0 0 8px 0;font-size:24px;font-weight:700;color:${BRAND.textHigh};line-height:1.3;text-align:center;">
      +${gained} Gup Points earned
    </h1>
    <p style="margin:0 0 24px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;text-align:center;">
      Nice work, ${escHtml(name)}. Your activity on ${BRAND.name} just earned you 
      <strong style="color:${BRAND.primary};">${gained} points</strong>.
    </p>

    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="background-color:${BRAND.bgOuter};border-radius:12px;margin-bottom:8px;">
      <tr>
        ${statBox("Total Points", total, BRAND.primary)}
        ${statBox("Level", level, BRAND.success)}
      </tr>
    </table>

    <!-- Progress bar -->
    <table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="margin-bottom:24px;padding:0 16px;">
      <tr>
        <td style="padding:8px 0;">
          <div style="font-size:12px;color:${BRAND.textLow};margin-bottom:6px;text-align:center;">Progress to Level ${level + 1}: ${progress}/100</div>
          <div style="background-color:${BRAND.border};border-radius:6px;height:8px;overflow:hidden;">
            <div style="background:linear-gradient(90deg, ${BRAND.primary} 0%, ${BRAND.primaryDark} 100%);height:8px;border-radius:6px;width:${progress}%;"></div>
          </div>
        </td>
      </tr>
    </table>

    <p style="margin:0 0 4px 0;font-size:15px;color:${BRAND.textMid};line-height:1.7;text-align:center;">
      Keep chatting and completing challenges to level up faster.
    </p>

    ${ctaButton("View Your Progress", BRAND.playStoreUrl)}
  `;

  return {
    subject: `+${gained} Gup Points — you're now Level ${level}`,
    html: emailWrapper(
      `You earned ${gained} Gup Points on GupShupGo. Total: ${total} points (Level ${level}).`,
      body,
      unsubscribeUrl
    ),
  };
}

// ─── Utility ───────────────────────────────────────────────────────────────────

function escHtml(str) {
  if (!str) return "";
  return String(str)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

module.exports = {
  welcomeEmail,
  loginAlertEmail,
  streakBrokenEmail,
  streakMilestoneEmail,
  weeklyDigestEmail,
  inactivityReminderEmail,
  gupPointsEarnedEmail,
  BRAND,
};
