import twilio from 'twilio';
import { env } from '../../config/env.js';
import { logger } from '../logger/logger.js';

let twilioClient: twilio.Twilio | null = null;

function getClient(): twilio.Twilio | null {
  if (twilioClient) return twilioClient;

  if (!env.TWILIO_ACCOUNT_SID || !env.TWILIO_AUTH_TOKEN) {
    logger.warn('Twilio not configured — SMS will be logged only');
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
    logger.info('Twilio SMS (dev mode)', { to: to.slice(-4), body });
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
  await sendSmsViaTwilio(phone, message);
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
