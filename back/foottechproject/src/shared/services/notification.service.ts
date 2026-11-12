import { env } from '../../config/env.js';
import { logger } from '../logger/logger.js';
import { sendOtpViaTwilio } from './twilio.service.js';
import { sendPushNotification, sendBulkPushNotifications } from './firebase.service.js';
import { ServiceUnavailableError } from '../errors/AppError.js';

export async function sendOtp(
  phone: string,
  code: string,
  channel: 'SMS' | 'WHATSAPP'
): Promise<void> {
  // Local development can use a fixed, explicitly configured OTP so the
  // complete authentication flow remains testable without a paid provider.
  // env.ts rejects this setting in production and the code is never logged.
  if (env.NODE_ENV !== 'production' && env.OTP_DEV_CODE) {
    logger.info('OTP delivery bypassed in local development', {
      channel,
      phone: phone.slice(-4),
    });
    return;
  }

  const message =
    `Your Football Team Manager verification code is: ${code}`;

  try {
    if (channel === 'SMS') {
      await sendOtpViaTwilio(phone, code);
      return;
    }

    if (channel === 'WHATSAPP') {
      await sendWhatsApp(phone, message);
      return;
    }
  } catch (error) {
    if (error instanceof ServiceUnavailableError) throw error;
    throw new ServiceUnavailableError('Verification delivery is temporarily unavailable');
  }
}

/**
 * Resource creation is already committed before an invitation is delivered.
 * A provider outage must therefore not turn a successful creation into a 500
 * response (which encourages a duplicate retry). The user can request a fresh
 * OTP once delivery is available again.
 */
export async function sendOtpBestEffort(
  phone: string,
  code: string,
  channel: 'SMS' | 'WHATSAPP'
): Promise<boolean> {
  try {
    await sendOtp(phone, code, channel);
    return true;
  } catch (error) {
    logger.error('OTP delivery failed after resource creation', {
      channel,
      phone: phone.slice(-4),
      error: error instanceof Error ? error.message : 'Unknown delivery error',
    });
    return false;
  }
}

async function sendWhatsApp(
  phone: string,
  message: string
): Promise<void> {
  if (!env.TWILIO_ACCOUNT_SID) {
    if (env.NODE_ENV !== 'production') {
      logger.warn('Twilio not configured for WhatsApp', {
        phone: phone.slice(-4),
      });
    }
    throw new Error('WhatsApp provider is not configured');
  }

  // Twilio WhatsApp API uses the same messaging endpoint with whatsapp: prefix
  const { sendSmsViaTwilio } = await import('./twilio.service.js');
  const result = await sendSmsViaTwilio(`whatsapp:${phone}`, message);
  if (!result) throw new Error('WhatsApp provider is not configured');
}

export async function sendPushToUser(
  fcmToken: string,
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  await sendPushNotification(fcmToken, title, body, data);
}

export async function sendPushToMultiple(
  tokens: string[],
  title: string,
  body: string,
  data?: Record<string, string>
): Promise<void> {
  await sendBulkPushNotifications(tokens, title, body, data);
}
