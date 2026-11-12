import twilio from 'twilio';
import { env } from '../../config/env.js';
import { logger } from '../logger/logger.js';

let twilioClient: twilio.Twilio | null = null;
let invalidConfigurationWarningLogged = false;

export function hasValidTwilioConfiguration(
  accountSid = env.TWILIO_ACCOUNT_SID,
  authToken = env.TWILIO_AUTH_TOKEN,
  phoneNumber = env.TWILIO_PHONE_NUMBER
): boolean {
  return /^AC[0-9a-f]{32}$/i.test(accountSid)
    && /^[0-9a-z]{32,64}$/i.test(authToken)
    && /^\+[1-9]\d{7,14}$/.test(phoneNumber);
}

function getClient(): twilio.Twilio | null {
  if (twilioClient) return twilioClient;

  if (!hasValidTwilioConfiguration()) {
    if (!invalidConfigurationWarningLogged) {
      logger.warn('Twilio is missing or invalid — SMS delivery is unavailable');
      invalidConfigurationWarningLogged = true;
    }
    return null;
  }

  twilioClient = twilio(env.TWILIO_ACCOUNT_SID, env.TWILIO_AUTH_TOKEN);
  return twilioClient;
}

export async function sendSmsViaTwilio(
  to: string,
  body: string
): Promise<{ sid: string; status: string } | null> {
  const client = getClient();

  if (!client) {
    if (env.NODE_ENV === 'production') {
      // Never leak an OTP into production logs when the provider is missing.
      throw new Error('SMS provider is not configured');
    }
    // Message bodies may contain OTPs or private team information. Never put
    // them in logs, even in development.
    logger.info('Twilio SMS skipped (dev mode)', { to: to.slice(-4) });
    return null;
  }

  try {
    const message = await client.messages.create({
      body,
      from: env.TWILIO_PHONE_NUMBER,
      to,
    });

    logger.info('Twilio SMS sent', {
      sid: message.sid,
      to: to.slice(-4),
      status: message.status,
    });

    return { sid: message.sid, status: message.status };
  } catch (error) {
    logger.error('Twilio SMS failed', {
      to: to.slice(-4),
      error: error instanceof Error ? error.message : error,
    });
    throw error;
  }
}

export async function sendOtpViaTwilio(
  phone: string,
  code: string
): Promise<void> {
  const message = `Your FootTech verification code is: ${code}`;
  const result = await sendSmsViaTwilio(phone, message);
  if (!result) throw new Error('SMS provider is not configured');
}

export async function sendBulkSmsViaTwilio(
  recipients: Array<{ phone: string; message: string }>
): Promise<Array<{ phone: string; sid: string | null; error?: string }>> {
  const results: Array<{ phone: string; sid: string | null; error?: string }> = [];

  for (const recipient of recipients) {
    try {
      const result = await sendSmsViaTwilio(recipient.phone, recipient.message);
      results.push({ phone: recipient.phone, sid: result?.sid ?? null });
    } catch (error) {
      results.push({
        phone: recipient.phone,
        sid: null,
        error: error instanceof Error ? error.message : 'Unknown error',
      });
    }
  }

  return results;
}
